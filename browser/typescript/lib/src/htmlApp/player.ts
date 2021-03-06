import { StreamIds } from "../rpc/index";
import { handlerListenners, rpc } from "./rpc_call";
import { fncCall, getFncCall, getSetCall, newHandlerName, } from "./handlers";

export class PlayerProxy {
    static async create(url: string, listen?: (streamId: StreamIds, value: any)=>void) {
        let res = new PlayerProxy();
        if (listen) handlerListenners[res.audioName] = listen;
        await fncCall(null, 'createPlayer', [res.playerName, res.audioName, url])
        return res
    }
    playerName = newHandlerName();
    audioName = newHandlerName();
    async dispose() {
        await fncCall(this.playerName, 'dispose')
        delete handlerListenners[this.audioName]
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

