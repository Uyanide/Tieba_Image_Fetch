import 'dart:io';
import 'dart:typed_data';
import 'package:tieba_image_parser/socks/socks_dart/lib/socks_client.dart'
    as socks;

class ProxyConfig {
  static const List<String> types = ['none', 'http', 'socks5'];

  String type = 'none';
  String host = '';
  String port = '';
  String username = '';
  String password = '';
}

class WebIO {
  static HttpClient _client = _newClient;

  static HttpClient get _newClient => HttpClient()
    ..userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0'
    ..connectionTimeout = const Duration(seconds: 30);

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

  static Future<Uint8List> get(String url) async {
    final request = await _client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('Request failed with status: ${response.statusCode}');
    }
    return await response.fold<Uint8List>(Uint8List(0), (bytes, data) {
      return Uint8List.fromList(bytes + data);
    });
  }
}
