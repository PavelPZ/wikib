export const enum PlayState {
    none = 0, play = 1, pause = 2, ended = 3,
}

// https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
export const enum ReadyStates {
    HAVE_NOTHING = 0, HAVE_METADATA = 1, HAVE_CURRENT_DATA = 2, HAVE_FUTURE_DATA = 3, HAVE_ENOUGH_DATA = 4
}

// https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
export const enum ErrorCodes {
    MEDIA_ERR_ABORTED = 1, MEDIA_ERR_NETWORK = 2, MEDIA_ERR_DECODE = 3, MEDIA_ERR_SRC_NOT_SUPPORTED = 4
}

