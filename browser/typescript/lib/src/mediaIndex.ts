import { getErrorMessage, rpcResult, setPlatform } from "./messagerIndex.js";
import { Player, players, IPlayerConstructor } from "./playerIndex.js";

export * from "./messagerIndex.js";
export * from "./playerIndex.js";

export const media = {
    setPlatform: setPlatform,
    createPlayer: function createPlayer(pars: IPlayerConstructor) {
        try {
            let player = new Player(pars)
            rpcResult<number>(pars.promiseId, player.id, null)
        } catch (error) {
            rpcResult<number>(pars.promiseId, null, getErrorMessage(error))
        }
    },
    players: players,
};


(window as any)['media'] = media
