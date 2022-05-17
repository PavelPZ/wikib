import { IPlatform, IOutMessage } from "./interface";

export class WebPlatform implements IPlatform {
    postMessage<T>(item: IOutMessage<T>): void {
        window.onStream(JSON.stringify(item));
    }
}