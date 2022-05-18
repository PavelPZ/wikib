import { RpcFncTypes, IRpcFnc } from "../rpc/index";
import { rpc } from "./rpc_call";

export function newHandlerName() {
    return handlerCounter++;
}
let handlerCounter = 1;

function getFncItem(handler: number | null, name: string, type?: RpcFncTypes | undefined, args?: any[]) {
    let fncCall: IRpcFnc = {
        name: handler == null ? `.${name}` : `.${handler}.${name}`,
        type: type,
        arguments: args ?? [],
    };
    return fncCall;
}

export function getFncCall(handler: number | null, name: string, args?: any[]) {
    return getFncItem(handler, name, undefined, args);
}

export function getGetCall(handler: number, name: string) {
    return getFncItem(handler, name, RpcFncTypes.getter, []);
}

export function getSetCall(handler: number, name: string, value: any) {
    return getFncItem(handler, name, RpcFncTypes.setter, [value]);
}

export async function fncCall<T>(handler: number | null, name: string, args?: any[]) {
    let res = await rpc([getFncCall(handler, name, args)]);
    return res[0] as T;
}

export async function getCall<T>(handler: number, name: string) {
    let res = await rpc([getGetCall(handler, name)]);
    return res[0] as T;
}

export async function setCall(handler: number, name: string, value: any) {
    await rpc([getSetCall(handler, name, value)]);
}

