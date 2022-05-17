import { HTMLApp, rpc } from './src/htmlApp/index';
import { FncType } from './src/messager/index';

import './src/messager/index';
import './src/player/index';
import './src/htmlApp/app';


async function flutterRun() {
    await HTMLApp.appInit();
    let res = await rpc([
        { name: 'window.testFunctions.simple', arguments: [1, '2'] },
        { name: 'window.testFunctions.inner.run', arguments: [false] },
        { name: 'window.testFunctions.test.sum', arguments: [10, 20] },
        { name: 'window.testFunctions.test.prop', arguments: [100], type: FncType.setter },
        { name: 'window.testFunctions.test.prop', arguments: [], type: FncType.getter },
    ]);
    console.log(res);
}

// javascriptRun
class Test {
    sum(a: number, b: number) { return a + b }
    set prop(v: number) { this.value = v; }
    get prop() { return this.value; }
    value: number = 0;
}

(window as any)['testFunctions'] = {
    'simple': (p1: number, p2: string) => {
        console.log(`window.testFunctions.simple(${p1}, ${p2})`)
        return 'res1'
    },
    'inner': {
        'run': (p1: boolean) => {
            console.log(`window.testFunctions.inner.run(${p1})`)
            return 12.6
        }
    },
    'test': new Test(),
}

setTimeout(flutterRun)
