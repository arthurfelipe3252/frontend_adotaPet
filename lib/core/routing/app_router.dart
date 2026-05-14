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
          loc == '/forgot-password';

      if (auth.isAuthenticated && isAuthRoute) {
        return '/home';
      }

      final isProtectedRoute =
          loc == '/home' ||
          loc == '/settings' ||
          loc == '/org/dashboard' ||
          loc == '/org/profile' ||
          loc == '/org/pets' ||
          loc == '/org/requests' ||
          loc == '/org/events' ||
          loc == '/pets' ||
          loc == '/pets/new' ||
          loc.startsWith('/pets/');

      if (!auth.isAuthenticated && isProtectedRoute) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: '/login',
        builder: (_, _) => kIsWeb
            ? const LoginPage()
            : const _MobilePlaceholder(message: 'Login mobile em breve'),
      ),
      GoRoute(
        path: '/register-org',
        builder: (_, _) => kIsWeb
            ? const RegisterProtetorOngPage()
            : const _MobilePlaceholder(message: 'Cadastro mobile em breve'),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => kIsWeb
            ? const ForgotPasswordPage()
            : const _MobilePlaceholder(message: 'Em breve'),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => kIsWeb
            ? const HomePlaceholderPage()
            : const _MobilePlaceholder(message: 'Home mobile em breve'),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => kIsWeb
            ? const UserSettingsPage()
            : const _MobilePlaceholder(
                message: 'Configurações mobile em breve',
              ),
      ),
      GoRoute(path: '/org/dashboard', redirect: (_, _) => '/home'),
      GoRoute(path: '/org/profile', redirect: (_, _) => '/settings'),
      GoRoute(path: '/org/pets', redirect: (_, _) => '/pets'),
      GoRoute(
        path: '/org/requests',
        builder: (_, _) => kIsWeb
            ? const AdoptionRequestPage()
            : const _MobilePlaceholder(
                message: 'Solicitações mobile em breve',
              ),
      ),
      GoRoute(path: '/org/events', redirect: (_, _) => '/home'),
      // ── Módulo de Pets ────────────────────────────────────────────────────
      GoRoute(path: '/pets', builder: (_, _) => const OrgPetListPage()),
      GoRoute(path: '/pets/new', builder: (_, _) => const PetFormPage()),
      GoRoute(
        path: '/pets/:id',
        builder: (_, state) => PetFormPage(petId: state.pathParameters['id']),
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
