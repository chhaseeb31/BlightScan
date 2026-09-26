import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

class GSOtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;

  const GSOtpInput({
    super.key,
    this.length = 4,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<GSOtpInput> createState() => _GSOtpInputState();
}

class _GSOtpInputState extends State<GSOtpInput> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (_) => TextEditingController());
    focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleInput(String value, int index) {
    if (value.isEmpty) {
      if (index > 0 && controllers[index - 1].text.isNotEmpty) {
        focusNodes[index - 1].requestFocus();
        controllers[index - 1].clear();
      }
    } else {
      if (value.length > 1) {
        controllers[index].text = value[value.length - 1];
        return;
      }
      if (index < widget.length - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    }
    _notifyChange();
  }

  void _notifyChange() {
    String otp = controllers.map((c) => c.text).join();
    widget.onChanged(otp);
    if (otp.length == widget.length) {
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => Container(
          margin: EdgeInsets.symmetric(
            horizontal: index < widget.length - 1 ? AppSpacing.sm : 0,
          ),
          child: SizedBox(
            width: 60,
            height: 60,
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              keyboardType: TextInputType.number,
              onChanged: (value) => _handleInput(value, index),
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
