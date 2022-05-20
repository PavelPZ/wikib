import { setSendMessageToFlutter} from "../rpc/index";
import { receiveFromWebView, callJavascript } from "./rpc_call";

export class HTMLApp {
    static async appInit(): Promise<void> {
        await callJavascript('window.wikib.setPlatform(4)')
        setSendMessageToFlutter(receiveFromWebView)
        return Promise.resolve()
    }
    // static callJavascript(script: string): Promise<void> {
    //     eval(script)
    //     return Promise.resolve()
    // }
        // HTMLApp.callJavascript(`${proc} (${JSON.stringify(jsonMap).replace('\\','\\\\').replace("'", "\'")})`)
}
