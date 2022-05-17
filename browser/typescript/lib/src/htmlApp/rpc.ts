import { FncType, IInFncCall, IOutMessage, IOutRpcResult, IRpcCall, receivedMessageFromFlutter, StreamIds } from "../messager/index";

export function rpc(calls: IInFncCall[]): Promise<any[]> {
    let msg: IRpcCall = { rpcId: lastPromiseIdx++, fncs: calls };
    console.log(`flutter rpc (rpcId=${msg.rpcId})`)
    return new Promise<any[]>((resolve, reject) => {
        promises[msg.rpcId] = { resolve: resolve, reject: reject };
        sendMessageToWebView(msg);
    });
}

let promises: (IResolveReject | undefined)[] = [];
let lastPromiseIdx = 1;
let sendMessageToWebView = receivedMessageFromFlutter;

export function newHandlerName() {
    return handlerCounter++;
}
let handlerCounter = 1;

export function receiveMessageFromWebView(msg: IOutMessage<any>) {
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

function rpcCallback(msg: IOutMessage<IOutRpcResult<any>>) {
    console.log(`flutter rpc Callback (rpcId=${msg.value.rpcId})`)
    let resolveReject = promises[msg.value.rpcId]
    delete promises[msg.value.rpcId]
    if (!resolveReject) throw 'not found'
    if (msg.value.error != null) resolveReject.reject(msg.value.error);
    else resolveReject.resolve(msg.value.result);
}

interface IResolveReject {
    resolve: (res: any) => void
    reject: (error?: any) => void
}

function getFncItem(handler: number | null, name: string, type?: FncType | undefined, args?: any[]) {
    let fncCall: IInFncCall = {
        name: handler == null ? `.${name}` : `.${handler}.${name}`,
        type: type,
        arguments: args ?? [],
    };
    return fncCall;
}

export function getFncCall(handler: number | null, name: string, args?: any[]) {
    return getFncItem(handler, name, undefined, args);
}

export function getGetCall(handler: number, name: string) {
    return getFncItem(handler, name, FncType.getter, []);
}

export function getSetCall(handler: number, name: string, value: any) {
    return getFncItem(handler, name, FncType.setter, [value]);
}

export async function fncCall<T>(handler: number | null, name: string, args?: any[]) {
    let res = await rpc([getFncCall(handler, name, args)]);
    return res[0] as T;
}

export async function getCall<T>(handler: number, name: string) {
    let res = await rpc([getGetCall(handler, name)]);
    return res[0] as T;
}

export async function setCall(handler: number, name: string, value: any) {
    await rpc([getSetCall(handler, name, value)]);
}

