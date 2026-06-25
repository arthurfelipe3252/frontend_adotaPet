// ignore_for_file: unnecessary_underscores

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:adota_pet/presentation/pages/desktop/forgot_password_page.dart';
import 'package:adota_pet/presentation/pages/desktop/reset_password_page.dart';
import 'package:adota_pet/presentation/pages/desktop/reports_page.dart';
import 'package:adota_pet/presentation/pages/desktop/dashboard_page.dart';
import 'package:adota_pet/presentation/pages/desktop/login_page.dart';
import 'package:adota_pet/presentation/pages/desktop/register_protetor_ong_page.dart';
import 'package:adota_pet/presentation/pages/desktop/splash_page.dart';
import 'package:adota_pet/presentation/pages/desktop/org_pet_list_page.dart';
import 'package:adota_pet/presentation/pages/desktop/pet_form_page.dart';
import 'package:adota_pet/presentation/pages/desktop/adoption_request_page.dart';
import 'package:adota_pet/presentation/pages/desktop/chat_page.dart' as desktop;
import 'package:adota_pet/presentation/pages/mobile/chat_page.dart' as mobile;
import 'package:adota_pet/presentation/pages/desktop/user_settings_page.dart';
import 'package:adota_pet/presentation/pages/mobile/catalog_page.dart';
import 'package:adota_pet/presentation/pages/mobile/pet_detail_page.dart';
import 'package:adota_pet/presentation/pages/mobile/login_page.dart' as mobile;
import 'package:adota_pet/presentation/pages/mobile/register_adotante_page.dart'
    as mobile;
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/mobile_shell.dart';
import 'package:adota_pet/presentation/widgets/org_shell.dart';

GoRouter buildAppRouter(AuthViewModel auth) {
  // Rota que o usuário tentou abrir antes de a sessão terminar de restaurar
  // (ex.: F5 no web em /pets, /chat, /reports). Guardada para voltar a ela
  // depois do bootstrap, em vez de cair sempre no painel.
  String? pendingDeepLink;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (!auth.bootstrapDone) {
        // Captura a rota pretendida (o próprio /splash não conta).
        if (loc != '/splash') pendingDeepLink = loc;
        return loc == '/splash' ? null : '/splash';
      }

      if (loc == '/splash') {
        final target = pendingDeepLink;
        pendingDeepLink = null;
        if (!auth.isAuthenticated) return '/login';
        // Volta para onde o usuário estava antes do reload (se for rota real).
        return (target != null && target != '/splash') ? target : '/home';
      }

      final isAuthRoute =
          loc == '/login' ||
          loc == '/register-org' ||
          loc == '/register-adotante' ||
          loc == '/forgot-password' ||
          loc == '/reset-password';

      // /reset-password é a única auth route que precisa funcionar mesmo
      // com sessão ativa (ex: usuário pediu o link estando logado em outro
      // dispositivo/aba). As demais (login, registro) não fazem sentido
      // para quem já está autenticado, por isso continuam redirecionando.
      if (auth.isAuthenticated && isAuthRoute && loc != '/reset-password') {
        return '/home';
      }

      // Todas as demais rotas exigem login.
      if (!auth.isAuthenticated && !isAuthRoute) return '/login';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(
        path: '/login',
        builder: (_, __) =>
            kIsWeb ? const LoginPage() : const mobile.LoginPage(),
      ),
      GoRoute(
        path: '/register-org',
        builder: (_, __) => kIsWeb
            ? const RegisterProtetorOngPage()
            : const _MobilePlaceholder(
                message:
                    'O cadastro de ONG/Protetor está disponível apenas na versão web.',
              ),
      ),
      GoRoute(
        path: '/register-adotante',
        builder: (_, __) => kIsWeb
            ? const _MobilePlaceholder(
                message:
                    'O cadastro de adotante está disponível apenas no app mobile.',
              )
            : const mobile.RegisterAdotantePage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) =>
            ResetPasswordPage(token: state.uri.queryParameters['token']),
      ),
      // ── Painel ONG (web): todas as telas dentro do shell com sidebar ──────
      // No mobile, estas rotas exibem placeholders (sem o shell de painel).
      ShellRoute(
        builder: (context, state, child) =>
            kIsWeb ? OrgShell(child: child) : child,
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) =>
                kIsWeb ? const DashboardPage() : const MobileShell(),
          ),
          GoRoute(
            path: '/pets',
            builder: (_, __) => kIsWeb
                ? const OrgPetListPage()
                : const _MobilePlaceholder(
                    message: 'Disponível na versão web.',
                  ),
          ),
          GoRoute(
            path: '/pets/new',
            builder: (_, __) => kIsWeb
                ? const PetFormPage()
                : const _MobilePlaceholder(
                    message: 'Disponível na versão web.',
                  ),
          ),
          GoRoute(
            path: '/pets/:id',
            builder: (_, state) => kIsWeb
                ? PetFormPage(petId: state.pathParameters['id'])
                : const _MobilePlaceholder(
                    message: 'Disponível na versão web.',
                  ),
          ),
          GoRoute(
            path: '/adoptions',
            builder: (_, __) => kIsWeb
                ? const AdoptionRequestPage()
                : const _MobilePlaceholder(
                    message: 'Solicitações mobile em breve',
                  ),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) =>
                kIsWeb ? const desktop.ChatPage() : const mobile.ChatPage(),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (_, state) => kIsWeb
                ? desktop.ChatPage(conversationId: state.pathParameters['id'])
                : mobile.ChatPage(conversationId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => kIsWeb
                ? const UserSettingsPage()
                : const _MobilePlaceholder(
                    message: 'Configurações mobile em breve',
                  ),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => kIsWeb
                ? const ReportsPage()
                : const _MobilePlaceholder(
                    message: 'Relatórios disponíveis na versão web.',
                  ),
          ),
        ],
      ),

      // ── Redirects legados (compatibilidade de nomenclatura) ───────────────
      GoRoute(path: '/org/dashboard', redirect: (_, __) => '/home'),
      GoRoute(path: '/org/profile', redirect: (_, __) => '/settings'),
      GoRoute(path: '/org/pets', redirect: (_, __) => '/pets'),
      GoRoute(path: '/org/events', redirect: (_, __) => '/home'),

      // ── Catálogo público (fluxo do adotante — fora do escopo do painel) ───
      GoRoute(path: '/catalog', builder: (_, __) => const CatalogPage()),
      GoRoute(
        path: '/catalog/:id',
        builder: (_, state) =>
            PetDetailPage(petId: state.pathParameters['id']!),
      ),
    ],
  );
}

class _MobilePlaceholder extends StatelessWidget {
  final String message;
  const _MobilePlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}