import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class InputField extends StatelessWidget {
  final String hint;
  final bool obscureText;
  final TextEditingController? controller;
  final Widget? prefix;
  final bool filled;
  final Color? borderColor;
  final Color? fillColor;
  final TextInputType? keyboardType;

  const InputField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.prefix,
    this.filled = true,
    this.borderColor,
    this.fillColor,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        prefixIcon: prefix,
        filled: filled,
        fillColor: fillColor ?? AppColors.inputFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderColor != null
              ? BorderSide(color: borderColor!, width: 1.9)
              : const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 18,
        ),
      ),
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 17),
    );
  }
}
