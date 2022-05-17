import { HTMLApp, PlayerProxy, rpc } from './src/htmlApp/index';
import { FncType, StreamIds } from './src/messager/index';

import './src/messager/index';
import './src/player/index';
import './src/htmlApp/app';

const longUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
const shortUrl = 'https://free-loops.com/data/mp3/c8/84/81a4f6cc7340ad558c25bba4f6c3.mp3';
const playUrl = shortUrl

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

    let player = await PlayerProxy.create(playUrl, (id, value) => {
        switch (id) {
            case StreamIds.playDurationchange:
                document.getElementById('duration')!.innerHTML = value.toString()
                break
            case StreamIds.playState:
            case StreamIds.playerReadyState:
                let div = document.getElementById('state')!
                div.innerHTML = div.innerHTML + ', ' + id.toString() + '=' + value.toString()
                break
        }
    })
    await player.play();
    await new Promise(resolve => setTimeout(resolve, 100000))
    await player.stop()
    await new Promise(resolve => setTimeout(resolve, 1000))
    await player.dispose()
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

document.getElementById('playbtn')?.addEventListener('click', () => flutterRun())
//setTimeout(flutterRun)
