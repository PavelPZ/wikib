import { IPlatform, IOutMessage, StreamIds } from "./interface"

export class HtmlPlatform implements IPlatform {
    postMessage<T>(item: IOutMessage<T>): void {
        sendMessageToFlutter?.call(undefined, item)
    }
}

export function setSendMessageToFlutter (_sendMessageToFlutter: (item: IOutMessage<any>) => void) {
    sendMessageToFlutter = _sendMessageToFlutter;
}

let sendMessageToFlutter: (item: IOutMessage<any>) => void

