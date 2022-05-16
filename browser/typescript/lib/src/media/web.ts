import { IStreamCallback, IStreamItem } from "./interface.js";

export class WebPlatform implements IStreamCallback {
    onStream<T>(item: IStreamItem<T>): void {
        window.onStream(JSON.stringify(item));
    }
}