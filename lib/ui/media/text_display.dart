import 'package:flutter/material.dart';
import 'package:tieba_image_parser/ui/containers.dart';
import 'package:flutter/services.dart';
import 'package:tieba_image_parser/utils/error_handler.dart';

class TextDisplay extends StatefulWidget {
  final String? text;
  final bool isDarkMode;
  final double maxHeight;

  const TextDisplay({
    super.key,
    required this.text,
    required this.isDarkMode,
    this.maxHeight = 500,
  });

  @override
  State<TextDisplay> createState() => _TextDisplayState();
}

class _TextDisplayState extends State<TextDisplay> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text == null || widget.text!.isEmpty) {
      return const NullContainer();
    }
    return Stack(
      children: [
        InputContainer(
          child: SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.maxHeight,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: SelectableText(
                    widget.text ?? 'nothing here :) (yet)',
                    style: Theme.of(context).textTheme.labelMedium!,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          width: 40,
          height: 40,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            mini: true,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.text ?? ''));
              ErrorHandler.showSnackBarWithContext(context, '已复制至剪贴板');
              setState(() {
                _copied = true;
              });
              Future.delayed(const Duration(milliseconds: 1000), () {
                setState(() {
                  _copied = false;
                });
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _copied
                  ? const Icon(Icons.done, key: ValueKey('done'), size: 20)
                  : const Icon(Icons.copy, key: ValueKey('copy'), size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
