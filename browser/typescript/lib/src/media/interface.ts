export const enum Platforms {
    none = 0, web = 1, mobile = 2, windows = 3,
}

export const enum StreamIds {
    none = 0, 
    promiseCallback = 1, consoleLog = 2,
    playerReadyState = 5, playerError = 6, playState = 7, playPosition = 8, playDurationchange = 9,
}

export interface IStreamItem<T> {
    streamId: StreamIds
    value: T
}

export interface IPlayerStreamValue {
    playerId: number
    value: number
}

export interface IPromiseStreamValue<TResult>{
    promiseId: number
    result: TResult | null
    error: string | null
}

export interface IStreamCallback {
    onStream<T>(item: IStreamItem<T>): void
}

export interface IInt {
    value: number;
}

export interface IString {
    value: string;
}

