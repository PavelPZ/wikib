import { IPlatform, IOutMessage } from "./interface.js";

export class WindowsPlatform implements IPlatform {
    constructor(onMessage: (data: TJson) => void) {
        window.chrome.webview.addEventListener('message', function (e) {
            onMessage(e.data);
        });
    }
    postMessage<T>(item: IOutMessage<T>): void {
        window.chrome.webview.postMessage(item);
    }
}

