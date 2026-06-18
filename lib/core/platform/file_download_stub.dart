import 'dart:typed_data';

/// Stub para plataformas nativas (Android/iOS/macOS). O download de arquivos
/// só é suportado na web; aqui a função nunca é chamada (as telas que exportam
/// são web-only via `kIsWeb`). Existe apenas para o build nativo não importar
/// `dart:html`.
void downloadBytes(
  Uint8List bytes, {
  required String filename,
  required String mimeType,
}) {
  throw UnsupportedError(
    'Download de arquivo não é suportado nesta plataforma (apenas web).',
  );
}
