import 'package:flutter/material.dart';
import 'package:tieba_image_parser/providers/main_app_state.dart';
import 'package:tieba_image_parser/providers/settings_state.dart';
import 'package:tieba_image_parser/ui/proxy_setting.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: AuthorInfo(),
          ),
          const _SubInfo(),
          _Divider(),
          _ConfigItem(
            title: '检查更新',
            detail: '当前版本: ${context.read<MainAppState>().version}',
            onTap: () {
              context.read<MainAppState>().checkUpdate();
            },
          ),
          // ListTile(
          //   title: Text(
          //     '代理配置',
          //     style: Theme.of(context).textTheme.titleMedium!.copyWith(
          //           color: Theme.of(context).colorScheme.onSecondaryContainer,
          //         ),
          //   ),
          //   onTap: () {
          //     showDialog(
          //       context: context,
          //       builder: (context) => const ProxySetting(),
          //     );
          //   },
          // ),
          _ConfigItem(
            title: '代理配置',
            detail: context.watch<SettingsState>().proxyConfig.toString(),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const ProxySetting(),
              );
            },
          )
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: const Divider(height: 20),
    );
  }
}

class AuthorInfo extends StatelessWidget {
  const AuthorInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(
                'https://avatars.githubusercontent.com/u/125987950?v=4')),
        SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '作者: ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
                Text(
                  'Uyanide',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const _LinkIcon(
                    asset: 'assets/icon_github.png',
                    url: 'https://github.com/Uyanide'),
                const SizedBox(width: 10),
                const _LinkIcon(
                    asset: 'assets/icon_qq.png',
                    url: 'https://qm.qq.com/q/xOLAEaLzUW'),
              ],
            )
          ],
        )
      ],
    );
  }
}

class _LinkIcon extends StatelessWidget {
  final String asset;
  final String url;

  const _LinkIcon({
    required this.asset,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: SizedBox(
        width: 24,
        height: 24,
        child: ClipOval(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
          ),
        ),
      ),
      onTap: () {
        launchUrl(Uri.parse(url));
      },
    );
  }
}

class _SubInfo extends StatelessWidget {
  const _SubInfo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '听说有人不会下载原图？',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            '(做着玩的小玩意😌)',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String title;
  final String? detail;
  final VoidCallback onTap;

  const _ConfigItem({
    required this.title,
    required this.onTap,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
      subtitle: detail != null
          ? Text(
              detail!,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
            )
          : null,
      onTap: onTap,
    );
  }
}
