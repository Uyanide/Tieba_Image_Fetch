import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tieba_image_parser/providers/settings_state.dart';
import 'package:tieba_image_parser/ui/common_input.dart';
import 'package:tieba_image_parser/ui/containers.dart';
import 'package:tieba_image_parser/utils/error_handler.dart';

class ProxySetting extends StatefulWidget {
  const ProxySetting({super.key});

  @override
  State<ProxySetting> createState() => _ProxySettingState();
}

class _ProxySettingState extends State<ProxySetting> {
  final TextEditingController _proxyHostController = TextEditingController();
  final TextEditingController _proxyPortController = TextEditingController();
  final TextEditingController _proxyUsernameController =
      TextEditingController();
  final TextEditingController _proxyPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = Provider.of<SettingsState>(context, listen: false);
    _proxyHostController.text = state.proxyHost;
    _proxyPortController.text = state.proxyPort.toString();
    _proxyUsernameController.text = state.proxyUsername;
    _proxyPasswordController.text = state.proxyPassword;
  }

  @override
  void dispose() {
    _proxyHostController.dispose();
    _proxyPortController.dispose();
    _proxyUsernameController.dispose();
    _proxyPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<SettingsState>(context, listen: false);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: CommonSegButton(
                items: state.proxyTypes,
                value: state.proxyTypes
                    .indexOf(context.watch<SettingsState>().proxyType),
                onChanged: (index) {
                  state.proxyType = state.proxyTypes[index];
                },
              ),
            ),
            // switch (state.proxyType) {
            //   'http' => _HttpProxySetting(
            //       proxyHostController: _proxyHostController,
            //       proxyPortController: _proxyPortController,
            //     ),
            //   'socks' => _SocksProxySetting(
            //       proxyHostController: _proxyHostController,
            //       proxyPortController: _proxyPortController,
            //       proxyUsernameController: _proxyUsernameController,
            //       proxyPasswordController: _proxyPasswordController,
            //     ),
            //   _ => const SizedBox(),
            // },
            // const SizedBox(height: 16),
            if (state.proxyType != 'none') ...[
              const SizedBox(height: 16),
              _ProxySetting(
                proxyHostController: _proxyHostController,
                proxyPortController: _proxyPortController,
                proxyUsernameController: _proxyUsernameController,
                proxyPasswordController: _proxyPasswordController,
              ),
              const SizedBox(height: 16),
            ],
            CommonButton(
              text: '确认',
              onPressed: () {
                if (!state.checkValidity(
                    proxyType: state.proxyType,
                    proxyHost: _proxyHostController.text,
                    proxyPort: _proxyPortController.text,
                    proxyUsername: _proxyUsernameController.text,
                    proxyPassword: _proxyPasswordController.text)) {
                  ErrorHandler.showErrorDialog('错误', '输入不合法');
                  return;
                }

                state
                    .applyProxySettings(
                  proxyType: state.proxyType,
                  proxyHost: _proxyHostController.text,
                  proxyPort: _proxyPortController.text,
                  proxyUsername: _proxyUsernameController.text,
                  proxyPassword: _proxyPasswordController.text,
                )
                    .catchError(
                  (e) {
                    ErrorHandler.showErrorDialog(
                        '错误', '无法应用代理设置\n${e.toString()}');
                  },
                );

                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProxySetting extends StatelessWidget {
  final TextEditingController proxyHostController;
  final TextEditingController proxyPortController;
  final TextEditingController proxyUsernameController;
  final TextEditingController proxyPasswordController;

  const _ProxySetting({
    required this.proxyHostController,
    required this.proxyPortController,
    required this.proxyUsernameController,
    required this.proxyPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        HeightMedium(
          child: CommonInputField(
            controller: proxyHostController,
            labelText: 'Host(*)',
          ),
        ),
        const SizedBox(height: 16),
        HeightMedium(
          child: CommonInputField(
            controller: proxyPortController,
            labelText: 'Port(*)',
          ),
        ),
        const SizedBox(height: 16),
        HeightMedium(
          child: CommonInputField(
            controller: proxyUsernameController,
            labelText: 'Username',
          ),
        ),
        const SizedBox(height: 16),
        HeightMedium(
          child: CommonInputField(
            controller: proxyPasswordController,
            labelText: 'Password',
            obscureText: true,
          ),
        ),
      ],
    );
  }
}
