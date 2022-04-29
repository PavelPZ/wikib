// import {inlineWorker} from "./inline_worker.js";
import { LameWasm } from "./new_lamewasm.js";

export class Recorder {
    constructor(wasmURL: string) {
        // Can't use relative URL in blob worker, see: https://stackoverflow.com/a/22582695
        this.wasmURL = new URL(wasmURL, location.toString()).href;
        Object.seal(this);
    }

    static async createRecorder(wasmURL: string): Promise<Recorder | Blob> {
        let res = new Recorder(wasmURL);
        await res.initAudio();
        return new Promise((resolve, reject) => {
            res.onResolve = () => {
                debugger;
                resolve(res); 
            }
            res.onReject = reject;
        });
    }

    initialized = false;
    wasmURL: string;
    onResolve:((value: Recorder | Blob) => void) | null = null;
    onReject:((reason: any) => void) | null = null;
    audioCtx = new window.AudioContext();
    mp3Processor: AudioWorkletNode | null = null;
    // worker: Worker | null = null;
    // workerURL: string | null = null;
    // blob: Blob | null = null;
    // blobURL: string | null = null;
    // resolve: ((msg: any) => void) | null = null;
    // reject: ((msg: any) => void) | null = null;


    close() {
        if (this.mp3Processor) this.mp3Processor.disconnect();
        // if (this.processor) this.processor.onaudioprocess = null;
        if (this.audioCtx) this.audioCtx.close();
        // if (this.worker) this.worker.terminate();
        // if (this.workerURL) URL.revokeObjectURL(this.workerURL);
        // if (this.blobURL) URL.revokeObjectURL(this.blobURL);
    }

    // Without pitch shift:
    //   [sourceNode] -> [processor] -> [audioCtx.destination]
    //                       -> [worker]
    //   sourceNode.connect(processor), processor.connect(audioCtx.destination)
    async initAudio() {
        let lame = await LameWasm.createLameWasm(new URL('vmsg.wasm', location.toString()).href,(status) => null);
        // https://developer.mozilla.org/en-US/docs/Web/API/AudioWorklet
        debugger;
        // https://stackoverflow.com/questions/68007500/how-to-migrate-to-audioworkletnode-from-scriptprocessornode
        // https://github.com/GoogleChromeLabs/web-audio-samples/blob/main/audio-worklet/basic/hello-audio-worklet/bypass-processor.js
        await this.audioCtx.audioWorklet.addModule(mp3Worklet_url);
        this.mp3Processor = new AudioWorkletNode(this.audioCtx, 'mp3-processor', {});
        this.mp3Processor.port.onmessage = (e: MessageEvent) => this.onmessage(e);
        this.mp3Processor!.port.postMessage({ type: "init", data: { "wasmURL": this.wasmURL } });
    }

    async onmessage(e: MessageEvent) {
        const msg = e.data;
        console.log("recorder msg: ", msg.type);
        switch (msg.type) {
            case "init":
                this.onResolve!(this);
                break;
            case "init-error":
            case "error":
            case "internal-error":
                this.close();
                this.onReject!(msg.type + ': ' + msg.data);
                break;
            case "stop":
                this.close();
                this.onResolve!(msg.data);
                break;
        }
    }

    async startRecording() {
        let microphone = await navigator.mediaDevices.getUserMedia({ audio: true });
        const sourceNode = this.audioCtx.createMediaStreamSource(microphone);
        sourceNode.connect(this.mp3Processor!);
        // this.mp3Processor!.connect(this.audioCtx.destination);
        // this.blob = null;
        // if (this.blobURL) URL.revokeObjectURL(this.blobURL);
        // this.blobURL = null;
        this.mp3Processor!.port.postMessage({ type: "start", data: this.audioCtx.sampleRate });
    }

    stopRecording() {
        return new Promise<Blob | Recorder>((resolve, reject) => {
            if (!this.mp3Processor) throw new Error("missing audio initialization");
            this.onResolve = resolve; this.onReject = reject;
            this.mp3Processor.port.postMessage({ type: "stop", data: null });
        });
    }
}

// let mp3Worklet_url = URL.createObjectURL(new Blob(['(', inlineWorker.toString(), ')()'], { type: 'application/javascript' }));
let mp3Worklet_url = "http://localhost:3000/dist/new_inline_worker2.js";
