import 'package:flutter/material.dart';
import 'package:tieba_image_parser/utils/web_io.dart';
// import 'package:shared_preferences/shared_preferences.dart';

class SettingsState extends ChangeNotifier {
  final proxyTypes = <String>['none', 'http', 'socks5'];

  final ProxyConfig _proxyConfig = ProxyConfig();

  String get proxyType => _proxyConfig.type;
  String get proxyHost => _proxyConfig.host;
  String get proxyPort => _proxyConfig.port;
  String get proxyUsername => _proxyConfig.username;
  String get proxyPassword => _proxyConfig.password;
  ProxyConfig get proxyConfig => _proxyConfig;

  set proxyType(String value) {
    _proxyConfig.type = value;
    notifyListeners();
  }

  SettingsState() {
    _loadProxy();
  }

  void _loadProxy() {
    applyProxySettings(
      proxyType: 'none',
      proxyHost: '',
      proxyPort: '',
      proxyUsername: '',
      proxyPassword: '',
    );
  }

  bool checkValidity({
    required String proxyType,
    required String proxyHost,
    required String proxyPort,
    required String proxyUsername,
    required String proxyPassword,
  }) {
    if (proxyType == 'none') {
      return true;
    }
    if (proxyType == 'http') {
      if (proxyHost.isEmpty || proxyPort.isEmpty) {
        return false;
      }
    } else if (proxyType == 'with auth') {
      if (proxyHost.isEmpty || proxyPort.isEmpty) {
        return false;
      }
      if (proxyUsername.isEmpty || proxyPassword.isEmpty) {
        return false;
      }
    }
    final port = int.tryParse(proxyPort);
    if (port == null || port < 1 || port > 65535) {
      return false;
    }
    return true;
  }

  bool _isApplying = false;
  Future<void> applyProxySettings({
    required String proxyType,
    required String proxyHost,
    required String proxyPort,
    required String proxyUsername,
    required String proxyPassword,
  }) async {
    _proxyConfig.type = proxyType;
    _proxyConfig.host = proxyHost;
    _proxyConfig.port = proxyPort;
    _proxyConfig.username = proxyUsername;
    _proxyConfig.password = proxyPassword;

    if (_isApplying) return;
    _isApplying = true;
    await WebIO.setProxy(_proxyConfig);
    notifyListeners();
    _isApplying = false;
  }
}
