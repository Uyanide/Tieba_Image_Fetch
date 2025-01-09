import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tieba_image_parser/utils/error_handler.dart';
import 'package:tieba_image_parser/utils/web_io.dart';

class MainAppState extends ChangeNotifier with WidgetsBindingObserver {
  late bool isDarkMode;
  late Locale locale;
  String? version;

  MainAppState() {
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  void initialize() {
    initializeDarkMode();
    _getVersion().then((value) {
      ErrorHandler.logCommon('Current version: $value');
      version = value;
      notifyListeners();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        checkUpdate(showSuccess: false);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void initializeDarkMode() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    isDarkMode = brightness == Brightness.dark;
    notifyListeners();
  }

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    final brightness = PlatformDispatcher.instance.platformBrightness;
    setDarkMode(brightness == Brightness.dark);
  }

  void setDarkMode(bool isDarkMode) {
    if (this.isDarkMode != isDarkMode) {
      this.isDarkMode = isDarkMode;
      notifyListeners();
    }
  }

  Future<void> checkUpdate({bool showSuccess = true}) async {
    try {
      final jsonStr = utf8.decode(await WebIO.get(
          'https://api.uyanide.com/tieba-image-fetch/latest-version'));
      final latestVersion = json.decode(jsonStr)['version'];
      final changeLog = json.decode(jsonStr)['changeLog'];
      if (latestVersion != version) {
        ErrorHandler.logCommon('New version available: $latestVersion');
        ErrorHandler.showUpdateDialog(latestVersion, changeLog);
      } else if (showSuccess) {
        ErrorHandler.showErrorDialog('🎉恭喜🎉', '已是最新版本');
      }
    } catch (e, s) {
      ErrorHandler.logError(e, s);
    }
  }

  Future<String> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    // String buildNumber = packageInfo.buildNumber;
    return version;
  }
}
