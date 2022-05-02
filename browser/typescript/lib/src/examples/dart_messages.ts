function dartMessage() {
  let body = document.body;
  let div = document.querySelector('#receiveMessage') as HTMLDivElement;
  if (window?.chrome?.webview) {
    window.chrome.webview.addEventListener('message', (event) => {
      let json = event.data;
      try {
        div.innerHTML = JSON.stringify(json);
        json.webview = 'Hallo world WebView';
        json.message = 'resend';
        window.chrome.webview.postMessage(json);
      }
      catch (msg: any) {
        div.innerHTML = msg.toString();
      }
    });
  }
  body.addEventListener('click', () => {
    let msg = JSON.parse('{"message":"webview", "number": 1.3, "bool": true, "string": "string"}');
    window?.chrome?.webview?.postMessage(msg);
    div.innerHTML = JSON.stringify(msg);
  });
}
dartMessage();
