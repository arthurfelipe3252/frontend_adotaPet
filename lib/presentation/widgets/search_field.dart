import 'package:flutter/material.dart';

/// Campo de busca com a mesma linguagem visual do `TextFieldThemed`
/// (preenchido, raio 20, herdado do `inputDecorationTheme`), porém compacto
/// e com ícone de lupa. Substitui os campos de busca reinventados nas telas.
class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    this.hint = 'Buscar...',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        isDense: true,
      ),
    );
  }
}
