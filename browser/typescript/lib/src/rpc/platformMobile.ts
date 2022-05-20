import { IPlatform, IStreamMessage } from "./interface";

let isFlutterInAppWebViewReady = false;
window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
    isFlutterInAppWebViewReady = true;
});

export class MobilePlatform implements IPlatform {
    // constructor() {
    //     window.addEventListener('message', function (e) {
    //         receivedFromFlutter(e.data)
    //     });
    // }
    postToFlutter<T>(item: IStreamMessage<T>): void {
        if (!isFlutterInAppWebViewReady) return;
        // window.flutter_inappwebview.callHandler('webMessageHandler', JSON.stringify(item))
        window.flutter_inappwebview.callHandler('webMessageHandler', item)
    }
}

