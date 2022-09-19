//*** see \wikib\browser\typescript\lib\src\player\interface.ts */

class PlayState {
  static int none = 0;
  static int play = 1;
  static int pause = 2;
  static int ended = 3;
}

// https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/readyState
class ReadyStates {
  static int HAVE_NOTHING = 0;
  static int HAVE_METADATA = 1;
  static int HAVE_CURRENT_DATA = 2;
  static int HAVE_FUTURE_DATA = 3;
  static int HAVE_ENOUGH_DATA = 4;
}

// https://developer.mozilla.org/en-US/docs/Web/API/MediaError/code#media_error_code_constants
class ErrorCodes {
  static int MEDIA_ERR_ABORTED = 1;
  static int MEDIA_ERR_NETWORK = 2;
  static int MEDIA_ERR_DECODE = 3;
  static int MEDIA_ERR_SRC_NOT_SUPPORTED = 4;
}

final fake = 1;
