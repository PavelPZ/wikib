export const enum Platforms {
    none = 0, web = 1, mobile = 2, windows = 3, html = 4,
}

export const enum StreamIds {
    none = 0,
    promiseCallback = 1, consoleLog = 2,
    playerReadyState = 5, playerError = 6, playState = 7, playDurationchange = 8,
}

export interface IStreamMessage<T> {
    streamId: StreamIds
    handlerId?: number | undefined
    value: T
}

export interface IRpcResult<TResult> {
    rpcId: number
    result: TResult | null
    error: string | null
}

export const enum RpcFncTypes { getter = 0, setter = 1, }

export interface IRpcFnc {
    name: string;
    type?: RpcFncTypes | undefined; // undefined for function
    arguments: any[];
}

export interface IRpc {
    rpcId: number
    fncs: IRpcFnc[];
}

export interface IPlatform {
    postToFlutter<T>(item: IStreamMessage<T>): void
}
