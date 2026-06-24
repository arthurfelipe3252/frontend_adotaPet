import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/http_client.dart';
import 'core/routing/app_router.dart';
import 'core/storage/auth_storage.dart';
import 'core/theme/app_theme.dart';

import 'data/datasources/adoption_request_remote_datasource.dart';
import 'data/datasources/auth_cache_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/cep_remote_datasource.dart';
import 'data/datasources/pet_cache_datasource.dart';
import 'data/datasources/pet_remote_datasource.dart';
import 'data/datasources/users_remote_datasource.dart';
import 'data/datasources/reports_remote_datasource.dart';
import 'data/datasources/chat_remote_datasource.dart';
import 'data/datasources/match_remote_datasource.dart';
import 'presentation/viewmodels/chat_viewmodel.dart';
import 'presentation/viewmodels/match_viewmodel.dart';
import 'presentation/viewmodels/adoption_request_viewmodel.dart';

import 'data/repositories/adoption_request_repository_impl.dart';
import 'data/repositories/reports_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/cep_repository_impl.dart';
import 'data/repositories/pet_repository_impl.dart';
import 'data/repositories/users_repository_impl.dart';

import 'presentation/viewmodels/reports_viewmodel.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/dashboard_viewmodel.dart';
import 'presentation/viewmodels/forgot_password_viewmodel.dart';
import 'presentation/viewmodels/reset_password_viewmodel.dart';
import 'presentation/viewmodels/pet_viewmodel.dart';
import 'presentation/viewmodels/register_adotante_viewmodel.dart';
import 'presentation/viewmodels/register_protetor_ong_viewmodel.dart';
import 'presentation/viewmodels/catalog_viewmodel.dart';
import 'presentation/viewmodels/user_settings_viewmodel.dart';
import 'presentation/widgets/app_notifications_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final authStorage = AuthStorage(prefs);
  final httpClient = HttpClient();

  final authCache = AuthCacheDatasource(authStorage);
  final authRemote = AuthRemoteDatasource(httpClient);
  final usersRemote = UsersRemoteDatasource(httpClient);
  final cepRemote = CepRemoteDatasource();

  final authRepository = AuthRepositoryImpl(
    remote: authRemote,
    cache: authCache,
    httpClient: httpClient,
  );

  final usersRepository = UsersRepositoryImpl(usersRemote);
  final cepRepository = CepRepositoryImpl(cepRemote);

  httpClient.onUnauthorized = authRepository.tryRefresh;

  final authViewModel = AuthViewModel(authRepository);

  final petRemote = PetRemoteDatasource(httpClient);
  final petCache = PetCacheDatasource();
  final petRepository = PetRepositoryImpl(petRemote, petCache);
  final petViewModel = PetViewModel(petRepository, usersRepository);

  final adoptionRequestRemote = AdoptionRequestRemoteDatasource(httpClient);
  final adoptionRequestRepository =
      AdoptionRequestRepositoryImpl(adoptionRequestRemote);
  final adoptionRequestViewModel =
      AdoptionRequestViewmodel(adoptionRequestRepository);

  final reportsRemote = ReportsRemoteDatasource(httpClient);
  final reportsRepository = ReportsRepositoryImpl(reportsRemote);

  final chatRemote = ChatRemoteDatasource(httpClient);
  final chatViewModel = ChatViewModel(chatRemote);

  final matchRemote = MatchRemoteDatasource(httpClient);
  final matchViewModel = MatchViewModel(matchRemote);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),

        ChangeNotifierProvider(
          create: (_) => RegisterProtetorOngViewModel(
            usersRepository: usersRepository,
            cepRepository: cepRepository,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => RegisterAdotanteViewModel(
            usersRepository: usersRepository,
            cepRepository: cepRepository,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => ForgotPasswordViewModel(authRemote),
        ),

        ChangeNotifierProvider(
          create: (_) => ResetPasswordViewModel(authRemote),
        ),

        ChangeNotifierProvider<PetViewModel>.value(value: petViewModel),

        ChangeNotifierProvider<AdoptionRequestViewmodel>.value(
          value: adoptionRequestViewModel,
        ),

        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(reportsRepository),
        ),

        ChangeNotifierProvider(
          create: (_) => ReportsViewModel(reportsRepository),
        ),

        ChangeNotifierProvider(
          create: (_) => CatalogViewModel(petRepository),
        ),

        ChangeNotifierProvider<ChatViewModel>.value(value: chatViewModel),

        ChangeNotifierProvider<MatchViewModel>.value(value: matchViewModel),

        ChangeNotifierProvider(
          create: (_) => UserSettingsViewModel(
            usersRepository: usersRepository,
            cepRepository: cepRepository,
          ),
        ),
      ],
      child: AdotaPetApp(authViewModel: authViewModel),
    ),
  );
}

class AdotaPetApp extends StatelessWidget {
  final AuthViewModel authViewModel;

  const AdotaPetApp({super.key, required this.authViewModel});

  @override
  Widget build(BuildContext context) {
    final router = buildAppRouter(authViewModel);

    return MaterialApp.router(
      title: 'AdotaPet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Força tema claro em todos os dispositivos enquanto o tema escuro não
      // for implementado. Sem isso, o teclado e a status bar ficam escuros
      // em dispositivos com dark mode ativo — inconsistente com a UI.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        return AppNotificationsHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}