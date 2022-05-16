import { IPlayerStreamValue, StreamIds } from "./interface.js"
import { callback, getErrorMessage, IPlayerConstructor, promiseCallback } from "./common.js"

export let players = {} as { [key: string]: Player }

const enum PlayState {
    none = 0, play = 1, pause = 2, ended = 3,
}

// https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
const enum ReadyStates {
    HAVE_NOTHING = 0, HAVE_METADATA = 1, HAVE_CURRENT_DATA = 2, HAVE_FUTURE_DATA = 3, HAVE_ENOUGH_DATA = 4
}

// https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
const enum ErrorCodes {
    MEDIA_ERR_ABORTED = 1, MEDIA_ERR_NETWORK = 2, MEDIA_ERR_DECODE = 3, MEDIA_ERR_SRC_NOT_SUPPORTED = 4
}

export class Player {
    constructor(pars: IPlayerConstructor) {
        this.id = playerCount++;
        players[`player_${this.id}`] = this
        const { url } = pars
        this.currentPositionTimerMsec = pars.currentPositionTimerMsec ?? 300
        this.url = url
        const audio = this.audio = new Audio(url)

        const onStream = (streamId: StreamIds, value: number) => callback.onStream<IPlayerStreamValue>({ streamId: streamId, value: { playerId: this.id, value: value } });
        const addListenner = (type: string, listener: EventListenerOrEventListenerObject) => { this.listeners[type] = listener; return listener; }

        audio.addEventListener("durationchange", addListenner("durationchange", () => onStream(StreamIds.playDurationchange, audio.duration)))
        audio.addEventListener("progress", addListenner("progress", () => {
            let curr = this.audio.currentTime
            let last = this.lastProgress
            this.lastProgress = curr;
            if (curr > last && curr < last + this.currentPositionTimerMsec) return
            onStream(StreamIds.playPosition, curr)
        }))

        audio.addEventListener("ended", addListenner("ended", () => onStream(StreamIds.playState, PlayState.ended)))
        audio.addEventListener("pause", addListenner("pause", () => onStream(StreamIds.playState, PlayState.pause)))
        audio.addEventListener("play", addListenner("play", () => onStream(StreamIds.playState, PlayState.play)))

        // https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
        // audio.error?.code: MEDIA_ERR_ABORTED, MEDIA_ERR_NETWORK, MEDIA_ERR_DECOD, MEDIA_ERR_SRC_NOT_SUPPORTED            
        audio.addEventListener("error", addListenner("error", () => onStream(StreamIds.playerError, audio.error?.code ?? 0)))
        // https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState
        // readyState == HAVE_META_DATA
        audio.addEventListener("loadedmetadata", addListenner("loadedmetadata", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_METADATA)))
        // readyState == HAVE_CURRENT_DATA
        audio.addEventListener("loadeddata", addListenner("loadeddata", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_CURRENT_DATA)))
        // readyState == HAVE_FUTURE_DATA
        audio.addEventListener("canplay", addListenner("canplay", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_FUTURE_DATA)))
        // readyState == HAVE_ENOUGH_DATA
        audio.addEventListener("canplaythrough", addListenner("canplaythrough", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_ENOUGH_DATA)))
    }

    id: number
    url: string
    audio: HTMLAudioElement
    currentPositionTimerMsec: number
    listeners: { [type: string]: EventListenerOrEventListenerObject } = {}
    lastProgress = 0;

    dispose(promiseId: number) {
        this._safeCall(promiseId, () => {
            for (let key in this.listeners) this.audio.removeEventListener(key, this.listeners[key])
            this.audio.pause()
            delete players[`player_${this.id}`]
        })
    }

    play(promiseId: number) {
        this._safeCall(promiseId, () => {
            this.audio.pause()
            this.audio.currentTime = 0
            this.audio.play()
        })
    }

    stop(promiseId: number) {
        this._safeCall(promiseId, () => {
            this.audio.pause()
            this.audio.currentTime = 0
        })
    }

    _safeCall (promiseId: number, action: Function) {
        try {
            action()
            promiseCallback<number>(promiseId, this.id, null)
        } catch (error) {
            promiseCallback<number>(promiseId, this.id, getErrorMessage(error))
        }
    }

}

let playerCount = 0

// https://stackoverflow.com/questions/4338951/how-do-i-determine-if-mediaelement-is-playing
Object.defineProperty(HTMLMediaElement.prototype, 'playing', {
    get: function () {
        return !!(this.currentTime > 0 && !this.paused && !this.ended && this.readyState > 2);
    }
})

