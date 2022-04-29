export function inlineWorker() {
    // TODO(Kagami): Cache compiled module in IndexedDB? It works in FF
    // and Edge, see: https://github.com/mdn/webassembly-examples/issues/4
    // Though gzipped WASM module currently weights ~70kb so it should be
    // perfectly cached by the browser itself.
    function fetchAndInstantiate(url, imports) {
      if (!WebAssembly.instantiateStreaming) return fetchAndInstantiateFallback(url, imports);
      const req = fetch(url, {credentials: "same-origin"});
      return WebAssembly.instantiateStreaming(req, imports).catch(err => {
        // https://github.com/Kagami/vmsg/issues/11
        if (err.message && err.message.indexOf("Argument 0 must be provided and must be a Response") > 0) {
          return fetchAndInstantiateFallback(url, imports);
        } else {
          throw err;
        }
      });
    }
  
    function fetchAndInstantiateFallback(url, imports) {
      return new Promise((resolve, reject) => {
        const req = new XMLHttpRequest();
        req.open("GET", url);
        req.responseType = "arraybuffer";
        req.onload = () => {
          resolve(WebAssembly.instantiate(req.response, imports));
        };
        req.onerror = reject;
        req.send();
      });
    }
  
    // Must be in sync with emcc settings!
    const TOTAL_STACK = 5 * 1024 * 1024;
    const TOTAL_MEMORY = 16 * 1024 * 1024;
    const WASM_PAGE_SIZE = 64 * 1024;
    let memory = null;
    let dynamicTop = TOTAL_STACK;
    // TODO(Kagami): Grow memory?
    function sbrk(increment) {
      const oldDynamicTop = dynamicTop;
      dynamicTop += increment;
      return oldDynamicTop;
    }
    // TODO(Kagami): LAME calls exit(-1) on internal error. Would be nice
    // to provide custom DEBUGF/ERRORF for easier debugging. Currenty
    // those functions do nothing.
    function exit(status) {
      postMessage({type: "internal-error", data: status});
    }
  
    let FFI = null;
    let ref = null;
    let pcm_l = null;
    function vmsg_init(rate) {
      ref = FFI.vmsg_init(rate);
      if (!ref) return false;
      const pcm_l_ref = new Uint32Array(memory.buffer, ref, 1)[0];
      pcm_l = new Float32Array(memory.buffer, pcm_l_ref);
      return true;
    }
    function vmsg_encode(data) {
      pcm_l.set(data);
      return FFI.vmsg_encode(ref, data.length) >= 0;
    }
    function vmsg_flush() {
      if (FFI.vmsg_flush(ref) < 0) return null;
      const mp3_ref = new Uint32Array(memory.buffer, ref + 4, 1)[0];
      const size = new Uint32Array(memory.buffer, ref + 8, 1)[0];
      const mp3 = new Uint8Array(memory.buffer, mp3_ref, size);
      const blob = new Blob([mp3], {type: "audio/mpeg"});
      FFI.vmsg_free(ref);
      ref = null;
      pcm_l = null;
      return blob;
    }
  
    // https://github.com/brion/min-wasm-fail
    function testSafariWebAssemblyBug() {
      const bin = new Uint8Array([0,97,115,109,1,0,0,0,1,6,1,96,1,127,1,127,3,2,1,0,5,3,1,0,1,7,8,1,4,116,101,115,116,0,0,10,16,1,14,0,32,0,65,1,54,2,0,32,0,40,2,0,11]);
      const mod = new WebAssembly.Module(bin);
      const inst = new WebAssembly.Instance(mod, {});
      // test storing to and loading from a non-zero location via a parameter.
      // Safari on iOS 11.2.5 returns 0 unexpectedly at non-zero locations
      return (inst.exports.test(4) !== 0);
    }
  
    onmessage = (e) => {
      debugger;
      const msg = e.data;
      switch (msg.type) {
      case "init":
        const { wasmURL, shimURL } = msg.data;
        Promise.resolve().then(() => {
          if (self.WebAssembly && !testSafariWebAssemblyBug()) {
            delete self.WebAssembly;
          }
          if (!self.WebAssembly) {
            importScripts(shimURL);
          }
          memory = new WebAssembly.Memory({
            initial: TOTAL_MEMORY / WASM_PAGE_SIZE,
            maximum: TOTAL_MEMORY / WASM_PAGE_SIZE,
          });
          return {
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
        }).then(Runtime => {
          return fetchAndInstantiate(wasmURL, {env: Runtime})
        }).then(wasm => {
          FFI = wasm.instance.exports;
          postMessage({type: "init", data: null});
        }).catch(err => {
          postMessage({type: "init-error", data: err.toString()});
        });
        break;
      case "start":
        if (!vmsg_init(msg.data)) return postMessage({type: "error", data: "vmsg_init"});
        break;
      case "data":
        if (!vmsg_encode(msg.data)) return postMessage({type: "error", data: "vmsg_encode"});
        break;
      case "stop":
        const blob = vmsg_flush();
        if (!blob) return postMessage({type: "error", data: "vmsg_flush"});
        postMessage({type: "stop", data: blob});
        break;
      }
    };
  }
  
  