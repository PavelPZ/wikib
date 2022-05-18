import { Platforms } from './interface';
import { setPlatform } from './lib.js';
import { HtmlPlatform } from './platformHtml';
import { WebPlatform } from './platformWeb';
import { WindowsPlatform } from './platformWindows';

export * from './interface.js';
export * from './lib.js';
export * from './platformHtml.js';
export * from './platformWeb.js';
export * from './platformWindows.js';

window.wikib.setPlatform = (platformId: Platforms) => {
    switch (platformId) {
        case Platforms.web:
            setPlatform(new WebPlatform())
            break
        case Platforms.windows:
            setPlatform(new WindowsPlatform((_) => { }))
            break
        case Platforms.html:
            setPlatform(new HtmlPlatform())
            break
    }
    console.log(`-window.media.setPlatform(${platformId})`);
}

