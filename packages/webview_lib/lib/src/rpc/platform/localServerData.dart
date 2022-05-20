const _html = '''
<!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>index_messages</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

<body id="body"
    style="margin: 0px; width: 1000px; height:1000px; background-color:red; overflow: hidden; cursor: pointer;">
    <div style="float: left;width:400px" id="consoleLog"></div> 
    <script>
{####}
    </script>
</body>
</html>''';
const _js = '''
let platform;
function setPlatform(_platform) {
    platform = _platform;
}
function postRpcResultToFlutter(promiseId, result, error) {
    // console.log('postRpcResultToFlutter'); console.log(platform);
    if (!platform)
        throw '!platform';
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
                throw `receivedMessageFromFlutter.getFunction.act!=window: \${act}`;
            else
                return getFunction(path, idx + 1, window);
        }
        if (idx >= path.length)
            return res;
        let newRes = res[act];
        if (newRes == undefined)
            throw `receivedMessageFromFlutter.getFunction.act=\${act}`;
        return getFunction(path, idx + 1, res[act]);
    }
    try {
        // console.log(`receivedMessageFromFlutter (rpcId=\${rpcCall.rpcId})`)
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
        console.log('receivedFromFlutter ERROR:' + msg.toString());
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
        if (sendMessageToFlutter == null)
            return;
        sendMessageToFlutter(item);
    }
}
function setSendMessageToFlutter(_sendMessageToFlutter) {
    sendMessageToFlutter = _sendMessageToFlutter;
}
let sendMessageToFlutter;

let isFlutterInAppWebViewReady = false;
window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
    isFlutterInAppWebViewReady = true;
});
class MobilePlatform {
    // constructor() {
    //     window.addEventListener('message', function (e) {
    //         receivedFromFlutter(e.data)
    //     });
    // }
    postToFlutter(item) {
        if (!isFlutterInAppWebViewReady)
            return;
        // window.flutter_inappwebview.callHandler('webMessageHandler', JSON.stringify(item))
        window.flutter_inappwebview.callHandler('webMessageHandler', item);
    }
}

class WebPlatform {
    postToFlutter(item) {
        window.onStream(JSON.stringify(item));
    }
}

class WindowsPlatform {
    constructor() {
    //     window.chrome.webview.addEventListener('message', function (e) {
    //         receivedFromFlutter(e.data)
    //     });
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
    console.log(`-window.media.setPlatform(\${platformId})`);
};

window.wikib.createPlayer = (playerName, audioName, url) => new Player(playerName, audioName, url);
class Player {
    constructor(playerName, audioName, url) {
        const audio = new Audio(url);
        const onStream = (streamId, value) => {
            console.log('postRpcResultToFlutter'); console.log(platform);
        if (!platform)
                throw '!platform';
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
''';

String debugHTML() => _html.replaceFirst('{####}', _js);
