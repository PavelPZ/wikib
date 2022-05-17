// import {inlineWorker} from "./inline_worker";
import { inlineWorker } from "./new_inline_worker";

export class Recorder {
    constructor(opts: {
        [wasmURL: string]: string;
    }, onStop: Function | null = null) {
        // Can't use relative URL in blob worker, see:
        // https://stackoverflow.com/a/22582695
        this.wasmURL = new URL(opts.wasmURL, location.toString()).href;
        this.onStop = onStop;
        Object.seal(this);
    }

    wasmURL: string;
    onStop: Function | null = null;
    audioCtx = new window.AudioContext();
    processor: AudioWorkletNode | null = null;
    worker: Worker | null = null;
    workerURL: string | null = null;
    blob: Blob | null = null;
    blobURL: string | null = null;
    resolve: ((msg: any) => void) | null = null;
    reject: ((msg: any) => void) | null = null;


    close() {
        if (this.processor) this.processor.disconnect();
        // if (this.processor) this.processor.onaudioprocess = null;
        if (this.audioCtx) this.audioCtx.close();
        if (this.worker) this.worker.terminate();
        if (this.workerURL) URL.revokeObjectURL(this.workerURL);
        if (this.blobURL) URL.revokeObjectURL(this.blobURL);
    }

    // Without pitch shift:
    //   [sourceNode] -> [processor] -> [audioCtx.destination]
    //                       -> [worker]
    //   sourceNode.connect(processor), processor.connect(audioCtx.destination)
    async initAudio() {
        let microphone = await navigator.mediaDevices.getUserMedia({ audio: true });
        const sourceNode = this.audioCtx.createMediaStreamSource(microphone);
        // https://developer.mozilla.org/en-US/docs/Web/API/AudioWorklet
        // https://stackoverflow.com/questions/68007500/how-to-migrate-to-audioworkletnode-from-scriptprocessornode
        // https://github.com/GoogleChromeLabs/web-audio-samples/blob/main/audio-worklet/basic/hello-audio-worklet/bypass-processor.js
        await this.audioCtx.audioWorklet.addModule(url_worklet);
        this.processor = new AudioWorkletNode(this.audioCtx, 'worklet-processor', {});
        sourceNode.connect(this.processor);
        // this.processor.connect(this.audioCtx.destination);
    }

    initWorker() {
        if (!this.audioCtx) throw new Error("missing audio initialization");
        // https://stackoverflow.com/a/19201292
        let source = inlineWorker.toString();
        const blob = new Blob(
            ["(", source, ")()"],
            { type: "application/javascript" });
        this.workerURL = URL.createObjectURL(blob);
        this.worker = new Worker(this.workerURL);
        this.worker.postMessage({ type: "init", data: { "wasmURL": this.wasmURL } });
        return new Promise<void>((resolve, reject) => {
            this.worker!.onmessage = (e) => {
                const msg = e.data;
                switch (msg.type) {
                    case "init":
                        resolve();
                        break;
                    case "init-error":
                        reject(new Error(msg.data));
                        break;
                    // TODO(Kagami): Error handling.
                    case "error":
                    case "internal-error":
                        console.error("Worker error:", msg.data);
                        if (this.reject) this.reject(msg.data);
                        break;
                    case "stop":
                        this.blob = msg.data;
                        this.blobURL = URL.createObjectURL(msg.data);
                        if (this.onStop) this.onStop();
                        if (this.resolve) this.resolve(this.blob);
                        break;
                }
            }
        });
    }

    startRecording() {
        if (!this.audioCtx) throw new Error("missing audio initialization");
        if (!this.worker) throw new Error("missing worker initialization");
        this.blob = null;
        if (this.blobURL) URL.revokeObjectURL(this.blobURL);
        this.blobURL = null;
        this.worker.postMessage({ type: "start", data: this.audioCtx.sampleRate });
        // this.encNode.onaudioprocess = (e) => {
        //     const samples = e.inputBuffer.getChannelData(0);
        //     this.worker.postMessage({ type: "data", data: samples });
        // };
        this.processor!.connect(this.audioCtx.destination);
    }

    stopRecording() {
        const resultP = new Promise((resolve, reject) => {
            if (this.processor) {
                this.processor.disconnect();
                // this.encNode.onaudioprocess = null;
            }

            this.resolve = resolve;
            this.reject = reject;
        });

        if (this.worker) {
            this.worker.postMessage({ type: "stop", data: null });
        } else {
            return Promise.resolve(this.blob);
        }

        return resultP;
    }
}

let url_worklet = URL.createObjectURL(new Blob(['(', function () {

    class WorkletProcessor extends AudioWorkletProcessor {
      constructor() { super(); }
      process(inputs: Float32Array[][], outputs: Float32Array[][], parameters: Record<string, Float32Array>) {
  
        const input = inputs[0];
        const output = outputs[0];
  
        for (let channel = 0; channel < output.length; ++channel) {
          output[channel].set(input[channel]);
        }
    
        return true;
      }
    }
    registerProcessor('worklet-processor', WorkletProcessor);
  
  }.toString(), ')()'], { type: 'application/javascript' }));
  