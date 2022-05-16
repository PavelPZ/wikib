import { IPlatform, IOutMessage } from "./interface.js";

export class WebPlatform implements IPlatform {
    postMessage<T>(item: IOutMessage<T>): void {
        window.onStream(JSON.stringify(item));
    }
}