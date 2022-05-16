class HTMLApp {
    static async appInit() {
        await HTMLApp.callJavascript('window.media.setPlatform(4)');
        return Promise.resolve();
    }
    static callJavascript(script) {
        eval(script);
        return Promise.resolve();
    }
    static postMessage(json) {
        window.htmlplatform.receivedMessageFromFlutter(json);
    }
}

function rpc(calls) {
    let msg = { rpcId: lastPromiseIdx++, fncs: calls };
    return new Promise((resolve, reject) => {
        promises[msg.rpcId] = { resolve: resolve, reject: reject };
        HTMLApp.postMessage(msg);
    });
}
let promises = [];
let lastPromiseIdx = 0;
function rpcCallback(msg) {
    let resolveReject = promises[msg.value.rpcId];
    if (!resolveReject)
        throw 'not found';
    promises[msg.value.rpcId] = undefined;
    if (msg.value.error != null)
        resolveReject.reject(msg.value.error);
    else
        resolveReject.resolve(msg.value.result);
}

let callback;
function setCallback(_callback) {
    callback = _callback;
}
function rpcResult(promiseId, result, error) {
    callback.postMessage({ streamId: 1 /* promiseCallback */, value: { rpcId: promiseId, result: result, error: error } });
}

class HtmlPlatform {
    postMessage(item) {
        window.htmlplatform.sendMessageToFlutter(item);
    }
}
window.htmlplatform = {
    receivedMessageFromFlutter: (rpcCall) => {
        function getFunction(path, idx, res) {
            let act = path[idx];
            if (idx == 0) {
                if (act != 'window')
                    throw `receivedMessageFromFlutter.getFunction.act!=window: ${act}`;
                return getFunction(path, idx + 1, window);
            }
            if (idx >= path.length)
                return res;
            let newRes = res[act];
            if (!newRes)
                throw `receivedMessageFromFlutter.getFunction.act=${act}`;
            return getFunction(path, idx + 1, res[act]);
        }
        try {
            let res = [];
            rpcCall.fncs.forEach((fnc) => {
                let fncObj = getFunction(fnc.name.split('.'), 0, null);
                res.push(fncObj.call(undefined, ...fnc.arguments));
            });
            rpcResult(rpcCall.rpcId, res, null);
        }
        catch (msg) {
            rpcResult(rpcCall.rpcId, null, msg.toString());
        }
    },
    sendMessageToFlutter: (msg) => {
        switch (msg.streamId) {
            case 1 /* promiseCallback */:
                rpcCallback(msg);
                break;
        }
    }
};

class WebPlatform {
    postMessage(item) {
        window.onStream(JSON.stringify(item));
    }
}

class WindowsPlatform {
    constructor(onMessage) {
        window.chrome.webview.addEventListener('message', function (e) {
            onMessage(e.data);
        });
    }
    postMessage(item) {
        window.chrome.webview.postMessage(item);
    }
}

function setPlatform(platform) {
    switch (platform) {
        case 1 /* web */:
            setCallback(new WebPlatform());
            break;
        case 3 /* windows */:
            setCallback(new WindowsPlatform((_) => { }));
            break;
        case 4 /* html */:
            setCallback(new HtmlPlatform());
            break;
    }
    console.log(`-window.media.setPlatform(${platform})`);
}
function getErrorMessage(error) {
    if (error instanceof Error)
        return error.message;
    return String(error);
}
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

let players = {};
class Player {
    constructor(pars) {
        this.id = playerCount++;
        players[`player_${this.id}`] = this;
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
            delete players[`player_${this.id}`];
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
            rpcResult(promiseId, this.id, null);
        }
        catch (error) {
            rpcResult(promiseId, this.id, getErrorMessage(error));
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

const media = {
    setPlatform: setPlatform,
    createPlayer: function createPlayer(pars) {
        try {
            let player = new Player(pars);
            rpcResult(pars.promiseId, player.id, null);
        }
        catch (error) {
            rpcResult(pars.promiseId, null, getErrorMessage(error));
        }
    },
    players: players,
};
window['media'] = media;

async function flutterRun() {
    await HTMLApp.appInit();
    let res = await rpc([
        { name: 'window.testFunctions.simple', arguments: [1, '2'] },
        { name: 'window.testFunctions.inner.run', arguments: [false] },
    ]);
    debugger;
    console.log(res);
}
// javascriptRun
window['testFunctions'] = {
    'simple': (p1, p2) => {
        console.log(`window.testFunctions.simple(${p1}, ${p2})`);
        return 'res1';
    },
    'inner': {
        'run': (p1) => {
            console.log(`window.testFunctions.inner.run(${p1})`);
            return 12.6;
        }
    }
};
setTimeout(() => {
    debugger;
    flutterRun();
});
