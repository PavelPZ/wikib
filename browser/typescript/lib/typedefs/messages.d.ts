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
  wikib: { 
    receivedFromFlutter: (rpcCall: IRpc) => void
    [idx: string]: any
  }
  
  flutter_inappwebview: {
    callHandler: (name: 'webMessageHandler', arg: any) => void
  }
}
