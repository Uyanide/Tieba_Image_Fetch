import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tieba_image_parser/ui/screens/main_page.dart';
import 'package:tieba_image_parser/utils/error_handler.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MainAppState(),
      child: const MainApp(),
    ),
  );
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
    return MaterialApp(
      title: '贴吧原图解析',
      theme: ThemeData(
        textTheme: textTheme,
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 22, 65, 174),
          brightness: Brightness.dark,
        ),
      ),
      navigatorKey: navigatorKey,
      home: const MainPage(),
    );
  }
}

class MainAppState extends ChangeNotifier {
  // Add your state and methods here
}