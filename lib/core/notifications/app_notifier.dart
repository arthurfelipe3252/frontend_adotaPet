import 'package:flutter/foundation.dart';

enum NotificationKind { success, error, info }

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String message;

  AppNotification(this.kind, this.message)
    : id = DateTime.now().microsecondsSinceEpoch.toString();
}

/// Notificações globais que aparecem no canto superior direito.
///
/// Singleton acessível de qualquer lugar via `AppNotifier.instance`.
/// O widget `AppNotificationsHost` (montado no `main.dart`) escuta esse
/// notifier e renderiza os toasts animados.
///
/// Uso:
/// ```dart
/// AppNotifier.instance.success('Cadastro realizado!');
/// AppNotifier.instance.error('Algo deu errado');
/// AppNotifier.instance.info('Atualizando...');
/// ```
class AppNotifier extends ChangeNotifier {
  AppNotifier._();
  static final AppNotifier instance = AppNotifier._();

  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);

  void success(String message) => _add(NotificationKind.success, message);
  void error(String message) => _add(NotificationKind.error, message);
  void info(String message) => _add(NotificationKind.info, message);

  void _add(NotificationKind kind, String message) {
    _items.add(AppNotification(kind, message));
    notifyListeners();
  }

  void dismiss(String id) {
    final i = _items.indexWhere((x) => x.id == id);
    if (i != -1) {
      _items.removeAt(i);
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
