import 'package:flutter/material.dart';

class HeightSizedBox extends StatelessWidget {
  final double height;
  final Widget child;

  const HeightSizedBox({
    super.key,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: child,
    );
  }
}

class HeightSmall extends HeightSizedBox {
  const HeightSmall({super.key, required super.child}) : super(height: 30);
}

class HeightMedium extends HeightSizedBox {
  const HeightMedium({super.key, required super.child}) : super(height: 40);
}

class HeightLarge extends HeightSizedBox {
  const HeightLarge({super.key, required super.child}) : super(height: 60);
}

class ContentExpansion extends StatefulWidget {
  const ContentExpansion({
    required this.firstChild,
    this.secondChild,
    this.titleText = "",
    this.isInitialExpanded = true,
    super.key,
  });

  final Widget firstChild;
  final Widget? secondChild;
  final String titleText;
  final bool isInitialExpanded;

  @override
  State<ContentExpansion> createState() => _ContentExpansionState();
}

class _ContentExpansionState extends State<ContentExpansion> {
  bool _isExpanded = true;
  static const double _maxWidth = 1000;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _isExpanded = isExpanded;
                });
              },
              dividerColor: Colors.transparent,
              children: [
                buildReactiveExpansionPanel(
                  context: context,
                  firstChild: widget.firstChild,
                  secondChild: widget.secondChild,
                  titleText: widget.titleText,
                  isExpanded: _isExpanded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContentExpansionPassiv extends StatelessWidget {
  const ContentExpansionPassiv({
    super.key,
    required this.firstChild,
    this.secondChild,
    required this.titleText,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  final Widget firstChild;
  final Widget? secondChild;
  final String titleText;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;

  static const double _maxWidth = 1000;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExpansionPanelList(
              elevation: 1,
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                onExpansionChanged(isExpanded);
              },
              dividerColor: Colors.transparent,
              children: [
                buildReactiveExpansionPanel(
                  context: context,
                  firstChild: firstChild,
                  secondChild: secondChild,
                  titleText: titleText,
                  isExpanded: isExpanded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ExpansionPanel buildReactiveExpansionPanel({
  required BuildContext context,
  required Widget firstChild,
  Widget? secondChild,
  required String titleText,
  required bool isExpanded,
}) {
  const double threshold = 600;

  return ExpansionPanel(
    headerBuilder: (BuildContext context, bool isExpanded) {
      return ListTile(
        tileColor: Theme.of(context).colorScheme.surfaceContainer,
        title: Text(
          titleText,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
    },
    isExpanded: isExpanded,
    canTapOnHeader: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    body: Container(
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth < threshold) {
            return Column(children: [
              firstChild,
              if (secondChild != null) ...[
                secondChild,
              ]
            ]);
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (secondChild != null) ...[
                  Expanded(
                    child: firstChild,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: secondChild,
                  ),
                ] else ...[
                  SizedBox(
                    width: constraints.maxWidth / 1.6,
                    child: firstChild,
                  ),
                ],
              ],
            );
          }
        },
      ),
    ),
  );
}

class InputContainer extends StatelessWidget {
  final String? labelText;
  final Widget child;

  const InputContainer({
    super.key,
    this.labelText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 5),
        ],
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 2,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class NullContainer extends StatelessWidget {
  const NullContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return InputContainer(
      child: AspectRatio(
        aspectRatio: 3,
        child: Center(
          child: Text(
            '啥也没有 ψ(._. )>',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}
