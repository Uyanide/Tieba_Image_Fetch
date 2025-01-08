import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tieba_image_parser/ui/containers.dart';

class ImageDisplay extends StatelessWidget {
  final ui.Image? image;
  final String? titleText;
  final GestureTapCallback? onTap;
  final bool isDarkMode;

  const ImageDisplay({
    super.key,
    required this.image,
    this.onTap,
    this.titleText,
    required this.isDarkMode,
  });

  void showFocused(BuildContext context, {ui.Image? image, Color? color}) {
    if (image == null) {
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: ImageDialog(
            color: color!,
            image: image,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleText != null) ...{
            Text(
              titleText!,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
          },
          if (image == null)
            NullContainer()
          else
            GestureDetector(
              onTap: onTap ??
                  () => showFocused(
                        context,
                        color: isDarkMode ? Colors.black : Colors.white,
                        image: image,
                      ),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth * image!.height / image!.width,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Container(
                    color: isDarkMode ? Colors.black : Colors.white,
                    child: RawImage(
                      image: image,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class ImageDialog extends StatelessWidget {
  const ImageDialog({
    super.key,
    required this.image,
    required this.color,
  });

  final ui.Image image;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: InteractiveViewer(
            child: Center(
              child: Container(
                color: color,
                child: RawImage(
                  image: image,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
