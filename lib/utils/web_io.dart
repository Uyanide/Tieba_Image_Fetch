import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:socks5_proxy/socks_client.dart' as socks;
import 'package:tieba_image_parser/utils/pair.dart';

class ProxyConfig {
  static const List<String> types = ['none', 'http', 'socks5'];

  String type = 'none';
  String host = '';
  String port = '';
  String username = '';
  String password = '';

  @override
  String toString() {
    if (type == 'none') {
      return '无代理';
    }
    if (type == 'http') {
      return 'HTTP 代理: ${username.isNotEmpty ? '$username@' : ''}$host:$port';
    }
    if (type == 'socks5') {
      return 'SOCKS5 代理: ${username.isNotEmpty ? '$username@' : ''}$host:$port';
    }
    return '未知代理类型';
  }
}

class WebIO {
  static HttpClient _client = _newClient;

  static HttpClient get _newClient => HttpClient()
    ..userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0'
    ..connectionTimeout = const Duration(seconds: 30);

  /// Create a new HttpClient instance with the given [proxyConfig].
  static Future<void> setProxy(ProxyConfig proxyConfig) async {
    if (proxyConfig.type == 'none') {
      _client = _newClient;
    } else if (proxyConfig.type == 'http') {
      _client = _newClient
        ..findProxy = (uri) {
          return 'PROXY ${proxyConfig.host}:${proxyConfig.port}';
        };
      if (proxyConfig.username.isNotEmpty && proxyConfig.password.isNotEmpty) {
        _client.authenticate = (uri, scheme, realm) {
          if (scheme == 'Basic') {
            _client.addCredentials(
              uri,
              realm ?? '',
              HttpClientBasicCredentials(
                proxyConfig.username,
                proxyConfig.password,
              ),
            );
            return Future.value(true);
          }
          return Future.value(false);
        };
      }
    } else if (proxyConfig.type == 'socks5') {
      _client = _newClient;
      socks.SocksTCPClient.assignToHttpClient(_client, [
        socks.ProxySettings(
          InternetAddress.tryParse(proxyConfig.host) ??
              await InternetAddress.lookup(proxyConfig.host)
                  .then((addresses) => addresses.first),
          int.parse(proxyConfig.port),
          username: proxyConfig.username.isEmpty ? null : proxyConfig.username,
          password: proxyConfig.password.isEmpty ? null : proxyConfig.password,
        )
      ]);
    }
  }

  // static bool get _isInDebugMode {
  //   var inDebugMode = false;
  //   assert(inDebugMode = true);
  //   return inDebugMode;
  // }

  static List<Pair<String, Completer<Uint8List>>> urlQueue = [];
  static bool _isProcessing = false;

  static Future<Uint8List> get(String url, [int delay = 500]) async {
    Completer<Uint8List> completer = Completer();
    urlQueue.add(Pair(url, completer));
    if (!_isProcessing) {
      _isProcessing = true;
      _cycle(delay);
    }
    return completer.future;
  }

  static Future<void> _cycle(int delay) async {
    final random = Random();
    while (urlQueue.isNotEmpty) {
      final pair = urlQueue.removeAt(0);
      _get(pair.first).then((bytes) {
        pair.second.complete(bytes);
      }).catchError((e) {
        pair.second.completeError(e);
      });
      await Future.delayed(Duration(
          milliseconds: delay + random.nextInt(delay * 2 ~/ 5) - delay ~/ 5));
    }
    _isProcessing = false;
  }

  static Future<Uint8List> _get(String url) async {
    print('GET $url');
    final request = await _client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Request failed with status: ${response.statusCode}');
    } else {
      final bytes = await response.fold<Uint8List>(Uint8List(0), (bytes, data) {
        return Uint8List.fromList(bytes + data);
      });
      return bytes;
    }
  }
}
