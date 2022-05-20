let platform;
function setPlatform(_callback) {
    platform = _callback;
}
function postRpcResultToFlutter(promiseId, result, error) {
    platform.postToFlutter({ streamId: 1 /* promiseCallback */, value: { rpcId: promiseId, result: result, error: error } });
}
function decodeErrorMsg(error) {
    if (error instanceof Error)
        return error.message;
    return String(error);
}
function receivedFromFlutter(rpcCall) {
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
        if (newRes == undefined)
            throw `receivedMessageFromFlutter.getFunction.act=${act}`;
        return getFunction(path, idx + 1, res[act]);
    }
    try {
        // console.log(`receivedMessageFromFlutter (rpcId=${rpcCall.rpcId})`)
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
                    let handlerId = parseInt(path[1]);
                    let handler = isNaN(handlerId) ? undefined : window.wikib[path[1]];
                    res.push(fncObj.call(handler, ...fnc.arguments));
                    break;
            }
        });
        postRpcResultToFlutter(rpcCall.rpcId, res, null);
    }
    catch (msg) {
        postRpcResultToFlutter(rpcCall.rpcId, null, decodeErrorMsg(msg));
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
    if (!platform)
        return;
    platform.postToFlutter({ streamId: 2 /* consoleLog */, value: message });
};
window.wikib = {
    receivedFromFlutter: receivedFromFlutter
};

class HtmlPlatform {
    postToFlutter(item) {
        sendMessageToFlutter?.call(undefined, item);
    }
}
function setSendMessageToFlutter(_sendMessageToFlutter) {
    sendMessageToFlutter = _sendMessageToFlutter;
}
let sendMessageToFlutter;

class MobilePlatform {
    constructor() {
        window.addEventListener('message', function (e) {
            receivedFromFlutter(e.data);
        });
    }
    postToFlutter(item) {
        window.flutter_inappwebview.callHandler('webMessageHandler', JSON.stringify(item));
    }
}

class WebPlatform {
    postToFlutter(item) {
        window.onStream(JSON.stringify(item));
    }
}

class WindowsPlatform {
    constructor() {
        window.chrome.webview.addEventListener('message', function (e) {
            receivedFromFlutter(e.data);
        });
    }
    postToFlutter(item) {
        window.chrome.webview.postMessage(item);
    }
}

window.wikib.setPlatform = (platformId) => {
    switch (platformId) {
        case 1 /* web */:
            setPlatform(new WebPlatform());
            break;
        case 3 /* windows */:
            setPlatform(new WindowsPlatform());
            break;
        case 4 /* html */:
            setPlatform(new HtmlPlatform());
            break;
        case 2 /* mobile */:
            setPlatform(new MobilePlatform());
            break;
    }
    console.log(`-window.media.setPlatform(${platformId})`);
};

function rpc(calls) {
    let msg = { rpcId: lastPromiseIdx++, fncs: calls };
    console.log(`flutter rpc (rpcId=${msg.rpcId})`);
    return new Promise((resolve, reject) => {
        promises[msg.rpcId.toString()] = { resolve: resolve, reject: reject };
        callJavascript(`wikib.receivedFromFlutter (${JSON.stringify(msg).replace('\\', '\\\\').replace("'", "\'")})`);
    });
}
function callJavascript(script) {
    eval(script);
    return Promise.resolve();
}
let promises = {};
let lastPromiseIdx = 1;
function receiveFromWebView(msg) {
    switch (msg.streamId) {
        case 1 /* promiseCallback */:
            rpcCallback(msg);
            break;
        case 2 /* consoleLog */:
            break;
        default:
            handlerCallback(msg);
            break;
    }
}
let handlerListenners = {};
function handlerCallback(msg) {
    if (!msg.handlerId)
        return;
    let listenner = handlerListenners[msg.handlerId];
    if (!listenner)
        return;
    listenner(msg.streamId, msg.value);
}
function rpcCallback(msg) {
    console.log(`flutter rpc Callback (rpcId=${msg.value.rpcId})`);
    let resolveReject = promises[msg.value.rpcId.toString()];
    delete promises[msg.value.rpcId.toString()];
    if (!resolveReject)
        throw 'not found';
    if (msg.value.error != null)
        resolveReject.reject(msg.value.error);
    else
        resolveReject.resolve(msg.value.result);
}

class HTMLApp {
    static async appInit() {
        await callJavascript('window.wikib.setPlatform(4)');
        setSendMessageToFlutter(receiveFromWebView);
        return Promise.resolve();
    }
}

function newHandlerName() {
    return handlerCounter++;
}
let handlerCounter = 1;
function getFncItem(handler, name, type, args) {
    let fncCall = {
        name: handler == null ? `.${name}` : `.${handler}.${name}`,
        type: type,
        arguments: args ?? [],
    };
    return fncCall;
}
function getFncCall(handler, name, args) {
    return getFncItem(handler, name, undefined, args);
}
function getGetCall(handler, name) {
    return getFncItem(handler, name, 0 /* getter */, []);
}
function getSetCall(handler, name, value) {
    return getFncItem(handler, name, 1 /* setter */, [value]);
}
async function fncCall(handler, name, args) {
    let res = await rpc([getFncCall(handler, name, args)]);
    return res[0];
}
async function getCall(handler, name) {
    let res = await rpc([getGetCall(handler, name)]);
    return res[0];
}
async function setCall(handler, name, value) {
    await rpc([getSetCall(handler, name, value)]);
}

class PlayerProxy {
    static async create(url, listen) {
        let res = new PlayerProxy();
        if (listen)
            handlerListenners[res.audioName] = listen;
        await fncCall(null, 'createPlayer', [res.playerName, res.audioName, url]);
        return res;
    }
    playerName = newHandlerName();
    audioName = newHandlerName();
    async dispose() {
        await fncCall(this.playerName, 'dispose');
        delete handlerListenners[this.audioName];
    }
    play() {
        return fncCall(this.audioName, 'play');
    }
    stop() {
        return rpc([
            getFncCall(this.audioName, 'pause'),
            getSetCall(this.audioName, 'currentTime', 0),
        ]);
    }
}

window.wikib.createPlayer = (playerName, audioName, url) => new Player(playerName, audioName, url);
class Player {
    constructor(playerName, audioName, url) {
        const audio = new Audio(url);
        const onStream = (streamId, value) => {
            platform.postToFlutter({ streamId: streamId, handlerId: audioName, value: value });
        };
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

const longUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
const shortUrl = 'https://free-loops.com/data/mp3/c8/84/81a4f6cc7340ad558c25bba4f6c3.mp3';
const playUrl = longUrl;
async function flutterRun() {
    await HTMLApp.appInit();
    let res = await rpc([
        { name: 'window.testFunctions.simple', arguments: [1, '2'] },
        { name: 'window.testFunctions.inner.run', arguments: [false] },
        { name: 'window.testFunctions.test.sum', arguments: [10, 20] },
        { name: 'window.testFunctions.test.prop', arguments: [100], type: 1 /* setter */ },
        { name: 'window.testFunctions.test.prop', arguments: [], type: 0 /* getter */ },
    ]);
    console.log(res.toString());
    let player = await PlayerProxy.create(playUrl, (id, value) => {
        switch (id) {
            case 8 /* playDurationchange */:
                document.getElementById('duration').innerHTML = value.toString();
                break;
            case 7 /* playState */:
            case 5 /* playerReadyState */:
                let div = document.getElementById('state');
                div.innerHTML = div.innerHTML + ', ' + id.toString() + '=' + value.toString();
                break;
        }
    });
    await rpc([
        getSetCall(player.audioName, 'currentTime', 360),
        getSetCall(player.audioName, 'playbackRate', 0.5)
    ]);
    // await setCall(player.audioName, 'currentTime', 10)
    // await setCall(player.audioName, 'playbackRate', 0.5)
    let posDiv = document.getElementById('pos');
    setInterval(async () => posDiv.innerHTML = await getCall(player.audioName, 'currentTime'), 100);
    await player.play();
    await new Promise(resolve => setTimeout(resolve, 100000));
    await player.stop();
    await new Promise(resolve => setTimeout(resolve, 1000));
    await player.dispose();
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
document.getElementById('playbtn')?.addEventListener('click', () => flutterRun());
