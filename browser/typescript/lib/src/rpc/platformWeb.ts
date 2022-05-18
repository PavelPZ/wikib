import { IStreamMessage } from "./interface";
import { IPlatform } from "./lib";

export class WebPlatform implements IPlatform {
    postMessage<T>(item: IStreamMessage<T>): void {
        window.onStream(JSON.stringify(item));
    }
}