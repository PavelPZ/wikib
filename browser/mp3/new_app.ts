import { Recorder } from "./new_recorder2.js";

export async function recordClick() { 
  if (!recorder) {
    if (audio) audio.remove();
    console.log('recordClick.createRecorder');
    let recorder = await Recorder.createRecorder("vmsg.wasm") as Recorder;
    console.log('recordClick.startRecording');
    recorder.startRecording();
  } else {
    console.log('recordClick.stopRecording');
    let blob = await recorder.stopRecording() as Blob;
    var url = URL.createObjectURL(blob);
    audio = document.createElement('audio') as HTMLAudioElement;
    audio.controls = true;
    audio.src = url;
    document.body.appendChild(audio);
    recorder = null;
  }
}

let audio: HTMLAudioElement | null;
let recorder: Recorder | null;
