import { HTMLApp } from './src/htmlApp/app.js';
import { rpc } from './src/htmlApp/rpc.js';
import { media } from './src/mediaIndex.js';

let m = media;

async function flutterRun() {
    await HTMLApp.appInit();
    let res = await rpc([
        {name: 'window.testFunctions.simple', arguments: [1, '2']},
        {name: 'window.testFunctions.inner.run', arguments: [false]},
    ]);
    console.log(res);
}

// javascriptRun
(window as any)['testFunctions'] = {
    'simple': (p1: number,p2:string) => {
        console.log(`window.testFunctions.simple(${p1}, ${p2})`)
        return 'res1'
    },
    'inner': {
        'run': (p1: boolean) => {
            console.log(`window.testFunctions.inner.run(${p1})`)
            return 12.6
        }
    }
}

setTimeout(flutterRun)
