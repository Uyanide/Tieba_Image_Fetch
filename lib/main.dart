import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tieba_image_parser/providers/main_app_state.dart';
import 'package:tieba_image_parser/providers/settings_state.dart';
import 'package:tieba_image_parser/ui/screens/main_page.dart';
import 'package:tieba_image_parser/utils/error_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  final TextTheme textTheme = const TextTheme(
    labelLarge: TextStyle(
      overflow: TextOverflow.fade,
    ),
    labelMedium: TextStyle(
      overflow: TextOverflow.fade,
    ),
    labelSmall: TextStyle(
      overflow: TextOverflow.fade,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.focusedChild?.unfocus();
        }
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => MainAppState()),
          ChangeNotifierProvider(create: (context) => SettingsState()),
        ],
        child: Consumer<MainAppState>(builder: (context, appState, child) {
          return MaterialApp(
            title: '贴吧原图解析',
            theme: ThemeData(
              textTheme: textTheme,
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 22, 65, 174),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              textTheme: textTheme,
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 22, 65, 174),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            navigatorKey: navigatorKey,
            home: const MainPage(),
          );
        }),
      ),
    );
  }
}
