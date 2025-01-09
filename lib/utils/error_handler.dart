import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ErrorHandler {
  static void showErrorDialog(String title, String message,
      {Function()? onPressed}) {
    if (navigatorKey.currentContext == null) return;
    final navigator = Navigator.of(navigatorKey.currentContext!);
    showDialog(
      context: navigator.overlay!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  onPressed?.call();
                }),
          ],
        );
      },
    );
  }

  static void showUpdateDialog(String version, String changelog) {
    if (navigatorKey.currentContext == null) return;
    final navigator = Navigator.of(navigatorKey.currentContext!);
    showDialog(
      context: navigator.overlay!.context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('新版本已发布: $version'),
          content: Text(changelog),
          actions: <Widget>[
            TextButton(
              child: const Text('下载地址'),
              onPressed: () {
                launchUrl(Uri.parse(
                    'https://github.com/Uyanide/Tieba_Image_Fetch/releases'));
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('我晓得了'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  static void generalError(dynamic error, StackTrace stackTrace) {
    logError(error, stackTrace);
    showErrorDialog('Error', 'An error occurred.', onPressed: () {});
  }

  static void logError(dynamic error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('Error Message From ErrorHandler:');
      debugPrint('Error: $error');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  static void logCommon(String info) {
    debugPrint(info);
  }

  static void showSnackBar(String message) {
    if (navigatorKey.currentContext == null) return;
    final navigator = Navigator.of(navigatorKey.currentContext!);
    final context = navigator.overlay!.context;
    showSnackBarWithContext(context, message);
  }

  static void showSnackBarWithContext(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        showCloseIcon: true,
      ),
    );
  }

  /// Redirect to the home page, not literally restart the app
  static void toHomePage() {
    if (navigatorKey.currentContext == null) return;
    navigatorKey.currentState!.pushNamedAndRemoveUntil('/', (route) => false);
  }
}
