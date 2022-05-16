export class HTMLApp {
    static async appInit(): Promise<void>  {
        await HTMLApp.callJavascript('window.media.setPlatform(4)');
        return Promise.resolve();
    }
  static callJavascript(script: string): Promise<void> {
      eval(script);
      return Promise.resolve();
  }

  static postMessage(json: TJson) {
    window.htmlplatform.receivedMessageFromFlutter(json);
  }
}