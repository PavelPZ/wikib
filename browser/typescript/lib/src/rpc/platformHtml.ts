import { IStreamMessage } from "./interface"
import { IPlatform } from "./lib";

export class HtmlPlatform implements IPlatform {
    postMessage<T>(item: IStreamMessage<T>): void {
        sendMessageToFlutter?.call(undefined, item)
    }
}

export function setSendMessageToFlutter (_sendMessageToFlutter: (item: IStreamMessage<any>) => void) {
    sendMessageToFlutter = _sendMessageToFlutter;
}

let sendMessageToFlutter: (item: IStreamMessage<any>) => void

