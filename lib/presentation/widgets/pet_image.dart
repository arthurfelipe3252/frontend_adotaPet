import 'dart:convert';

import 'package:flutter/widgets.dart';

/// Resolve a foto de um pet em um [ImageProvider], lidando com os dois
/// formatos que aparecem em `Pet.fotosUrls`:
///
/// - **data-URI / base64** (`data:image/jpeg;base64,...`, ou base64 puro) —
///   formato gravado pelo painel web → [MemoryImage];
/// - **URL http(s)** (pets de seed / fontes externas) → [NetworkImage].
///
/// Retorna `null` quando não há foto utilizável (string vazia ou base64
/// corrompido), para o chamador exibir um placeholder.
ImageProvider? petImageProvider(String? src) {
  if (src == null || src.isEmpty) return null;
  try {
    if (src.startsWith('http')) return NetworkImage(src);
    final b64 = src.contains(',') ? src.split(',').last : src;
    return MemoryImage(base64Decode(b64));
  } catch (_) {
    return null;
  }
}

/// Resolve a primeira foto utilizável de uma lista. Itera até achar uma
/// válida — assim uma foto corrompida no início não esconde as demais.
ImageProvider? firstPetImageProvider(List<String> fotosUrls) {
  for (final src in fotosUrls) {
    final provider = petImageProvider(src);
    if (provider != null) return provider;
  }
  return null;
}
