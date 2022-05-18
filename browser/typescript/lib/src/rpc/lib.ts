import { IRpc, IRpcFnc, IRpcResult, IStreamMessage, RpcFncTypes, StreamIds } from "./interface";

export interface IPlatform {
    postMessage<T>(item: IStreamMessage<T>): void
}

export let platform: IPlatform

export function setPlatform(_callback: IPlatform) {
    platform = _callback;
}

export function postRpcResult<TResult>(promiseId: number, result: TResult | null, error: string | null) {
    platform.postMessage<IRpcResult<TResult>>({ streamId: StreamIds.promiseCallback, value: { rpcId: promiseId, result: result, error: error } })
}

export function getErrorMessage(error: unknown) {
    if (error instanceof Error) return error.message
    return String(error)
}

export function receivedMessageFromFlutter(rpcCall: IRpc) {
    function getFunction(path: string[], idx: number, res: any): any {
        let act = path[idx]
        if (idx == 0) {
            if (act == '') return getFunction(path, idx + 1, window.wikib)
            else if (act != 'window') throw `receivedMessageFromFlutter.getFunction.act!=window: ${act}`
            else return getFunction(path, idx + 1, window)
        }
        if (idx >= path.length) return res
        let newRes = res[act]
        if (newRes==undefined) throw `receivedMessageFromFlutter.getFunction.act=${act}`
        return getFunction(path, idx + 1, res[act])
    }
    try {
        // console.log(`receivedMessageFromFlutter (rpcId=${rpcCall.rpcId})`)
        let res: any[] = [];
        rpcCall.fncs.forEach((fnc: IRpcFnc) => {
            let path = fnc.name.split('.');
            switch (fnc.type) {
                case RpcFncTypes.getter:
                    res.push(getFunction(path, 0, null))
                    break;
                case RpcFncTypes.setter:
                    let last = path.pop() as string
                    let obj = getFunction(path, 0, null)
                    obj[last] = fnc.arguments[0];
                    res.push(undefined);
                    break;
                default:
                    let fncObj: Function = getFunction(fnc.name.split('.'), 0, null)
                    let handlerId = parseInt(path[1])
                    let handler = isNaN(handlerId) ?  undefined : window.wikib[path[1]];
                    res.push(fncObj.call(handler, ...fnc.arguments))
                    break;
            }
        });
        postRpcResult<any[]>(rpcCall.rpcId, res, null)
    } catch (msg) {
        postRpcResult<void>(rpcCall.rpcId, null, getErrorMessage(msg))
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
    if (!platform) return;
    platform.postMessage<string>({ streamId: StreamIds.consoleLog, value: message });
}

window.wikib = {}