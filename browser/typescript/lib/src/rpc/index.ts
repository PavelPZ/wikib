import { Platforms } from './interface';
import { setPlatform } from './lib';
import { HtmlPlatform } from './platformHtml';
import { WebPlatform } from './platformWeb';
import { WindowsPlatform } from './platformWindows';

export * from './interface';
export * from './lib';
export * from './platformHtml';
export * from './platformWeb';
export * from './platformWindows';

window.wikib.setPlatform = (platformId: Platforms) => {
    switch (platformId) {
        case Platforms.web:
            setPlatform(new WebPlatform())
            break
        case Platforms.windows:
            setPlatform(new WindowsPlatform());
            break
        case Platforms.html:
            setPlatform(new HtmlPlatform())
            break
    }
    console.log(`-window.media.setPlatform(${platformId})`);
}

