import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:tieba_image_parser/providers/main_app_state.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppbar({super.key, required this.titleText});

  final String titleText;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(titleText),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: context.watch<MainAppState>().isDarkMode
              ? IconButton(
                  key: const ValueKey('dark_mode'),
                  icon: const Icon(Icons.dark_mode),
                  onPressed: () {
                    context.read<MainAppState>().toggleTheme();
                  },
                )
              : IconButton(
                  key: const ValueKey('light_mode'),
                  icon: const Icon(Icons.light_mode),
                  onPressed: () {
                    context.read<MainAppState>().toggleTheme();
                  },
                ),
        ),
      ],
    );
  }
}
