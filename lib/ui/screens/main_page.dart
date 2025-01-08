import 'package:flutter/material.dart';
import 'package:tieba_image_parser/ui/main_appbar.dart';
import 'package:tieba_image_parser/ui/main_drawer.dart';
import 'package:tieba_image_parser/ui/screens/parse_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppbar(titleText: '贴吧原图解析'),
      drawer: MainDrawer(),
      body: ParsePage(),
    );
  }
}
