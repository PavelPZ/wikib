import { IStreamCallback, IPromiseStreamValue, StreamIds } from "./interface"

// http://www.kaizou.org/2013/03/html5-media-state-machine-explained.html
export interface IPlayerConstructor {
    url: string
    promiseId: number
    currentPositionTimerMsec?: number
}

export function setCallback(_callback: IStreamCallback) {
    callback = _callback;
}

export let callback: IStreamCallback

export function promiseCallback<TResult>(promiseId: number, result: TResult | null, error: string | null) {
    callback.onStream<IPromiseStreamValue<TResult>>({ streamId: StreamIds.promiseCallback, value: { promiseId: promiseId, result: result, error: error } })
}

export function getErrorMessage(error: unknown) {
    if (error instanceof Error) return error.message
    return String(error)
}


let backupconsolelog = console.log;
console.log = function (message: string) {
    backupconsolelog(message);
    if (!callback) return;
    callback.onStream<string>({streamId: StreamIds.consoleLog, value: message });
}