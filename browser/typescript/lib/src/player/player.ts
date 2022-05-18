import { PlayState, ReadyStates } from "./interface";
import { platform, StreamIds } from "../rpc/index";

window.wikib.createPlayer = (playerName: number, audioName: number, url: string) => new Player(playerName, audioName, url)

export class Player {
    constructor(playerName: number, audioName: number, url: string) {
        const audio = new Audio(url)

        const onStream = (streamId: StreamIds, value: number) => { 
            platform.postMessage({ streamId: streamId, name: audioName, value: value })
        }
        let listeners: { [type: string]: EventListenerOrEventListenerObject } = {}
        const addListenner = (type: string, listener: EventListenerOrEventListenerObject) => { 
            audio.addEventListener(type, listener);
            listeners[type] = listener; return listener; 
        }

        addListenner("durationchange", () => onStream(StreamIds.playDurationchange, audio.duration))
        // audio.addEventListener("progress", addListenner("progress", () => {
        //     let curr = this.audio.currentTime
        //     let last = this.lastProgress
        //     this.lastProgress = curr;
        //     if (curr > last && curr < last + this.currentPositionTimerMsec) return
        //     onStream(StreamIds.playPosition, curr)
        // }))

        addListenner("ended", () => onStream(StreamIds.playState, PlayState.ended))
        addListenner("pause", () => onStream(StreamIds.playState, PlayState.pause))
        addListenner("play", () => onStream(StreamIds.playState, PlayState.play))

        // https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
        // audio.error?.code: MEDIA_ERR_ABORTED, MEDIA_ERR_NETWORK, MEDIA_ERR_DECOD, MEDIA_ERR_SRC_NOT_SUPPORTED            
        addListenner("error", () => onStream(StreamIds.playerError, audio.error?.code ?? 0))
        // https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState
        // readyState == HAVE_META_DATA
        addListenner("loadedmetadata", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_METADATA))
        // readyState == HAVE_CURRENT_DATA
        addListenner("loadeddata", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_CURRENT_DATA))
        // readyState == HAVE_FUTURE_DATA
        addListenner("canplay", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_FUTURE_DATA))
        // readyState == HAVE_ENOUGH_DATA
        addListenner("canplaythrough", () => onStream(StreamIds.playerReadyState, ReadyStates.HAVE_ENOUGH_DATA))

        window.wikib[playerName.toString()] = this;
        window.wikib[audioName.toString()] = audio;

        this.dispose = () => {
            for (let key in listeners) audio.removeEventListener(key, listeners[key])
            audio.pause()
            delete window.wikib[playerName.toString()]
            delete window.wikib[audioName.toString()]
        }
    }

    dispose: () => void
}

// https://stackoverflow.com/questions/4338951/how-do-i-determine-if-mediaelement-is-playing
Object.defineProperty(HTMLMediaElement.prototype, 'playing', {
    get: function () {
        return !!(this.currentTime > 0 && !this.paused && !this.ended && this.readyState > 2);
    }
})

