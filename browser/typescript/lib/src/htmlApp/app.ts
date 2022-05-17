import { setSendMessageToFlutter } from "../messager/index";
import { receiveMessageFromWebView } from "./rpc";

export class HTMLApp {
    static async appInit(): Promise<void>  {
        await HTMLApp.callJavascript('window.media.setPlatform(4)');
        setSendMessageToFlutter(receiveMessageFromWebView);
        return Promise.resolve();
    }
  static callJavascript(script: string): Promise<void> {
      eval(script);
      return Promise.resolve();
  }

}