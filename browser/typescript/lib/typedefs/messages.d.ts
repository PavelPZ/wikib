interface Event {
  data: any;
}
interface Window {
  chrome: {
    webview: {
      postMessage: (json: string) => void;
      addEventListener: (message: 'message', event: (event: Event) => void) => void;
    };
  };
}
