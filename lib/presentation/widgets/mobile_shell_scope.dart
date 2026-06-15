import 'package:flutter/widgets.dart';

/// Permite que as abas-filhas do `MobileShell` troquem a aba ativa
/// (ex.: a Home abrir a aba Conversas).
///
/// Acesse via `MobileShellScope.of(context)?.goTo(index)`. O lookup usa
/// `getInheritedWidgetOfExactType` (sem criar dependência), ideal para chamar
/// dentro de callbacks.
class MobileShellScope extends InheritedWidget {
  final int currentIndex;
  final void Function(int index) goTo;

  const MobileShellScope({
    super.key,
    required this.currentIndex,
    required this.goTo,
    required super.child,
  });

  static MobileShellScope? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MobileShellScope>();

  @override
  bool updateShouldNotify(MobileShellScope oldWidget) =>
      oldWidget.currentIndex != currentIndex;
}
