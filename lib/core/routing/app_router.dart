import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:adota_pet/presentation/pages/desktop/forgot_password_page.dart';
import 'package:adota_pet/presentation/pages/desktop/home_placeholder_page.dart';
import 'package:adota_pet/presentation/pages/desktop/login_page.dart';
import 'package:adota_pet/presentation/pages/desktop/register_protetor_ong_page.dart';
import 'package:adota_pet/presentation/pages/desktop/splash_page.dart';
import 'package:adota_pet/presentation/pages/desktop/org_pet_list_page.dart';
import 'package:adota_pet/presentation/pages/desktop/pet_form_page.dart';
import 'package:adota_pet/presentation/pages/desktop/adoption_request_page.dart';
import 'package:adota_pet/presentation/pages/desktop/user_settings_page.dart';
import 'package:adota_pet/presentation/pages/desktop/catalog_page.dart';
import 'package:adota_pet/presentation/pages/desktop/pet_detail_page.dart';
import 'package:adota_pet/presentation/pages/desktop/follow_up_management_page.dart';
import 'package:adota_pet/presentation/pages/desktop/follow_up_review_page.dart';
import 'package:adota_pet/presentation/pages/mobile/login_page.dart' as mobile;
import 'package:adota_pet/presentation/pages/mobile/register_adotante_page.dart'
    as mobile;
import 'package:adota_pet/presentation/pages/mobile/follow_up_list_page.dart'
    as mobile;
import 'package:adota_pet/presentation/pages/mobile/follow_up_detail_page.dart'
    as mobile;
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';

GoRouter buildAppRouter(AuthViewModel auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (!auth.bootstrapDone) {
        return loc == '/splash' ? null : '/splash';
      }

      if (loc == '/splash') {
        return auth.isAuthenticated ? '/home' : '/login';
      }

      final isAuthRoute =
          loc == '/login' ||
          loc == '/register-org' ||
          loc == '/register-adotante' ||
          loc == '/forgot-password';

      if (auth.isAuthenticated && isAuthRoute) return '/home';

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
        builder: (_, __) => kIsWeb
            ? const ForgotPasswordPage()
            : const _MobilePlaceholder(message: 'Em breve'),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => kIsWeb
            ? const HomePlaceholderPage()
            : const _MobilePlaceholder(message: 'Home mobile em breve'),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => kIsWeb
            ? const UserSettingsPage()
            : const _MobilePlaceholder(message: 'Configurações mobile em breve'),
      ),
      GoRoute(path: '/org/dashboard', redirect: (_, __) => '/home'),
      GoRoute(path: '/org/profile', redirect: (_, __) => '/settings'),
      GoRoute(path: '/org/pets', redirect: (_, __) => '/pets'),
      GoRoute(
        path: '/org/requests',
        builder: (_, __) => kIsWeb
            ? const AdoptionRequestPage()
            : const _MobilePlaceholder(
                message: 'Solicitações mobile em breve',
              ),
      ),
      GoRoute(
        path: '/org/follow-ups',
        builder: (_, __) => kIsWeb
            ? const FollowUpManagementPage()
            : const mobile.FollowUpListPage(),
      ),
      GoRoute(
        path: '/org/follow-up/:id',
        builder: (_, state) => kIsWeb
            ? FollowUpReviewPage(id: state.pathParameters['id']!)
            : mobile.FollowUpDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/follow-ups',
        builder: (_, __) => const mobile.FollowUpListPage(),
      ),
      GoRoute(
        path: '/follow-up/:id',
        builder: (_, state) => mobile.FollowUpDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/org/events', redirect: (_, __) => '/home'),
      // ── Módulo de Pets (ONG) ──────────────────────────────────────────────
      GoRoute(path: '/pets', builder: (_, __) => const OrgPetListPage()),
      GoRoute(path: '/pets/new', builder: (_, __) => const PetFormPage()),
      GoRoute(
        path: '/pets/:id',
        builder: (_, state) => PetFormPage(petId: state.pathParameters['id']),
      ),
      // ── Catálogo público ──────────────────────────────────────────────────
      GoRoute(path: '/catalog', builder: (_, __) => const CatalogPage()),
      GoRoute(
        path: '/catalog/:id',
        builder: (_, state) => PetDetailPage(petId: state.pathParameters['id']!),
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
              Text(message, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}