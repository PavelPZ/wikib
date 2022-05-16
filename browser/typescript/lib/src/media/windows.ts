import { IStreamCallback, IStreamItem } from "./interface.js";

export class WindowsPlatform implements IStreamCallback {
    onStream<T>(item: IStreamItem<T>): void {
        window.chrome.webview.postMessage(JSON.stringify(item));
    }
}