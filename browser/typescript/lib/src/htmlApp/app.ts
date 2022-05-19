import { setSendMessageToFlutter} from "../rpc/index";
import { receiveFromWebView } from "./rpc_call";

export class HTMLApp {
    static async appInit(): Promise<void> {
        await HTMLApp.callJavascript('window.wikib.setPlatform(4)');
        setSendMessageToFlutter(receiveFromWebView);
        return Promise.resolve();
    }
    static callJavascript(script: string): Promise<void> {
        eval(script);
        return Promise.resolve();
    }
}
