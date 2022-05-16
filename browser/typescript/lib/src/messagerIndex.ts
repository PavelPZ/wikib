import { callback, IOutRpcResult, Platforms, setCallback, StreamIds } from './messager/interface';
import { HtmlPlatform } from './messager/platformHtml';
import { WebPlatform } from './messager/platformWeb';
import { WindowsPlatform } from './messager/platformWindows';

export * from './messager/interface.js';

export function setPlatform(platform: Platforms) {
    switch (platform) {
        case Platforms.web:
            setCallback(new WebPlatform())
            break
        case Platforms.windows:
            setCallback(new WindowsPlatform((_) => { }))
            break
        case Platforms.html:
            setCallback(new HtmlPlatform())
            break
    }
    console.log(`-window.media.setPlatform(${platform})`);
}

export function getErrorMessage(error: unknown) {
    if (error instanceof Error) return error.message
    return String(error)
}

let _backupconsolelog = console.log;
function _divLog(message: string) {
    let consoleLog = document.getElementById("consoleLog")!;
    consoleLog.innerHTML = consoleLog.innerHTML + "<br/>" + message;
}
console.log = function (message: string) {
    _backupconsolelog(message);
    _divLog(message);
    if (!callback) return;
    callback.postMessage<string>({streamId: StreamIds.consoleLog, value: message });
}
