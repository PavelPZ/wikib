export const enum Platforms {
    none = 0, web = 1, mobile = 2, windows = 3, html = 4,
}

export const enum StreamIds {
    none = 0, 
    promiseCallback = 1, consoleLog = 2,
    playerReadyState = 5, playerError = 6, playState = 7, playPosition = 8, playDurationchange = 9,
}

export interface IOutMessage<T> {
    streamId: StreamIds
    value: T
}

export interface IOutRpcResult<TResult>{
    rpcId: number
    result: TResult | null
    error: string | null
}

export interface IPlatform {
    postMessage<T>(item: IOutMessage<T>): void
}

export interface IInFncCall {
    name: string;
    arguments: any[];
}

export interface IRpcCall {
    rpcId: number
    fncs: IInFncCall[];
}

export let callback: IPlatform

export function setCallback (_callback: IPlatform) {
    callback = _callback;
}

export function rpcResult<TResult>(promiseId: number, result: TResult | null, error: string | null) {
    callback.postMessage<IOutRpcResult<TResult>>({ streamId: StreamIds.promiseCallback, value: { rpcId: promiseId, result: result, error: error } })
}



