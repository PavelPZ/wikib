// import {Recorder} from "./recorder.js";
import {Recorder} from "./new_recorder.js";

function pad2(n) {
  n |= 0;
  return n < 10 ? `0${n}` : `${Math.min(n, 99)}`;
}


export class Form {
  constructor(opts = {}, resolve, reject) {
    this.recorder = new Recorder(opts, this.onStop.bind(this));
    this.resolve = resolve;
    this.reject = reject;
    this.backdrop = null;
    this.popup = null;
    this.recordBtn = null;
    this.stopBtn = null;
    this.timer = null;
    this.audio = null;
    this.saveBtn = null;
    this.tid = 0;
    this.start = 0;
    Object.seal(this);

    this.recorder.initAudio()
      .then(() => this.drawInit())
      .then(() => this.recorder.initWorker())
      .then(() => this.drawAll())
      .catch((err) => this.drawError(err));
  }

  drawInit() {
    if (this.backdrop) return;
    const backdrop = this.backdrop = document.createElement("div");
    backdrop.className = "vmsg-backdrop";
    backdrop.addEventListener("click", () => this.close(null));

    const popup = this.popup = document.createElement("div");
    popup.className = "vmsg-popup";
    popup.addEventListener("click", (e) => e.stopPropagation());

    const progress = document.createElement("div");
    progress.className = "vmsg-progress";
    for (let i = 0; i < 3; i++) {
      const progressDot = document.createElement("div");
      progressDot.className = "vmsg-progress-dot";
      progress.appendChild(progressDot);
    }
    popup.appendChild(progress);

    backdrop.appendChild(popup);
    document.body.appendChild(backdrop);
  }

  drawTime(msecs) {
    const secs = Math.round(msecs / 1000);
    this.timer.textContent = pad2(secs / 60) + ":" + pad2(secs % 60);
  }

  drawAll() {
    this.drawInit();
    this.clearAll();

    const recordRow = document.createElement("div");
    recordRow.className = "vmsg-record-row";
    this.popup.appendChild(recordRow);

    const recordBtn = this.recordBtn = document.createElement("button");
    recordBtn.className = "vmsg-button vmsg-record-button";
    recordBtn.textContent = "●";
    recordBtn.addEventListener("click", () => this.startRecording());
    recordRow.appendChild(recordBtn);

    const stopBtn = this.stopBtn = document.createElement("button");
    stopBtn.className = "vmsg-button vmsg-stop-button";
    stopBtn.style.display = "none";
    stopBtn.textContent = "■";
    stopBtn.addEventListener("click", () => this.stopRecording());
    recordRow.appendChild(stopBtn);

    const audio = this.audio = new Audio();
    audio.autoplay = true;

    const timer = this.timer = document.createElement("span");
    timer.className = "vmsg-timer";
    timer.addEventListener("click", () => {
      if (audio.paused) {
        if (this.recorder.blobURL) {
          audio.src = this.recorder.blobURL;
        }
      } else {
        audio.pause();
      }
    });
    this.drawTime(0);
    recordRow.appendChild(timer);

    const saveBtn = this.saveBtn = document.createElement("button");
    saveBtn.className = "vmsg-button vmsg-save-button";
    saveBtn.textContent = "✓";
    saveBtn.disabled = true;
    saveBtn.addEventListener("click", () => this.close(this.recorder.blob));
    recordRow.appendChild(saveBtn);

    const gainWrapper = document.createElement("div");
    gainWrapper.className = "vmsg-slider-wrapper vmsg-gain-slider-wrapper";
    const gainSlider = document.createElement("input");
    gainSlider.className = "vmsg-slider vmsg-gain-slider";
    gainSlider.setAttribute("type", "range");
    gainSlider.min = 0;
    gainSlider.max = 2;
    gainSlider.step = 0.2;
    gainSlider.value = 1;
    gainSlider.onchange = () => {
      const gain = +gainSlider.value;
      this.recorder.gainNode.gain.value = gain;
    };
    gainWrapper.appendChild(gainSlider);
    this.popup.appendChild(gainWrapper);

    const pitchWrapper = document.createElement("div");
    pitchWrapper.className = "vmsg-slider-wrapper vmsg-pitch-slider-wrapper";
    const pitchSlider = document.createElement("input");
    pitchSlider.className = "vmsg-slider vmsg-pitch-slider";
    pitchSlider.setAttribute("type", "range");
    pitchSlider.min = -1;
    pitchSlider.max = 1;
    pitchSlider.step = 0.2;
    pitchSlider.value = this.recorder.pitch;
    pitchSlider.onchange = () => {
      const pitch = +pitchSlider.value;
      this.recorder.pitchFX.setPitchOffset(pitch);
      this.recorder.gainNode.disconnect();
      this.recorder.gainNode.connect(
        pitch === 0 ? this.recorder.encNode : this.recorder.pitchFX.input
      );
    };
    pitchWrapper.appendChild(pitchSlider);
    this.popup.appendChild(pitchWrapper);
  }

  drawError(err) {
    console.error(err);
    this.drawInit();
    this.clearAll();
    const error = document.createElement("div");
    error.className = "vmsg-error";
    error.textContent = err.toString();
    this.popup.appendChild(error);
  }

  clearAll() {
    if (!this.popup) return;
    this.popup.innerHTML = "";
  }

  close(blob) {
    if (this.audio) this.audio.pause();
    if (this.tid) clearTimeout(this.tid);
    this.recorder.close();
    this.backdrop.remove();
    if (blob) {
      this.resolve(blob);
    } else {
      this.reject(new Error("No record made"));
    }
  }

  onStop() {
    this.recordBtn.style.display = "";
    this.stopBtn.style.display = "none";
    this.stopBtn.disabled = false;
    this.saveBtn.disabled = false;
  }

  startRecording() {
    this.audio.pause();
    this.start = Date.now();
    this.updateTime();
    this.recordBtn.style.display = "none";
    this.stopBtn.style.display = "";
    this.saveBtn.disabled = true;
    this.recorder.startRecording();
  }

  stopRecording() {
    clearTimeout(this.tid);
    this.tid = 0;
    this.stopBtn.disabled = true;
    this.recorder.stopRecording();
  }

  updateTime() {
    // NOTE(Kagami): We can do this in `onaudioprocess` but that would
    // run too often and create unnecessary DOM updates.
    this.drawTime(Date.now() - this.start);
    this.tid = setTimeout(() => this.updateTime(), 300);
  }
}

let shown = false;

/**
 * Record a new voice message.
 *
 * @param {Object=} opts - Options
 * @param {string=} opts.wasmURL - URL of the module
 *                                 ("/static/js/vmsg.wasm" by default)
 * @param {string=} opts.shimURL - URL of the WebAssembly polyfill
 *                                 ("/static/js/wasm-polyfill.js" by default)
 * @param {number=} opts.pitch - Initial pitch shift ([-1, 1], 0 by default)
 * @return {Promise.<Blob>} A promise that contains recorded blob when fulfilled.
 */
export function record(opts) {
  return new Promise((resolve, reject) => {
    if (shown) throw new Error("Record form is already opened");
    shown = true;
    new Form(opts, resolve, reject);
  // Use `.finally` once it's available in Safari and Edge.
  }).then(result => {
    shown = false;
    return result;
  }, err => {
    shown = false;
    throw err;
  });
}

/**
 * All available public items.
 */
export default { Recorder, Form, record };
