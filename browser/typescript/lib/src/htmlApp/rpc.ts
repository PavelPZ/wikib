import { IInFncCall, IOutMessage, IOutRpcResult, IRpcCall, receivedMessageFromFlutter, StreamIds } from "../messager/index";

export function rpc<T>(calls: IInFncCall[]):Promise<T>  {
    let msg: IRpcCall = { rpcId:lastPromiseIdx++, fncs: calls};
    return new Promise<T>((resolve, reject) => {
        promises[msg.rpcId] = {resolve: resolve, reject:reject};
        sendMessageToWebView(msg);
    });
}

let promises: (IResolveReject | undefined)[] = [];
let lastPromiseIdx = 0;
let sendMessageToWebView = receivedMessageFromFlutter;

export function receiveMessageFromWebView(msg: IOutMessage<any>) {
    switch (msg.streamId) {
        case StreamIds.promiseCallback:
            rpcCallback(msg)
            break
    }

}

function rpcCallback(msg: IOutMessage<IOutRpcResult<any>>) {
    let resolveReject = promises[msg.value.rpcId]
    if (!resolveReject) throw 'not found'
    promises[msg.value.rpcId] = undefined
    if (msg.value.error!=null) resolveReject.reject(msg.value.error);
    else resolveReject.resolve(msg.value.result);
}

interface IResolveReject {
    resolve: (res:any) => void
    reject: (error?:any) => void
}

