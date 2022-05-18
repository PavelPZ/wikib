import { IPlatform, IStreamMessage } from "./interface";

export class WebPlatform implements IPlatform {
    postToFlutter<T>(item: IStreamMessage<T>): void {
        window.onStream(JSON.stringify(item));
    }
}