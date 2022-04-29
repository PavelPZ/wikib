// import {inlineWorker} from "./inline_worker.js";
import {inlineWorker} from "./new_inline_worker.js";
import {Jungle} from "./jungle.js";

export class Recorder {
    constructor(opts = {}, onStop) {
      // Can't use relative URL in blob worker, see:
      // https://stackoverflow.com/a/22582695
      this.wasmURL = new URL(opts.wasmURL || "/static/js/vmsg.wasm", location).href;
      this.shimURL = new URL(opts.shimURL || "/static/js/wasm-polyfill.js", location).href;
      this.onStop = onStop;
      this.pitch = opts.pitch || 0;
      this.audioCtx = null;
      this.gainNode = null;
      this.pitchFX = null;
      this.encNode = null;
      this.worker = null;
      this.workerURL = null;
      this.blob = null;
      this.blobURL = null;
      this.resolve = null;
      this.reject = null;
      Object.seal(this);
    }
  
    close() {
      if (this.encNode) this.encNode.disconnect();
      if (this.encNode) this.encNode.onaudioprocess = null;
      if (this.audioCtx) this.audioCtx.close();
      if (this.worker) this.worker.terminate();
      if (this.workerURL) URL.revokeObjectURL(this.workerURL);
      if (this.blobURL) URL.revokeObjectURL(this.blobURL);
    }
  
    // Without pitch shift:
    //   [sourceNode] -> [gainNode] -> [encNode] -> [audioCtx.destination]
    //                                     -> [worker]
    //   sourceNode.connect(gainNode), gainNode.connect(encNode), encNode.connect(audioCtx.destination)
    // 
    // With pitch shift:
    //   [sourceNode] -> [gainNode] -> [pitchFX] -> [encNode] -> [audioCtx.destination]
    //                                                  |
    //                                                  -> [worker]
    initAudio() {
      const getUserMedia = navigator.mediaDevices && navigator.mediaDevices.getUserMedia
        ? function(constraints) {
            return navigator.mediaDevices.getUserMedia(constraints);
          }
        : function(constraints) {
            const oldGetUserMedia = navigator.webkitGetUserMedia || navigator.mozGetUserMedia;
            if (!oldGetUserMedia) {
              return Promise.reject(new Error("getUserMedia is not implemented in this browser"));
            }
            return new Promise(function(resolve, reject) {
              oldGetUserMedia.call(navigator, constraints, resolve, reject);
            });
          };
  
      return getUserMedia({audio: true}).then(stream => {
        const audioCtx = this.audioCtx = new (window.AudioContext
          || window.webkitAudioContext)();
  
        const sourceNode = audioCtx.createMediaStreamSource(stream);
        const gainNode = this.gainNode = (audioCtx.createGain
          || audioCtx.createGainNode).call(audioCtx);
        gainNode.gain.value = 1;
        sourceNode.connect(gainNode);
  
        const pitchFX = this.pitchFX = new Jungle(audioCtx);
        pitchFX.setPitchOffset(this.pitch);
  
        const encNode = this.encNode = (audioCtx.createScriptProcessor
          || audioCtx.createJavaScriptNode).call(audioCtx, 0, 1, 1);
        pitchFX.output.connect(encNode);
  
        gainNode.connect(this.pitch === 0 ? encNode : pitchFX.input);
      });
    }
  
    initWorker() {
      if (!this.audioCtx) throw new Error("missing audio initialization");
      // https://stackoverflow.com/a/19201292
      let source = inlineWorker.toString();
      const blob = new Blob(
        ["(", source, ")()"],
        {type: "application/javascript"});
      const workerURL = this.workerURL = URL.createObjectURL(blob);
      const worker = this.worker = new Worker(workerURL);
      const { wasmURL, shimURL } = this;
      worker.postMessage({type: "init", data: {wasmURL, shimURL}});
      return new Promise((resolve, reject) => {
        worker.onmessage = (e) => {
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
      this.worker.postMessage({type: "start", data: this.audioCtx.sampleRate});
      this.encNode.onaudioprocess = (e) => {
        const samples = e.inputBuffer.getChannelData(0);
        this.worker.postMessage({type: "data", data: samples});
      };
      this.encNode.connect(this.audioCtx.destination);
    }
  
    stopRecording() {
      const resultP = new Promise((resolve, reject) => {
        if (this.encNode) {
          this.encNode.disconnect();
          this.encNode.onaudioprocess = null;
        }
  
        this.resolve = resolve;
        this.reject = reject;
      });
  
      if (this.worker) {
        this.worker.postMessage({type: "stop", data: null});
      } else {
        return Promise.resolve(this.blob);
      }
  
      return resultP;
    }
  }
  