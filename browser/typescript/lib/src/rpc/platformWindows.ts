import { IStreamMessage } from "./interface";
import { IPlatform } from "./lib";

export class WindowsPlatform implements IPlatform {
    constructor(onMessage: (data: TJson) => void) {
        window.chrome.webview.addEventListener('message', function (e) {
            onMessage(e.data);
        });
    }
    postMessage<T>(item: IStreamMessage<T>): void {
        window.chrome.webview.postMessage(item);
    }
}

