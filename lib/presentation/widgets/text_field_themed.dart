import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextFieldThemed extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const TextFieldThemed({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffix,
            counterText: maxLength == null ? '' : null,
          ),
        ),
      ],
    );
  }
}
