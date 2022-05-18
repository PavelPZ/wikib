import { setSendMessageToFlutter, StreamIds } from "../rpc/index";
import { fncCall, getFncCall, getSetCall, listenners, newHandlerName, receiveMessageFromWebView, rpc } from "./rpc";

export class HTMLApp {
    static async appInit(): Promise<void> {
        await HTMLApp.callJavascript('window.wikib.setPlatform(4)');
        setSendMessageToFlutter(receiveMessageFromWebView);
        return Promise.resolve();
    }
    static callJavascript(script: string): Promise<void> {
        eval(script);
        return Promise.resolve();
    }
}

export class PlayerProxy {
    static async create(url: string, listen?: (streamId: StreamIds, value: any)=>void) {
        let res = new PlayerProxy();
        if (listen) listenners[res.audioName] = listen;
        await fncCall(null, 'createPlayer', [res.playerName, res.audioName, url])
        return res
    }
    playerName = newHandlerName();
    audioName = newHandlerName();
    async dispose() {
        await fncCall(this.playerName, 'dispose')
        delete listenners[this.audioName]
    }
    play() {
        return fncCall(this.audioName, 'play')
    }
    stop() {
        return rpc([
            getFncCall(this.audioName, 'pause'),
            getSetCall(this.audioName, 'currentTime', 0),
        ])
    }
}