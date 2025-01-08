import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AnimatedCarousel extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int initialPage;
  final Function(int)? onPageChanged;

  const AnimatedCarousel({
    super.key,
    required this.itemBuilder,
    this.initialPage = 0,
    this.onPageChanged,
  });

  @override
  State<AnimatedCarousel> createState() => _AnimatedCarouselState();
}

class _AnimatedCarouselState extends State<AnimatedCarousel> {
  late final PageController _controller;
  late int _currentPage;
  bool _pageHasChanged = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(
      viewportFraction: .6,
      initialPage: widget.initialPage,
    );
    widget.onPageChanged?.call(widget.initialPage);
  }

  @override
  Widget build(context) {
    return LayoutBuilder(builder: (context, constraints) {
      var size = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(
        children: [
          PageView.builder(
            onPageChanged: (value) {
              setState(() {
                _pageHasChanged = true;
                _currentPage = value;
              });
              widget.onPageChanged?.call(value);
            },
            controller: _controller,
            scrollBehavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                ui.PointerDeviceKind.touch,
                ui.PointerDeviceKind.mouse,
              },
            ),
            itemBuilder: (context, index) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                var result =
                    _pageHasChanged ? _controller.page! : _currentPage * 1.0;
                var value = result - index;
                value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);

                return Center(
                  child: SizedBox(
                    height: Curves.easeOut.transform(value) * size.height * 1.5,
                    width: Curves.easeOut.transform(value) * size.width * .6,
                    child: child,
                  ),
                );
              },
              child: Center(child: widget.itemBuilder(context, index)),
            ),
          ),
          _AnimatedCarouselActionButton(
            isLeft: true,
            onPressed: () {
              if (_currentPage > 0) {
                _controller.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            size: size,
          ),
          _AnimatedCarouselActionButton(
            isLeft: false,
            onPressed: () {
              _controller.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            size: size,
          ),
        ],
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AnimatedCarouselActionButton extends StatelessWidget {
  final Function() onPressed;
  final Size size;
  final bool isLeft;

  const _AnimatedCarouselActionButton({
    required this.isLeft,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final actionSize = min(max(size.width * .12, 32), 54).toDouble();
    return Positioned(
      left: isLeft ? 16.0 : null,
      right: isLeft ? null : 16.0,
      top: size.height / 2 - 24,
      child: SizedBox(
        height: actionSize,
        width: actionSize,
        child: FloatingActionButton(
          heroTag: UniqueKey().toString(),
          backgroundColor:
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          onPressed: onPressed,
          child: Icon(isLeft ? Icons.arrow_back : Icons.arrow_forward),
        ),
      ),
    );
  }
}
