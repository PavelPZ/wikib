type TJson = { [idx: string]: any };
interface Event {
  data: IRpc;
}
interface Window {
  chrome: {
    webview: {
      postMessage: (json: dynamic) => void
      addEventListener: (message: 'message', event: (event: Event) => void) => void
    }
  }
  wikib: { [idx: string]: any }
}
