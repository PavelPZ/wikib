const mediaJs = '''
function setCallback(_callback) {
    callback = _callback;
}
let callback;
function promiseCallback(promiseId, result, error) {
    callback.postMessage({ streamId: 1 /* promiseCallback */, value: { promiseId: promiseId, result: result, error: error } });
}
function getErrorMessage(error) {
    if (error instanceof Error)
        return error.message;
    return String(error);
}
// let backupconsolelog = console.log;
// console.log = function (message: string) {
//     backupconsolelog(message);
//     if (!callback) return;
//     callback.onStream<string>({streamId: StreamIds.consoleLog, value: message });
// }

let players = {};
class Player {
    constructor(pars) {
        this.id = playerCount++;
        players[`player_\${this.id}`] = this;
        const { url } = pars;
        this.currentPositionTimerMsec = pars.currentPositionTimerMsec ?? 300;
        this.url = url;
        const audio = this.audio = new Audio(url);
        const onStream = (streamId, value) => callback.postMessage({ streamId: streamId, value: { playerId: this.id, value: value } });
        const addListenner = (type, listener) => { this.listeners[type] = listener; return listener; };
        audio.addEventListener("durationchange", addListenner("durationchange", () => onStream(9 /* playDurationchange */, audio.duration)));
        audio.addEventListener("progress", addListenner("progress", () => {
            let curr = this.audio.currentTime;
            let last = this.lastProgress;
            this.lastProgress = curr;
            if (curr > last && curr < last + this.currentPositionTimerMsec)
                return;
            onStream(8 /* playPosition */, curr);
        }));
        audio.addEventListener("ended", addListenner("ended", () => onStream(7 /* playState */, 3 /* ended */)));
        audio.addEventListener("pause", addListenner("pause", () => onStream(7 /* playState */, 2 /* pause */)));
        audio.addEventListener("play", addListenner("play", () => onStream(7 /* playState */, 1 /* play */)));
        // https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
        // audio.error?.code: MEDIA_ERR_ABORTED, MEDIA_ERR_NETWORK, MEDIA_ERR_DECOD, MEDIA_ERR_SRC_NOT_SUPPORTED            
        audio.addEventListener("error", addListenner("error", () => onStream(6 /* playerError */, audio.error?.code ?? 0)));
        // https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState
        // readyState == HAVE_META_DATA
        audio.addEventListener("loadedmetadata", addListenner("loadedmetadata", () => onStream(5 /* playerReadyState */, 1 /* HAVE_METADATA */)));
        // readyState == HAVE_CURRENT_DATA
        audio.addEventListener("loadeddata", addListenner("loadeddata", () => onStream(5 /* playerReadyState */, 2 /* HAVE_CURRENT_DATA */)));
        // readyState == HAVE_FUTURE_DATA
        audio.addEventListener("canplay", addListenner("canplay", () => onStream(5 /* playerReadyState */, 3 /* HAVE_FUTURE_DATA */)));
        // readyState == HAVE_ENOUGH_DATA
        audio.addEventListener("canplaythrough", addListenner("canplaythrough", () => onStream(5 /* playerReadyState */, 4 /* HAVE_ENOUGH_DATA */)));
    }
    id;
    url;
    audio;
    currentPositionTimerMsec;
    listeners = {};
    lastProgress = 0;
    dispose(promiseId) {
        this._safeCall(promiseId, () => {
            for (let key in this.listeners)
                this.audio.removeEventListener(key, this.listeners[key]);
            this.audio.pause();
            delete players[`player_\${this.id}`];
        });
    }
    play(promiseId) {
        this._safeCall(promiseId, () => {
            this.audio.pause();
            this.audio.currentTime = 0;
            this.audio.play();
        });
    }
    stop(promiseId) {
        this._safeCall(promiseId, () => {
            this.audio.pause();
            this.audio.currentTime = 0;
        });
    }
    _safeCall(promiseId, action) {
        try {
            action();
            promiseCallback(promiseId, this.id, null);
        }
        catch (error) {
            promiseCallback(promiseId, this.id, getErrorMessage(error));
        }
    }
}
let playerCount = 0;
// https://stackoverflow.com/questions/4338951/how-do-i-determine-if-mediaelement-is-playing
Object.defineProperty(HTMLMediaElement.prototype, 'playing', {
    get: function () {
        return !!(this.currentTime > 0 && !this.paused && !this.ended && this.readyState > 2);
    }
});

class WebPlatform {
    postMessage(item) {
        window.onStream(JSON.stringify(item));
    }
}

class WindowsPlatform {
    postMessage(item) {
        window.chrome.webview.postMessage(item);
    }
}
window.chrome.webview.addEventListener('message', function (e) {
    console.log(e.data.msg);
});

const media = {
    setPlatform: function setPlatform(platform) {
        switch (platform) {
            case 1 /* web */:
                setCallback(new WebPlatform());
                break;
            case 3 /* windows */:
                setCallback(new WindowsPlatform());
                break;
        }
        console.log("-window.media.setPlatform(\${platform})");
    },
    createPlayer: function createPlayer(pars) {
        try {
            let player = new Player(pars);
            promiseCallback(pars.promiseId, player.id, null);
        }
        catch (error) {
            promiseCallback(pars.promiseId, null, getErrorMessage(error));
        }
    },
    players: players,
};
window['media'] = media;

let _backupconsolelog = console.log;
function _divLog(message) {
    let consoleLog = document.getElementById("consoleLog");
    consoleLog.innerHTML = consoleLog.innerHTML + "<br/>" + message;
}
console.log = function (message) {
    _backupconsolelog(message);
    _divLog(message);
    if (!callback)
        return;
    callback.postMessage({ streamId: 2 /* consoleLog */, value: message });
};
''';
