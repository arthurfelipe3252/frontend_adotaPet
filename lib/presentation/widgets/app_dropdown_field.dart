import 'package:flutter/material.dart';

/// Item de um [AppDropdownField]: par (valor tipado, rótulo exibido).
class AppDropdownItem<T> {
  final T value;
  final String label;
  const AppDropdownItem(this.value, this.label);
}

/// Select com o mesmo visual do `TextFieldThemed` (label acima + campo
/// preenchido raio-20 herdado do tema). Substitui os `_Select` privados que
/// cada formulário reimplementava.
class AppDropdownField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final IconData? prefixIcon;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.hint,
    this.onChanged,
    this.errorText,
    this.prefixIcon,
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
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          ),
          items: items
              .map(
                (it) => DropdownMenuItem<T>(
                  value: it.value,
                  child: Text(it.label),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
