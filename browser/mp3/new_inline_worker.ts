export function inlineWorker() {
    // TODO(Kagami): Cache compiled module in IndexedDB? It works in FF
    // and Edge, see: https://github.com/mdn/webassembly-examples/issues/4
    // Though gzipped WASM module currently weights ~70kb so it should be
    // perfectly cached by the browser itself.
    function fetchAndInstantiate(url: string, imports: WebAssembly.Imports) {
        const req = fetch(url, { credentials: "same-origin" });
        return WebAssembly.instantiateStreaming(req, imports);
    }

    // Must be in sync with emcc settings!
    const TOTAL_STACK = 5 * 1024 * 1024;
    const TOTAL_MEMORY = 16 * 1024 * 1024;
    const WASM_PAGE_SIZE = 64 * 1024;
    let memory: WebAssembly.Memory = new WebAssembly.Memory({
        initial: TOTAL_MEMORY / WASM_PAGE_SIZE,
        maximum: TOTAL_MEMORY / WASM_PAGE_SIZE,
    });
    let dynamicTop = TOTAL_STACK;
    // TODO(Kagami): Grow memory?
    function sbrk(increment: any) {
        const oldDynamicTop = dynamicTop; 
        dynamicTop += increment;
        return oldDynamicTop;
    }
    // TODO(Kagami): LAME calls exit(-1) on internal error. Would be nice
    // to provide custom DEBUGF/ERRORF for easier debugging. Currenty
    // those functions do nothing.
    function exit(status: any) {
        postMessage({ type: "internal-error", data: status });
    }

    let FFI: any = null;
    let ref: any = null;
    let pcm_l: Float32Array | null = null;
    function vmsg_init(rate: number /*audioCtx.sampleRate*/) {
        ref = FFI.vmsg_init(rate);
        if (!ref) return false;
        const pcm_l_ref = new Uint32Array(memory.buffer, ref, 1)[0];
        pcm_l = new Float32Array(memory.buffer, pcm_l_ref);
        return true;
    }
    function vmsg_encode(data: ArrayLike<number>) {
        pcm_l!.set(data);
        return FFI.vmsg_encode(ref, data.length) >= 0;
    }
    function vmsg_flush(): Blob | null {
        if (FFI.vmsg_flush(ref) < 0) return null;
        const mp3_ref = new Uint32Array(memory.buffer, ref + 4, 1)[0];
        const size = new Uint32Array(memory.buffer, ref + 8, 1)[0];
        const mp3 = new Uint8Array(memory.buffer, mp3_ref, size);
        const blob = new Blob([mp3], { type: "audio/mpeg" });
        FFI.vmsg_free(ref);
        ref = null;
        pcm_l = null;
        return blob;
    }

    onmessage = async (e) => {
        const msg = e.data;
        switch (msg.type) {
            case "init":
                try {
                    const { wasmURL } = msg.data;
                    let runtime: WebAssembly.ModuleImports = {
                        memory: memory,
                        pow: Math.pow,
                        exit: exit,
                        powf: Math.pow,
                        exp: Math.exp,
                        sqrtf: Math.sqrt,
                        cos: Math.cos,
                        log: Math.log,
                        sin: Math.sin,
                        sbrk: sbrk,
                    };
                    let wasm = await fetchAndInstantiate(wasmURL, { env: runtime })
                    FFI = wasm.instance.exports;
                    postMessage({ type: "init", data: null });
                } catch (err: any) {
                    postMessage({ type: "init-error", data: err.toString() });
                }
                break;
            case "start":
                if (!vmsg_init(msg.data /*audioCtx.sampleRate*/)) return postMessage({ type: "error", data: "vmsg_init" });
                break;
            case "data":
                debugger;
                if (!vmsg_encode(msg.data)) return postMessage({ type: "error", data: "vmsg_encode" });
                break;
            case "stop":
                debugger;
                const blob = vmsg_flush();
                if (!blob) return postMessage({ type: "error", data: "vmsg_flush" });
                postMessage({ type: "stop", data: blob });
                break;
        }
    };
}
