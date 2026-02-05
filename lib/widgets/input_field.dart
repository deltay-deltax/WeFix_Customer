import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class InputField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final Color? borderColor;
  final Color? fillColor;

  const InputField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.borderColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    bool isMultiLine = maxLines > 1;

    // Conditionally set label color: orange for Salary, blue otherwise
    final labelColor = (label == "Salary") ? AppColors.warning : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((label ?? '').isNotEmpty) ...[
            Text(
              label!,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: isMultiLine ? null : 48,
            decoration: BoxDecoration(
              color: fillColor ?? AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor ?? Colors.transparent),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              obscureText: obscureText,
              keyboardType:
                  keyboardType ??
                  (isMultiLine ? TextInputType.multiline : TextInputType.text),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: suffix,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
