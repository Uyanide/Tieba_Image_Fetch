import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tieba_image_parser/providers/main_app_state.dart';
import 'package:tieba_image_parser/providers/parse_state.dart';
import 'package:tieba_image_parser/providers/settings_state.dart';
import 'package:tieba_image_parser/ui/common_input.dart';
import 'package:tieba_image_parser/ui/containers.dart';
import 'package:tieba_image_parser/ui/media/multi_image.dart';
import 'package:tieba_image_parser/ui/media/text_display.dart';
import 'package:tieba_image_parser/utils/error_handler.dart';

class ParsePage extends StatelessWidget {
  const ParsePage({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ParseState(),
      child: Stack(
        children: [
          ListView(
            children: [
              const _InfoExpansion(),
              const _ParseExpansion(),
              const _LogExpansion(),
            ],
          ),
          const _ProcessIndicator(),
        ],
      ),
    );
  }
}

class _ProcessIndicator extends StatelessWidget {
  const _ProcessIndicator();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Provider.of<ParseState>(context).isLoading,
      builder: (context, isLoading, child) {
        return isLoading ? const LinearProgressIndicator() : const SizedBox();
      },
    );
  }
}

class _InfoExpansion extends StatelessWidget {
  const _InfoExpansion();

  @override
  Widget build(BuildContext context) {
    return ContentExpansion(
      isInitialExpanded: false,
      titleText: '说明',
      firstChild: Text(
        'TODO: Add information',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ParseExpansion extends StatelessWidget {
  const _ParseExpansion();

  @override
  Widget build(BuildContext context) {
    return ContentExpansion(
      isInitialExpanded: true,
      titleText: '解析',
      firstChild: const Column(
        children: [
          _InputField(),
          _OutputContainer(),
          _UrlContainer(),
        ],
      ),
    );
  }
}

class _LogExpansion extends StatelessWidget {
  const _LogExpansion();

  @override
  Widget build(BuildContext context) {
    return ContentExpansion(
      isInitialExpanded: false,
      titleText: '日志',
      firstChild: const _LogContainer(),
    );
  }
}

class _InputField extends StatefulWidget {
  const _InputField();

  @override
  State<_InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<_InputField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parseState = Provider.of<ParseState>(context, listen: false);
    return AnimatedBuilder(
      // valueListenable: parseState.isLoading,
      animation: Listenable.merge([parseState.isLoading, parseState.canStop]),
      builder: (context, child) {
        final isLoading = parseState.isLoading.value;
        final canStop = parseState.canStop.value;

        return InputContainer(
          child: Column(
            children: [
              HeightMedium(
                child: PasteInputField(
                  labelText: '帖子链接或id',
                  onSubmitted: (_) => Focus.of(context).unfocus(),
                  disabled: isLoading,
                  controller: _controller,
                ),
              ),
              const SizedBox(height: 10),
              HeightMedium(
                child: SizedBox(
                  width: double.infinity,
                  child: !isLoading
                      ? CommonButton(
                          text: '开始解析',
                          onPressed: () {
                            parseState
                                .parse(_controller.text,
                                    context.read<SettingsState>().proxyConfig)
                                .catchError((error) {
                              ErrorHandler.showErrorDialog(
                                '解析失败',
                                '请检查输入或代理设置是否正确 ($error)',
                              );
                            });
                          },
                          disabled: isLoading,
                        )
                      : CommonButton(
                          text: '停止解析',
                          onPressed: () {
                            parseState.cancel();
                          },
                          disabled: !isLoading || !canStop,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              HeightMedium(
                child: SizedBox(
                  width: double.infinity,
                  child: CommonButton(
                    text: '清空',
                    onPressed: () {
                      parseState.clear();
                      _controller.clear();
                    },
                    disabled: isLoading,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutputContainer extends StatelessWidget {
  const _OutputContainer();

  @override
  Widget build(BuildContext context) {
    final parseState = Provider.of<ParseState>(context, listen: false);
    return ValueListenableBuilder<List<Uint8List>>(
      valueListenable: Provider.of<ParseState>(context).imgBytes,
      builder: (context, images, child) {
        // if (images.isEmpty) {
        //   return const SizedBox();
        // }
        return Column(
          children: [
            Divider(height: 30),
            if (images.isNotEmpty) ...[
              Text(
                '已加载 ${images.length} 张图片',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '(图片预览显示可能不完全，请点击图片查看大图)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
            ],
            MultiImage(
              images: images.map((bytes) => Image.memory(bytes)).toList(),
              isDarkMode:
                  Provider.of<MainAppState>(context, listen: true).isDarkMode,
              onPageChanged: (index) {
                parseState.currIndex = index;
              },
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                HeightMedium(
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: double.infinity,
                          child: CommonButton(
                            text: '保存当前图片',
                            onPressed: () {
                              parseState.saveCurrImage().then(
                                (path) {
                                  ErrorHandler.showSnackBar(
                                    '图片已保存至 $path',
                                  );
                                },
                              ).catchError(
                                (error) {
                                  ErrorHandler.showErrorDialog(
                                    '保存失败',
                                    '请检查图片是否正常加载 ($error)',
                                  );
                                },
                              );
                            },
                            disabled: images.isEmpty,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: double.infinity,
                          child: CommonButton(
                            text: '复制当前链接',
                            onPressed: () {
                              parseState.copyCurrentUrl().then(
                                (_) {
                                  ErrorHandler.showSnackBar(
                                    '链接已复制至剪贴板',
                                  );
                                },
                              );
                            },
                            disabled: images.isEmpty,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                HeightMedium(
                  child: SizedBox(
                    width: double.infinity,
                    child: CommonButton(
                      text: '保存所有图片',
                      onPressed: () {
                        parseState.saveAllImages().then(
                          (path) {
                            ErrorHandler.showSnackBar(
                              '${path.split('\n').length} 张图片已保存',
                            );
                          },
                        ).catchError(
                          (error) {
                            ErrorHandler.showErrorDialog(
                              '保存失败',
                              '请检查图片是否正常加载 ($error)',
                            );
                          },
                        );
                      },
                      disabled: images.isEmpty,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _UrlContainer extends StatelessWidget {
  const _UrlContainer();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Provider.of<ParseState>(context).urls,
      builder: (context, urls, child) {
        // if (urls.isEmpty) {
        //   return const SizedBox();
        // }
        return Column(
          children: [
            Divider(height: 30),
            Text(
              '原图链接',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            TextDisplay(
              text: urls,
              maxHeight: 300,
              isDarkMode:
                  Provider.of<MainAppState>(context, listen: true).isDarkMode,
            ),
          ],
        );
      },
    );
  }
}

class _LogContainer extends StatelessWidget {
  const _LogContainer();
  @override
  Widget build(BuildContext context) {
    final parseState = Provider.of<ParseState>(context, listen: false);
    return ValueListenableBuilder<String>(
      valueListenable: parseState.log,
      builder: (context, log, child) {
        if (log.isEmpty) {
          return const NullContainer();
        }
        return TextDisplay(
          text: log,
          maxHeight: 500,
          isDarkMode:
              Provider.of<MainAppState>(context, listen: true).isDarkMode,
        );
      },
    );
  }
}
