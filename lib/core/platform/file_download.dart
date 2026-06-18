// Download de bytes como arquivo, com implementação escolhida por plataforma.
//
// Em web reexporta a versão com `dart:html`; nas demais plataformas, um stub
// (sem `dart:html`) — assim o `flutter build apk`/`ipa`/`macos` compila, já
// que as telas que exportam arquivo são web-only.
export 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';
