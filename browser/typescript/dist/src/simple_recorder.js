"use strict";
async function init() {
    const getRecordOrPlay = (callback) => {
        return new Promise(async (resolve) => {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            let mediaRecorder = null;
            let audio = null;
            const recordOrPlay = () => new Promise(resolve => {
                let audioChunks = [];
                if (mediaRecorder == null) { //recording
                    if (audio != null) {
                        audio.pause();
                        audio = null;
                    }
                    mediaRecorder = new MediaRecorder(stream);
                    mediaRecorder.addEventListener("dataavailable", event => audioChunks.push(event.data));
                    mediaRecorder.addEventListener("stop", () => {
                        mediaRecorder = null;
                        const audioBlob = new Blob(audioChunks, { type: "audio/mpeg" });
                        const audioUrl = URL.createObjectURL(audioBlob);
                        audio = new Audio(audioUrl);
                        audio.addEventListener("ended", () => {
                            callback(0);
                        });
                        callback(2);
                        audio.play();
                    });
                    mediaRecorder.start();
                    callback(1);
                }
                else {
                    mediaRecorder.stop();
                }
            });
            resolve(recordOrPlay);
        });
    };
    let button = document.querySelector('#recordButton');
    let setButton = (text, disabled) => { button.innerHTML = text; button.disabled = disabled; };
    let recordOrPlay = await getRecordOrPlay(status => {
        switch (status) {
            case 0: return setButton('Record', false);
            case 1:
                return setButton('Stop', false);
                button.innerHTML = 'Stop';
                button.disabled = false;
            case 2: return setButton('... playing ...', true);
        }
    });
    button.addEventListener('click', recordOrPlay);
}
init();
