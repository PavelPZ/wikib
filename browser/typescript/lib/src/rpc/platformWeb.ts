import { IPlatform, IStreamMessage } from "./interface";

export class WebPlatform implements IPlatform {
    postToFlutter<T>(item: IStreamMessage<T>): void {
        wikibWebPostMessage(JSON.stringify(item));
    }
}

window.setWikibWebPostMessage = _wikibWebPostMessage => {
    wikibWebPostMessage = _wikibWebPostMessage;
}

let wikibWebPostMessage: (item: string) => void