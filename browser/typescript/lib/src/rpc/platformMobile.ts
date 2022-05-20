import { IPlatform, IStreamMessage } from "./interface";
import { receivedFromFlutter } from "./lib";

export class MobilePlatform implements IPlatform {
    constructor() {
        window.addEventListener('message', function (e) {
            receivedFromFlutter(e.data)
        });
    }
    postToFlutter<T>(item: IStreamMessage<T>): void {
        window.flutter_inappwebview.callHandler('webMessageHandler', JSON.stringify(item))
    }
}