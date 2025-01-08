import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tieba_image_parser/ui/common_input.dart';
import 'package:tieba_image_parser/ui/containers.dart';

class DurationIndicator extends StatelessWidget {
  const DurationIndicator({
    super.key,
    this.processingNotifier,
    required this.processDurationNotifier,
    this.needReprocessNotifier,
    this.onReprocess,
  });

  final ValueListenable<bool>? processingNotifier;
  final ValueListenable<int> processDurationNotifier;
  final ValueListenable<bool>? needReprocessNotifier;
  final Function()? onReprocess;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (processingNotifier != null)
          ValueListenableBuilder(
            valueListenable: processingNotifier!,
            builder: (context, value, child) {
              if (value) {
                return const SizedBox(
                  height: 10,
                  child: Column(
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 5),
                    ],
                  ),
                );
              } else {
                return const SizedBox(height: 10);
              }
            },
          ),
        InputContainer(
          child: Column(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: processDurationNotifier,
                          builder: (context, value, child) {
                            return Text(
                              // S.of(context).mirage_processing_time(value),
                              'Processing time: $value ms',
                              style: Theme.of(context).textTheme.labelLarge,
                            );
                          },
                        ),
                      ),
                      CommonButton(
                        // text: S.of(context).mirage_reprocess,
                        text: 'Reprocess',
                        onPressed: onReprocess!,
                      ),
                    ],
                  ),
                  if (needReprocessNotifier != null)
                    ValueListenableBuilder(
                      valueListenable: needReprocessNotifier!,
                      builder: (context, value, child) {
                        if (value) {
                          return Column(
                            children: [
                              const SizedBox(height: 5),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  // S.of(context).mirage_reprocess_hint,
                                  'Reprocess',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
