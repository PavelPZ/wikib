
class MP3Processor extends AudioWorkletProcessor {
    constructor() {
        super();
        this.port.onmessage = (e: MessageEvent) => MP3Processor.onMessage(this, e);
    }

    lameWasm: LameWasm | null = null;

    static onMessage(self: MP3Processor, e: MessageEvent) {
        const msg = e.data;
        console.log("worker msg: ", msg.type);
        switch (msg.type) {
            case "init":
                self.onInit(msg.data.wasmURL as string);
                break;
            case "start":
                self.onStart(msg.data /*audioCtx.sampleRate*/ as number);
                break;
            case "stop":
                self.onStop();
                break;
        }
    }

    process(inputs: Float32Array[][], outputs: Float32Array[][], parameters: Record<string, Float32Array>) {
        debugger;
        this.onData(inputs[0][0]);
        // Do nothing, producing silent output.
        return true;
    }
    async onInit(wasmURL: string) {
        try {
            this.lameWasm = await LameWasm.createLameWasm(wasmURL, (status) => this.port.postMessage({ type: "internal-error", data: status }));
            this.port.postMessage({ type: "init", data: null });
        } catch (err: any) {
            this.port.postMessage({ type: "init-error", data: err.toString() });
        }
    }

    onStart(sampleRate: number) {
        if (!this.lameWasm!.vmsg_init(sampleRate)) return postMessage({ type: "error", data: "vmsg_init" });
    }

    onData(data: ArrayLike<number>) {
        if (!!this.lameWasm!.vmsg_encode(data)) return postMessage({ type: "error", data: "vmsg_encode" });
    }

    onStop() {
        const blob = !this.lameWasm!.vmsg_flush();
        if (!blob) return postMessage({ type: "error", data: "vmsg_flush" });
        postMessage({ type: "stop", data: blob });
    }
}

registerProcessor('mp3-processor', MP3Processor);

// Must be in sync with emcc settings!
const TOTAL_STACK = 5 * 1024 * 1024;
const TOTAL_MEMORY = 16 * 1024 * 1024;
const WASM_PAGE_SIZE = 64 * 1024;

//new FFI(status => postMessage({ type: "internal-error", data: status }));
export class LameWasm {
    static async createLameWasm(url: string, exit: (status: any) => void): Promise<LameWasm> {
        console.log('LameWasm.createLamwWasm: ', url);
        let res = new LameWasm();
        let runtime: WebAssembly.ModuleImports = {
            memory: res.memory,
            pow: Math.pow,
            exit: exit,
            powf: Math.pow,
            exp: Math.exp,
            sqrtf: Math.sqrt,
            cos: Math.cos,
            log: Math.log,
            sin: Math.sin,
            sbrk: res.sbrk,
        };
        console.log('LameWasm.createLamwWasm.fetch start');
        const req = fetch(url, { credentials: "same-origin" });
        console.log('LameWasm.createLamwWasm.fetch end');
        let wasm = await WebAssembly.instantiateStreaming(req, { env: runtime });
        res.lame = wasm.instance.exports;
        console.log('LameWasm.createLamwWasm.exports: ', res.lame);
        return res;
    }

    memory: WebAssembly.Memory = new WebAssembly.Memory({
        initial: TOTAL_MEMORY / WASM_PAGE_SIZE,
        maximum: TOTAL_MEMORY / WASM_PAGE_SIZE,
    });
    dynamicTop = TOTAL_STACK;
    // TODO(Kagami): Grow memory?
    sbrk(increment: any) {
        const oldDynamicTop = this.dynamicTop;
        this.dynamicTop += increment;
        return oldDynamicTop;
    }
    // TODO(Kagami): LAME calls exit(-1) on internal error. Would be nice
    // to provide custom DEBUGF/ERRORF for easier debugging. Currenty
    // those functions do nothing.
    lame: any = null;
    ref: any = null;
    pcm_l: Float32Array | null = null;
    vmsg_init(rate: number /*audioCtx.sampleRate*/) {
        this.ref = this.lame.vmsg_init(rate);
        if (!this.ref) return false;
        const pcm_l_ref = new Uint32Array(this.memory.buffer, this.ref, 1)[0];
        this.pcm_l = new Float32Array(this.memory.buffer, pcm_l_ref);
        return true;
    }
    vmsg_encode(data: ArrayLike<number>) {
        this.pcm_l!.set(data);
        return this.lame.vmsg_encode(this.ref, data.length) >= 0;
    }
    vmsg_flush(): Blob | null {
        if (this.lame.vmsg_flush(this.ref) < 0) return null;
        const mp3_ref = new Uint32Array(this.memory.buffer, this.ref + 4, 1)[0];
        const size = new Uint32Array(this.memory.buffer, this.ref + 8, 1)[0];
        const mp3 = new Uint8Array(this.memory.buffer, mp3_ref, size);
        const blob = new Blob([mp3], { type: "audio/mpeg" });
        this.lame.vmsg_free(this.ref);
        this.ref = null;
        this.pcm_l = null;
        return blob;
    }
}

