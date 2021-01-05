import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/service/audio_player.dart';
import 'package:polaris/service/cache.dart' as cache;
import 'package:polaris/service/collection.dart';
import 'package:polaris/service/proxy_server.dart';
import 'package:polaris/shared/http_collection_api.dart';
import 'package:polaris/shared/token.dart' as token;
import 'package:polaris/shared/shared_preferences_host.dart';

final getIt = GetIt.instance;

final String customActionGetPort = 'getPort';

ProxyServer _proxyServer;

void entrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hostManager = await SharedPreferencesHost.create();
  final tokenManager = await token.Manager.create();
  final cacheManager = await cache.Manager.create();
  final collectionAPI = HttpCollectionAPI(client: Client(), tokenManager: tokenManager, hostManager: hostManager);
  final Collection collection = new Collection(
    hostManager: hostManager,
    cacheManager: cacheManager,
    collectionAPI: collectionAPI,
  );
  _proxyServer = await ProxyServer.create(collection);
  await AudioServiceBackground.run(() {
    return AudioPlayerTask(proxyServerPort: _proxyServer.port);
  });
}
