import { Platforms, setCallback } from './interface';
import { HtmlPlatform } from './platformHtml';
import { WebPlatform } from './platformWeb';
import { WindowsPlatform } from './platformWindows';

export * from './interface.js';
export * from './platformHtml.js';
export * from './platformWeb.js';
export * from './platformWindows.js';

window.wikib.setPlatform = (platform: Platforms) => {
    switch (platform) {
        case Platforms.web:
            setCallback(new WebPlatform())
            break
        case Platforms.windows:
            setCallback(new WindowsPlatform((_) => { }))
            break
        case Platforms.html:
            setCallback(new HtmlPlatform())
            break
    }
    console.log(`-window.media.setPlatform(${platform})`);
}

