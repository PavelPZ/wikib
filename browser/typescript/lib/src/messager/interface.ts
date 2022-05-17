export const enum Platforms {
    none = 0, web = 1, mobile = 2, windows = 3, html = 4,
}

export const enum StreamIds {
    none = 0,
    promiseCallback = 1, consoleLog = 2,
    playerReadyState = 5, playerError = 6, playState = 7, playDurationchange = 8,
}

export interface IOutMessage<T> {
    streamId: StreamIds
    name?: number | undefined
    value: T
}

export interface IOutRpcResult<TResult> {
    rpcId: number
    result: TResult | null
    error: string | null
}

export interface IPlatform {
    postMessage<T>(item: IOutMessage<T>): void
}

export const enum FncType { getter, setter, }

export interface IInFncCall {
    name: string;
    type?: FncType | undefined; // undefined for function
    arguments: any[];
}

export interface IRpcCall {
    rpcId: number
    fncs: IInFncCall[];
}

export let callback: IPlatform

export function setCallback(_callback: IPlatform) {
    callback = _callback;
}

export function rpcResult<TResult>(promiseId: number, result: TResult | null, error: string | null) {
    callback.postMessage<IOutRpcResult<TResult>>({ streamId: StreamIds.promiseCallback, value: { rpcId: promiseId, result: result, error: error } })
}

export function rpcCall(promiseId: number, action: () => any) {
    try {
        let res = action()
        rpcResult<number>(promiseId, res, null)
    } catch (error) {
        rpcResult<number>(promiseId, null, getErrorMessage(error))
    }
}

export function getErrorMessage(error: unknown) {
    if (error instanceof Error) return error.message
    return String(error)
}

export function receivedMessageFromFlutter(rpcCall: IRpcCall) {
    function getFunction(path: string[], idx: number, res: any): any {
        let act = path[idx]
        if (idx == 0) {
            if (act == '') return getFunction(path, idx + 1, window.wikib)
            else if (act != 'window') throw `receivedMessageFromFlutter.getFunction.act!=window: ${act}`
            else return getFunction(path, idx + 1, window)
        }
        if (idx >= path.length) return res
        let newRes = res[act]
        if (!newRes) throw `receivedMessageFromFlutter.getFunction.act=${act}`
        return getFunction(path, idx + 1, res[act])
    }
    try {
        let res: any[] = [];
        rpcCall.fncs.forEach((fnc: IInFncCall) => {
            let path = fnc.name.split('.');
            switch (fnc.type) {
                case FncType.getter:
                    res.push(getFunction(path, 0, null))
                    break;
                case FncType.setter:
                    let last = path.pop() as string
                    let obj = getFunction(path, 0, null)
                    obj[last] = fnc.arguments[0];
                    res.push(undefined);
                    break;
                default:
                    let fncObj: Function = getFunction(fnc.name.split('.'), 0, null)
                    res.push(fncObj.call(undefined, ...fnc.arguments))
                    break;
            }
        });
        rpcResult<any[]>(rpcCall.rpcId, res, null)
    } catch (msg) {
        rpcResult<void>(rpcCall.rpcId, null, getErrorMessage(msg))
    }
}

let _backupconsolelog = console.log;
function _divLog(message: string) {
    let consoleLog = document.getElementById("consoleLog")!;
    consoleLog.innerHTML = consoleLog.innerHTML + "<br/>" + message;
}
console.log = function (message: string) {
    _backupconsolelog(message);
    _divLog(message);
    if (!callback) return;
    callback.postMessage<string>({streamId: StreamIds.consoleLog, value: message });
}

window.wikib = {}