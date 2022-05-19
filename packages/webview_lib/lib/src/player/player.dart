import '../rpc/handlers.dart';
import '../rpc/rpc.dart';

export 'interface.dart';

class PlayerProxy {
  static Future<PlayerProxy> create(String url, {void Function(int streamId, IRpcResult value)? listen}) async {
    final res = new PlayerProxy();
    if (listen != null) handlerListenners[res.audioName] = listen;
    await fncCall(null, 'createPlayer', [res.playerName, res.audioName, url]);
    return res;
  }

  final playerName = newHandlerName();
  final audioName = newHandlerName();
  Future dispose() async {
    await fncCall(this.playerName, 'dispose');
    handlerListenners.remove(audioName);
  }

  Future play() => fncCall(this.audioName, 'play');
  Future stop() => rpc([
        getFncCall(this.audioName, 'pause'),
        getSetCall(this.audioName, 'currentTime', 0),
      ]);
}
