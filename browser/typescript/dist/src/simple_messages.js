"use strict";
window?.chrome?.webview?.addEventListener('message', (event) => {
    let data = JSON.parse(event);
});
