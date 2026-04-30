import 'dart:async';

import 'package:flutter/material.dart';

import 'package:adota_pet/core/notifications/app_notifier.dart';
import 'package:adota_pet/core/theme/app_theme.dart';

/// Host que renderiza os toasts no canto superior direito.
/// Deve envolver toda a UI (no `builder` do `MaterialApp.router`).
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

class _NotificationToast extends StatefulWidget {
  final AppNotification notification;

  const _NotificationToast({super.key, required this.notification});

  @override
  State<_NotificationToast> createState() => _NotificationToastState();
}

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

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.notification.kind) {
      case NotificationKind.success:
        return AppTheme.sage;
      case NotificationKind.error:
        return AppTheme.destructive;
      case NotificationKind.info:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (widget.notification.kind) {
      case NotificationKind.success:
        return Icons.check_circle_rounded;
      case NotificationKind.error:
        return Icons.error_outline_rounded;
      case NotificationKind.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _dismiss,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380, minWidth: 260),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _bgColor,
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
                        widget.notification.message,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
