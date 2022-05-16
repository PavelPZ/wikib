import { IInFncCall, IOutMessage, IOutRpcResult, IRpcCall } from "../messager/interface";
import { HTMLApp } from "./app";

export function rpc<T>(calls: IInFncCall[]):Promise<T>  {
    let msg: IRpcCall = { rpcId:lastPromiseIdx++, fncs: calls};
    return new Promise<T>((resolve, reject) => {
        promises[msg.rpcId] = {resolve: resolve, reject:reject};
        HTMLApp.postMessage(msg);
    });
}

let promises: (IResolveReject | undefined)[] = [];
let lastPromiseIdx = 0;

export function rpcCallback(msg: IOutMessage<IOutRpcResult<any>>) {
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

