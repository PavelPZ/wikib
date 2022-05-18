import { IRpcFnc, IStreamMessage, IRpcResult, IRpc, receivedFromFlutter, StreamIds } from "../rpc/index";

export function rpc(calls: IRpcFnc[]): Promise<any[]> {
    let msg: IRpc = { rpcId: lastPromiseIdx++, fncs: calls };
    console.log(`flutter rpc (rpcId=${msg.rpcId})`)
    return new Promise<any[]>((resolve, reject) => {
        promises[msg.rpcId.toString()] = { resolve: resolve, reject: reject };
        sendMessageToWebView(msg);
    });
}

let promises: { [idx: string]: IResolveReject | undefined } = {};
let lastPromiseIdx = 1;
let sendMessageToWebView = receivedFromFlutter;

export function receiveMessageFromWebView(msg: IStreamMessage<any>) {
    switch (msg.streamId) {
        case StreamIds.promiseCallback:
            rpcCallback(msg)
            break
        case StreamIds.consoleLog:
            break
        default:
            if (!msg.name) return
            let listenner = listenners[msg.name];
            if (!listenner) return;
            listenner(msg.streamId, msg.value);
            break
    }
}
export let listenners: {[name:string]:(streamId: StreamIds, valye: any) => void} = {}

function rpcCallback(msg: IStreamMessage<IRpcResult<any>>) {
    console.log(`flutter rpc Callback (rpcId=${msg.value.rpcId})`)
    let resolveReject = promises[msg.value.rpcId.toString()]
    delete promises[msg.value.rpcId.toString()]
    if (!resolveReject) throw 'not found'
    if (msg.value.error != null) resolveReject.reject(msg.value.error);
    else resolveReject.resolve(msg.value.result);
}

interface IResolveReject {
    resolve: (res: any) => void
    reject: (error?: any) => void
}

