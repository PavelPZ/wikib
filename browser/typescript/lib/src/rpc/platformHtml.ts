import { IPlatform, IStreamMessage } from "./interface"

export class HtmlPlatform implements IPlatform {
    postToFlutter<T>(item: IStreamMessage<T>): void {
        sendMessageToFlutter?.call(undefined, item)
    }
}

export function setSendMessageToFlutter (_sendMessageToFlutter: (item: IStreamMessage<any>) => void) {
    sendMessageToFlutter = _sendMessageToFlutter;
}

let sendMessageToFlutter: (item: IStreamMessage<any>) => void

