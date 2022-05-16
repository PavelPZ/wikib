import { rpcCallback } from "../htmlApp/rpc.js"
import { IPlatform, IOutMessage, IRpcCall, IInFncCall, rpcResult, IOutRpcResult, StreamIds } from "./interface.js"

export class HtmlPlatform implements IPlatform {
    postMessage<T>(item: IOutMessage<T>): void {
        window.htmlplatform.sendMessageToFlutter(item)
    }
}

window.htmlplatform = {
    receivedMessageFromFlutter: (rpcCall: IRpcCall) => {
        function getFunction(path: string[], idx: number, res: any): any {
            let act = path[idx]
            if (idx == 0) {
                if (act != 'window') throw `receivedMessageFromFlutter.getFunction.act!=window: ${act}`
                return getFunction(path, idx + 1, window)
            }
            if (idx >= path.length) return res
            let newRes = res[act]
            if (!newRes) throw `receivedMessageFromFlutter.getFunction.act=${act}`
            return getFunction(path, idx + 1, res[act])
        }

        try {
            let res: any[] = [];
            rpcCall.fncs.forEach((fnc: IInFncCall) => {
                let fncObj: Function = getFunction(fnc.name.split('.'), 0, null)
                res.push(fncObj.call(undefined, ...fnc.arguments))
            });
            rpcResult<any[]>(rpcCall.rpcId, res, null)
        } catch (msg) {
            rpcResult<void>(rpcCall.rpcId, null, (msg as any).toString())
        }
    },
    sendMessageToFlutter: (msg) => {
        switch (msg.streamId) {
            case StreamIds.promiseCallback:
                rpcCallback(msg)
                break
        }
    }
}