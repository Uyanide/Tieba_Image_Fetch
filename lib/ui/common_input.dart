import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:tieba_image_parser/utils/error_handler.dart';

// import 'package:tieba_image_parser/ui/containers.dart';
// import 'package:tieba_image_parser/utils/error_handler.dart';

class HeightConfiguration {
  static const double small = 30;
  static const double medium = 40;
  static const double large = 50;
}

// class NumberInputField extends StatefulWidget {
//   final String labelText;
//   final Function(double) onConfirmed;
//   final double min;
//   final double max;
//   final double value;
//   final bool disabled;

//   const NumberInputField({
//     super.key,
//     required this.labelText,
//     required this.onConfirmed,
//     required this.value,
//     this.min = 0,
//     this.max = double.infinity,
//     this.disabled = false,
//   });

//   @override
//   State<NumberInputField> createState() => _NumberInputFieldState();
// }

// class _NumberInputFieldState extends State<NumberInputField> {
//   // to reduce onConfirmed calls and recover from invalid input
//   late double lastValue;
//   late TextEditingController controller;

//   String _formatValue(double value) {
//     return value
//         .toStringAsFixed(2)
//         .replaceAll(RegExp(r'0*$'), '')
//         .replaceAll(RegExp(r'\.$'), '');
//   }

//   @override
//   void initState() {
//     super.initState();
//     lastValue = widget.value;
//     controller = TextEditingController(
//       text: _formatValue(widget.value),
//     );
//   }

//   @override
//   void didUpdateWidget(NumberInputField oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.value != oldWidget.value) {
//       lastValue = widget.value;
//       controller.text = _formatValue(widget.value);
//     }
//   }

//   // should be called manually, only for special cases
//   void showValue(double value) {
//     controller.text = _formatValue(value);
//   }

//   void onSubmitted(String value) {
//     double v;
//     try {
//       v = double.parse(value);
//     } catch (e) {
//       ErrorHandler.showErrorDialog(
//         'Invalid Input',
//         'Please enter a valid number',
//       );
//       showValue(lastValue);
//       return;
//     }
//     if (v < widget.min) {
//       v = widget.min;
//       showValue(v);
//     } else if (v > widget.max) {
//       v = widget.max;
//       showValue(v);
//     }
//     if (v == lastValue) {
//       return;
//     }
//     lastValue = v;
//     widget.onConfirmed(v);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             keyboardType: TextInputType.number,
//             decoration: InputDecoration(
//               labelText: widget.labelText,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             style: Theme.of(context).textTheme.labelMedium,
//             onSubmitted: onSubmitted,
//             enabled: !widget.disabled,
//           ),
//         ),
//         if (!widget.disabled) ...[
//           const SizedBox(width: 10),
//           AspectRatio(
//             aspectRatio: 1,
//             child: IconButton(
//               padding: const EdgeInsets.all(0),
//               icon: const Icon(Icons.check),
//               style: ButtonStyle(
//                 shape: WidgetStateProperty.all(
//                   RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 // backgroundColor: Theme.of(context).colorScheme.primary,
//                 backgroundColor: WidgetStateProperty.resolveWith(
//                   (states) {
//                     return Theme.of(context).colorScheme.primary;
//                   },
//                 ),
//                 foregroundColor: WidgetStateProperty.resolveWith(
//                   (states) {
//                     return Theme.of(context).colorScheme.onPrimary;
//                   },
//                 ),
//               ),
//               onPressed: () {
//                 onSubmitted(controller.text);
//               },
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }

class CommonInputField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final bool disabled;
  final bool obscureText;

  const CommonInputField({
    super.key,
    required this.labelText,
    required this.controller,
    this.disabled = false,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        labelText: labelText,
        labelStyle: Theme.of(context).textTheme.labelMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      style: Theme.of(context).textTheme.labelMedium,
      enabled: !disabled,
      obscureText: obscureText,
    );
  }
}

class PasteInputField extends StatelessWidget {
  final String labelText;
  final Function(String) onSubmitted;
  final bool disabled;
  final TextEditingController controller;

  const PasteInputField({
    super.key,
    required this.labelText,
    required this.onSubmitted,
    this.disabled = false,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              labelText: labelText,
              isDense: false,
              labelStyle: Theme.of(context).textTheme.labelMedium,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: Theme.of(context).textTheme.labelMedium,
            onSubmitted: onSubmitted,
            enabled: !disabled,
          ),
        ),
        if (!disabled) ...[
          const SizedBox(width: 10),
          Padding(
            // padding: const EdgeInsets.only(top: 6, bottom: 6),
            padding: const EdgeInsets.all(0),
            child: AspectRatio(
              aspectRatio: 1,
              child: IconButton(
                padding: const EdgeInsets.all(0),
                icon: const Icon(
                  Icons.paste,
                ),
                style: ButtonStyle(
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) {
                      return Theme.of(context).colorScheme.primary;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) {
                      return Theme.of(context).colorScheme.onPrimary;
                    },
                  ),
                ),
                onPressed: disabled
                    ? null
                    : () {
                        Clipboard.getData(Clipboard.kTextPlain).then(
                          (clipboardContent) {
                            if (clipboardContent != null) {
                              controller.text = clipboardContent.text ?? '';
                            }
                          },
                        );
                      },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// class NumberSlider extends StatefulWidget {
//   final String labelText;
//   final Function(double) onChanged;
//   final double min;
//   final double max;
//   final double step;
//   final double value;
//   final bool followInputField;
//   final double? secondaryTrackValue;

//   const NumberSlider({
//     super.key,
//     required this.labelText,
//     required this.onChanged,
//     required this.min,
//     required this.max,
//     required this.value,
//     this.step = 0.02,
//     this.followInputField = false,
//     this.secondaryTrackValue,
//   });

//   @override
//   State<NumberSlider> createState() => _NumberSliderState();
// }

// class _NumberSliderState extends State<NumberSlider> {
//   double lastValue = -1; // to reduce onChanged calls

//   double convertValue(String value) {
//     double v = double.parse(value);
//     return adjustValue(v);
//   }

//   // adjust value to step manually instead of using divisions in Slider,
//   // because divisions will somehow cause unacceptable delays :(
//   double adjustValue(double value) {
//     value = (value / widget.step).round() * widget.step;
//     if (value < widget.min) {
//       value = widget.min;
//     } else if (value > widget.max) {
//       value = widget.max;
//     }
//     return value;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         Text(
//           widget.labelText,
//           style: Theme.of(context).textTheme.labelMedium,
//           maxLines: 1,
//         ),
//         SliderTheme(
//           data: SliderTheme.of(context).copyWith(
//             overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
//           ),
//           child: Slider(
//             value: widget.value,
//             min: widget.min,
//             max: widget.max,
//             label: widget.value.toStringAsFixed(2),
//             secondaryTrackValue: widget.secondaryTrackValue,
//             onChanged: (double value) {
//               double v = adjustValue(value);
//               if (v == lastValue) {
//                 return;
//               }
//               lastValue = v;
//               widget.onChanged(adjustValue(v));
//             },
//           ),
//         ),
//         if (widget.followInputField)
//           HeightSmall(
//             child: NumberInputField(
//               labelText: 'or enter value',
//               onConfirmed: (double value) {
//                 if (value == lastValue) {
//                   return;
//                 }
//                 lastValue = value;
//                 widget.onChanged(adjustValue(value));
//               },
//               min: widget.min,
//               max: widget.max,
//               value: widget.value,
//             ),
//           ),
//       ],
//     );
//   }
// }

class CommonButton extends StatelessWidget {
  final String text;
  final Function onPressed;
  final bool disabled;

  const CommonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        disabledBackgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        disabledForegroundColor:
            Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
      ),
      onPressed: disabled
          ? null
          : () {
              FocusScope.of(context).unfocus();
              onPressed();
            },
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
        maxLines: 1,
      ),
    );
  }
}

class CommonCheckbox extends StatelessWidget {
  final String text;
  final bool value;
  final Function(bool?) onChanged;
  final bool disabled;

  const CommonCheckbox({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: disabled ? null : onChanged,
        ),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

// class CommonDropdown<T> extends StatelessWidget {
//   final T value;
//   final List<T> items;
//   final ValueChanged<T?>? onChanged;

//   const CommonDropdown({
//     super.key,
//     required this.value,
//     required this.items,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return DropdownButton<T>(
//       value: value,
//       items: items
//           .map(
//             (item) => DropdownMenuItem<T>(
//               value: item,
//               child: Center(
//                 child: Text(
//                   item.toString(),
//                   style: Theme.of(context).textTheme.labelLarge,
//                 ),
//               ),
//             ),
//           )
//           .toList(),
//       onChanged: onChanged,
//       alignment: Alignment.center,
//       // isExpanded: true,
//     );
//   }
// }

class CommonSegButton extends StatelessWidget {
  final List<String> items;
  final int value;
  final Function(int) onChanged;
  final bool disabled;

  const CommonSegButton({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    // return ToggleButtons(
    //   isSelected: List.generate(items.length, (index) => index == value),
    //   onPressed: disabled ? null : onChanged,
    //   borderRadius: BorderRadius.circular(8),
    //   selectedColor: Theme.of(context).colorScheme.onPrimary,
    //   fillColor: Theme.of(context).colorScheme.primary,
    //   children: items
    //       .map(
    //         (item) => Padding(
    //           padding: EdgeInsets.symmetric(horizontal: 10),
    //           child: Text(
    //             item,
    //             style: Theme.of(context).textTheme.labelMedium?.copyWith(
    //                   color: items.indexOf(item) == value
    //                       ? disabled
    //                           ? Theme.of(context).colorScheme.onPrimary
    //                           : Theme.of(context).colorScheme.onPrimary
    //                       : Theme.of(context).colorScheme.primary,
    //                 ),
    //           ),
    //         ),
    //       )
    //       .toList(),
    // );
    return SegmentedButton<String>(
      segments: [
        for (var item in items)
          ButtonSegment<String>(
            value: item,
            label: Text(
              item,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
      selected: {items[value]},
      onSelectionChanged: disabled
          ? null
          : (Set<String> newSelection) {
              onChanged(items.indexOf(newSelection.first));
            },
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
