import { IPlatform, IStreamMessage } from "./interface";
import { receivedFromFlutter } from "./lib";

export class WindowsPlatform implements IPlatform {
    // constructor() {
    //     window.chrome.webview.addEventListener('message', function (e) {
    //         receivedFromFlutter(e.data)
    //     });
    // }
    postToFlutter<T>(item: IStreamMessage<T>): void {
        window.chrome.webview.postMessage(item)
    }
}

