import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adota_pet/core/network/http_client.dart';
import 'package:adota_pet/core/routing/app_router.dart';
import 'package:adota_pet/core/storage/auth_storage.dart';
import 'package:adota_pet/core/theme/app_theme.dart';
import 'package:adota_pet/data/datasources/auth_cache_datasource.dart';
import 'package:adota_pet/data/datasources/auth_remote_datasource.dart';
import 'package:adota_pet/data/datasources/cep_remote_datasource.dart';
import 'package:adota_pet/data/datasources/users_remote_datasource.dart';
import 'package:adota_pet/data/repositories/auth_repository_impl.dart';
import 'package:adota_pet/data/repositories/cep_repository_impl.dart';
import 'package:adota_pet/data/repositories/users_repository_impl.dart';
import 'package:adota_pet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/forgot_password_viewmodel.dart';
import 'package:adota_pet/presentation/viewmodels/register_protetor_ong_viewmodel.dart';
import 'package:adota_pet/presentation/widgets/app_notifications_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===== Composição (DI manual) =====
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

  // Plug do interceptor 401: refresh atrelado ao repository.
  httpClient.onUnauthorized = authRepository.tryRefresh;

  final authViewModel = AuthViewModel(authRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
        ChangeNotifierProvider<RegisterProtetorOngViewModel>(
          create: (_) => RegisterProtetorOngViewModel(
            usersRepository: usersRepository,
            cepRepository: cepRepository,
          ),
        ),
        ChangeNotifierProvider<ForgotPasswordViewModel>(
          create: (_) => ForgotPasswordViewModel(),
        ),
      ],
      child: AdotaPetApp(authViewModel: authViewModel),
    ),
  );
}

class AdotaPetApp extends StatefulWidget {
  final AuthViewModel authViewModel;

  const AdotaPetApp({super.key, required this.authViewModel});

  @override
  State<AdotaPetApp> createState() => _AdotaPetAppState();
}

class _AdotaPetAppState extends State<AdotaPetApp> {
  late final _router = buildAppRouter(widget.authViewModel);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AdotaPet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: (context, child) => AppNotificationsHost(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
