import 'package:flutter/material.dart';
import 'package:tieba_image_parser/ui/animated_carousel.dart';
import 'package:tieba_image_parser/ui/containers.dart';
import 'package:tieba_image_parser/ui/media/image_display.dart';
import 'dart:ui' as ui;

class MultiImage extends StatelessWidget {
  final List<ui.Image> images;
  final bool isDarkMode;
  final Function(int)? onPageChanged;

  const MultiImage({
    super.key,
    required this.images,
    required this.isDarkMode,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return NullContainer();
    }
    return AspectRatio(
      aspectRatio: 1.5,
      child: AnimatedCarousel(
        itemBuilder: (context, index) {
          return SingleChildScrollView(
            child: ImageDisplay(
              image: images[index % images.length],
              isDarkMode: isDarkMode,
            ),
          );
        },
        onPageChanged: onPageChanged,
      ),
    );
  }
}
