import {recordAudio} from "./src/simple_recorder.js";

export async function toggleStartStop() {
    let startStop = await recordAudio();
    if (!started) {
        started = true;
        startStop.start();
    } else {
        started = false;
        let stopInfo = await startStop.stop();
        stopInfo.play()
    }
}

let started = false;

