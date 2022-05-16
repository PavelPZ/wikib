import { setCallback, IPlayerConstructor, promiseCallback, getErrorMessage } from "./common.js"
import { Platforms } from "./interface.js"
import { Player, players } from "./player.js"
import { WebPlatform } from "./web.js";
import { WindowsPlatform } from "./windows.js";

export const media = {
    setPlatform: function setPlatform(platform: Platforms) {
        switch (platform) {
            case Platforms.web:
                setCallback(new WebPlatform())
                break
            case Platforms.windows:
                setCallback(new WindowsPlatform())
                break
        }
        console.log(`media.setPlatform(${platform})`);
    },
    createPlayer: function createPlayer(pars: IPlayerConstructor) {
        try {
            let player = new Player(pars)
            promiseCallback<number>(pars.promiseId, player.id, null)
        } catch (error) {
            promiseCallback<number>(pars.promiseId, null, getErrorMessage(error))
        }
    },
    players: players,
};


(window as any)['media'] = media
