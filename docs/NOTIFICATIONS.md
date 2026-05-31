# Sistema de notificações

Notificações são toasts que aparecem no canto superior direito da tela, animadas, com auto-dismiss. Usadas para sucesso, erro e info — substituem o `SnackBar` do Material.

Implementação em dois arquivos:

- `lib/core/notifications/app_notifier.dart` — singleton que gerencia a fila.
- `lib/presentation/widgets/app_notifications_host.dart` — host visual que renderiza os toasts.

## API pública

`AppNotifier.instance` é singleton. **Não precisa de `BuildContext`**:

```dart
import 'package:adota_pet/core/notifications/app_notifier.dart';

AppNotifier.instance.success('Cadastro realizado!');
AppNotifier.instance.error('Algo deu errado.');
AppNotifier.instance.info('Atualizando dados...');
```

Cada chamada empilha um toast novo. Vários simultâneos ficam um abaixo do outro, com gap de 10px.

Para dispensar manualmente (raro):

```dart
AppNotifier.instance.dismiss(notificationId);
AppNotifier.instance.clear();  // limpa tudo
```

## Funcionamento interno

```dart
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
}
```

Singleton + `ChangeNotifier`. Cada notificação tem ID gerado por timestamp:

```dart
class AppNotification {
  final String id;
  final NotificationKind kind;
  final String message;

  AppNotification(this.kind, this.message)
      : id = DateTime.now().microsecondsSinceEpoch.toString();
}
```

## Host visual

`AppNotificationsHost` é montado pelo `MaterialApp.router(builder:)` no `main.dart`:

```dart
MaterialApp.router(
  // ...
  builder: (context, child) => AppNotificationsHost(
    child: child ?? const SizedBox.shrink(),
  ),
)
```

Isso garante que o host está acima de qualquer rota — toasts aparecem em qualquer tela.

Estrutura interna:

```dart
class AppNotificationsHost extends StatelessWidget {
  final Widget child;

  const AppNotificationsHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: AnimatedBuilder(
              animation: AppNotifier.instance,
              builder: (_, _) {
                final items = AppNotifier.instance.items;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in items)
                      _NotificationToast(
                        key: ValueKey(item.id),
                        notification: item,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

`Stack` põe o host acima do `child` (o app inteiro). `Positioned` ancora top-right. `AnimatedBuilder` reage a `AppNotifier.instance.notifyListeners()`.

Cada toast tem `key: ValueKey(item.id)` — garante que adicionar/remover na lista preserve o state correto dos `AnimationController` dos outros toasts.

## Toast individual

`_NotificationToast` é `StatefulWidget` com `AnimationController` próprio:

```dart
class _NotificationToastState extends State<_NotificationToast>
    with SingleTickerProviderStateMixin {
  static const Duration _enterExit = Duration(milliseconds: 280);
  static const Duration _dwell = Duration(milliseconds: 3200);

  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _enterExit);
    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
    _autoDismiss = Timer(_dwell, _dismiss);
  }

  Future<void> _dismiss() async {
    _autoDismiss?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      AppNotifier.instance.dismiss(widget.notification.id);
    }
  }
  // ...
}
```

Ciclo:

1. **Entrada** (~280ms): `forward()` anima `slide` (offset 1.2 → 0) + `fade` (0 → 1) com curve `easeOutCubic`. Toast desliza da direita pra dentro.
2. **Permanência** (3200ms): timer agendado.
3. **Saída** (~280ms): `reverse()` anima de volta. Timer pode ser cancelado se o usuário tap pra dispensar antes.
4. **Remoção da lista**: após `reverse()` completar, chama `AppNotifier.instance.dismiss(id)`. O widget some da árvore quando o `AnimatedBuilder` rebuilda sem ele.

## Estilo visual

```dart
Container(
  constraints: const BoxConstraints(maxWidth: 380, minWidth: 260),
  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  decoration: BoxDecoration(
    color: _bgColor,                    // por kind
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(_icon, color: Colors.white, size: 22),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            height: 1.3,
          ),
        ),
      ),
    ],
  ),
)
```

Wrapper externo é `Material` + `InkWell` para captar tap (dispensa o toast).

### Cores por tipo

| Kind | Background | Ícone |
|---|---|---|
| `success` | `AppTheme.sage` (`#7AAD83`) | `Icons.check_circle_rounded` |
| `error` | `AppTheme.destructive` (`#D93939`) | `Icons.error_outline_rounded` |
| `info` | `AppTheme.primary` (`#D2693A`) | `Icons.info_outline_rounded` |

## Quando usar toast vs banner vs fieldError

| Situação | Onde aparece |
|---|---|
| Sucesso de ação (cadastro feito, link enviado, etc.) | **Toast** (`success`) |
| Erro inesperado / rede | **Banner** (`vm.error`) acima do form |
| Erro específico de campo | **Field error** (`vm.fieldErrors[campo]`) |
| Notificação de info (atualização rodando, dado novo) | **Toast** (`info`) |
| Erro persistente que pede correção | **Banner** ou field, **não toast** (toast some) |

Toasts são bons quando a mensagem é informativa e descartável. Quando o usuário precisa **agir** sobre a mensagem (corrigir um campo, refazer login), use banner ou field error — eles ficam visíveis enquanto a condição persiste.

## Empilhamento e gerenciamento de múltiplos toasts

Se o usuário disparar 3 ações em sucessão, 3 toasts aparecem empilhados. Cada um vive seu ciclo independente. A ordem é cronológica (mais recente embaixo).

Não há dedup — chamar `success('msg')` 3x em sequência mostra 3 toasts iguais. Isso é intencional pra refletir 3 ações; se quiser dedup, é responsabilidade do chamador.

## Acessibilidade

- O texto é `FontWeight.w600` em branco sobre cor saturada — contraste alto.
- Toasts são clicáveis (tap dispensa) — facilita interação por teclado/screen reader.
- Auto-dismiss (3.2s) é tempo suficiente pra ler ~6 palavras. Mensagens longas devem ser parceladas ou viradas em banners persistentes.

## Limitações

- **Sem ações inline** (como `SnackBar.action`). Se precisar de "Desfazer", entra como feature nova.
- **Sem persistência** entre reload de app (são in-memory).
- **Sem agrupamento** ("3 novas mensagens recebidas").

Quando algum desses requisitos surgir, o `AppNotifier` evolui — só evite over-engineering preventivo.
