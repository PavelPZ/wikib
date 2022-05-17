let callback;
function setCallback(_callback) {
    callback = _callback;
}
function rpcResult(promiseId, result, error) {
    callback.postMessage({ streamId: 1 /* promiseCallback */, value: { rpcId: promiseId, result: result, error: error } });
}
function rpcCall(promiseId, action) {
    try {
        let res = action();
        rpcResult(promiseId, res, null);
    }
    catch (error) {
        rpcResult(promiseId, null, getErrorMessage(error));
    }
}
function getErrorMessage(error) {
    if (error instanceof Error)
        return error.message;
    return String(error);
}
function receivedMessageFromFlutter(rpcCall) {
    function getFunction(path, idx, res) {
        let act = path[idx];
        if (idx == 0) {
            if (act == '')
                return getFunction(path, idx + 1, window.wikib);
            else if (act != 'window')
                throw `receivedMessageFromFlutter.getFunction.act!=window: ${act}`;
            else
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
            let path = fnc.name.split('.');
            switch (fnc.type) {
                case 0 /* getter */:
                    res.push(getFunction(path, 0, null));
                    break;
                case 1 /* setter */:
                    let last = path.pop();
                    let obj = getFunction(path, 0, null);
                    obj[last] = fnc.arguments[0];
                    res.push(undefined);
                    break;
                default:
                    let fncObj = getFunction(fnc.name.split('.'), 0, null);
                    res.push(fncObj.call(undefined, ...fnc.arguments));
                    break;
            }
        });
        rpcResult(rpcCall.rpcId, res, null);
    }
    catch (msg) {
        rpcResult(rpcCall.rpcId, null, getErrorMessage(msg));
    }
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
window.wikib = {};

class HtmlPlatform {
    postMessage(item) {
        sendMessageToFlutter(item);
    }
}
function setSendMessageToFlutter(_sendMessageToFlutter) {
    sendMessageToFlutter = _sendMessageToFlutter;
}
let sendMessageToFlutter;

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

window.wikib.setPlatform = (platform) => {
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
};

function rpc(calls) {
    let msg = { rpcId: lastPromiseIdx++, fncs: calls };
    return new Promise((resolve, reject) => {
        promises[msg.rpcId] = { resolve: resolve, reject: reject };
        sendMessageToWebView(msg);
    });
}
let promises = [];
let lastPromiseIdx = 0;
let sendMessageToWebView = receivedMessageFromFlutter;
function receiveMessageFromWebView(msg) {
    switch (msg.streamId) {
        case 1 /* promiseCallback */:
            rpcCallback(msg);
            break;
    }
}
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

class HTMLApp {
    static async appInit() {
        await HTMLApp.callJavascript('window.media.setPlatform(4)');
        setSendMessageToFlutter(receiveMessageFromWebView);
        return Promise.resolve();
    }
    static callJavascript(script) {
        eval(script);
        return Promise.resolve();
    }
}

window.wikib.createPlayer = (promiseId, playerName, audioName, url) => rpcCall(promiseId, () => new Player(playerName, audioName, url));
class Player {
    constructor(playerName, audioName, url) {
        const audio = new Audio(url);
        const onStream = (streamId, value) => callback.postMessage({ streamId: streamId, name: audioName, value: value });
        let listeners = {};
        const addListenner = (type, listener) => {
            audio.addEventListener(type, listener);
            listeners[type] = listener;
            return listener;
        };
        addListenner("durationchange", () => onStream(8 /* playDurationchange */, audio.duration));
        // audio.addEventListener("progress", addListenner("progress", () => {
        //     let curr = this.audio.currentTime
        //     let last = this.lastProgress
        //     this.lastProgress = curr;
        //     if (curr > last && curr < last + this.currentPositionTimerMsec) return
        //     onStream(StreamIds.playPosition, curr)
        // }))
        addListenner("ended", () => onStream(7 /* playState */, 3 /* ended */));
        addListenner("pause", () => onStream(7 /* playState */, 2 /* pause */));
        addListenner("play", () => onStream(7 /* playState */, 1 /* play */));
        // https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
        // audio.error?.code: MEDIA_ERR_ABORTED, MEDIA_ERR_NETWORK, MEDIA_ERR_DECOD, MEDIA_ERR_SRC_NOT_SUPPORTED            
        addListenner("error", () => onStream(6 /* playerError */, audio.error?.code ?? 0));
        // https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState
        // readyState == HAVE_META_DATA
        addListenner("loadedmetadata", () => onStream(5 /* playerReadyState */, 1 /* HAVE_METADATA */));
        // readyState == HAVE_CURRENT_DATA
        addListenner("loadeddata", () => onStream(5 /* playerReadyState */, 2 /* HAVE_CURRENT_DATA */));
        // readyState == HAVE_FUTURE_DATA
        addListenner("canplay", () => onStream(5 /* playerReadyState */, 3 /* HAVE_FUTURE_DATA */));
        // readyState == HAVE_ENOUGH_DATA
        addListenner("canplaythrough", () => onStream(5 /* playerReadyState */, 4 /* HAVE_ENOUGH_DATA */));
        window.wikib[playerName.toString()] = this;
        window.wikib[audioName.toString()] = audio;
        this.dispose = () => {
            for (let key in listeners)
                audio.removeEventListener(key, listeners[key]);
            audio.pause();
            delete window.wikib[playerName.toString()];
            delete window.wikib[audioName.toString()];
        };
    }
    dispose;
}
// https://stackoverflow.com/questions/4338951/how-do-i-determine-if-mediaelement-is-playing
Object.defineProperty(HTMLMediaElement.prototype, 'playing', {
    get: function () {
        return !!(this.currentTime > 0 && !this.paused && !this.ended && this.readyState > 2);
    }
});

async function flutterRun() {
    await HTMLApp.appInit();
    let res = await rpc([
        { name: 'window.testFunctions.simple', arguments: [1, '2'] },
        { name: 'window.testFunctions.inner.run', arguments: [false] },
        { name: 'window.testFunctions.test.sum', arguments: [10, 20] },
        { name: 'window.testFunctions.test.prop', arguments: [100], type: 1 /* setter */ },
        { name: 'window.testFunctions.test.prop', arguments: [], type: 0 /* getter */ },
    ]);
    console.log(res);
}
// javascriptRun
class Test {
    sum(a, b) { return a + b; }
    set prop(v) { this.value = v; }
    get prop() { return this.value; }
    value = 0;
}
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
    },
    'test': new Test(),
};
setTimeout(flutterRun);
