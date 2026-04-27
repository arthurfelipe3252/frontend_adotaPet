# Autenticação

Fluxo completo de login, refresh com rotação, logout e bootstrap. Toda a lógica passa por `AuthRepository` e `AuthViewModel`.

## Diagrama de tokens

```
┌──────────────────────────────────┐
│ accessToken (JWT, ~15min TTL)    │ ← em memória (HttpClient.headers)
└──────────────────────────────────┘
              │
              │ usado em:
              │ Authorization: Bearer <accessToken>
              │
              ▼
        Backend protegido

┌──────────────────────────────────┐
│ refreshToken (opaco, longa vida) │ ← em memória + persistido (SharedPreferences)
└──────────────────────────────────┘
              │
              │ usado em:
              │ POST /users/auth/refresh { refreshToken }
              │ → novo par (access + refresh)
              │
              ▼
        Refresh atômico (rotação)
```

**Importante:** o backend rotaciona o refresh token. Cada vez que `/auth/refresh` é chamado, o refresh anterior é revogado e um novo é emitido. Reusar um refresh já usado retorna **401**. O frontend precisa sempre persistir o **mais recente**.

## `AuthRepository` — interface

```dart
// lib/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String senha});
  Future<AuthSession?> tryRestoreSession();
  Future<bool> tryRefresh();
  Future<void> logout();
}
```

Quatro operações cobrem 100% do fluxo:

- **`login`** — primeira autenticação. Retorna `AuthSession`. Lança `Failure` em erro.
- **`tryRestoreSession`** — chamada no bootstrap. Lê refresh do storage; se válido, faz refresh e retorna sessão. Se inválido/inexistente, retorna `null` (silencioso).
- **`tryRefresh`** — chamada pelo interceptor 401 quando o access expira. Renova com o refresh em memória. Retorna `bool`.
- **`logout`** — revoga refresh no backend (best-effort) e limpa local.

## `AuthSession` — entidade

```dart
// lib/domain/entities/auth_session.dart
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Usuario usuario;

  const AuthSession({...});

  factory AuthSession.fromExpiresIn({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    required Usuario usuario,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
      usuario: usuario,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

`expiresAt` é calculado no momento do login (ou refresh) somando `expiresIn` segundos retornados pelo backend ao instante atual.

`isExpired` não é usado pra decidir refresh proativo (deixamos o interceptor 401 lidar reativamente), mas pode ser útil em features futuras.

## Fluxo completo

### 1. Login

```dart
// AuthViewModel.login (presentation)
Future<bool> login(String email, String senha) async {
  isLoading = true;
  error = null;
  fieldErrors = {};
  notifyListeners();

  try {
    final restored = await repository.login(email: email.trim(), senha: senha);

    // Bloqueio adotante (regra do painel web)
    if (restored.usuario.tipoUsuario == Usuario.tipoAdotante) {
      await repository.logout();
      session = null;
      _setError(Failure('Esta área é exclusiva para protetores e ONGs.'));
      return false;
    }

    session = restored;
    isLoading = false;
    notifyListeners();
    return true;
  } on Failure catch (f) {
    _setError(f);
    return false;
  } catch (_) {
    _setError(Failure('Não foi possível concluir o login.'));
    return false;
  }
}
```

```dart
// AuthRepositoryImpl.login (data)
Future<AuthSession> login({required String email, required String senha}) async {
  final model = await remote.login(LoginRequestModel(email: email, senha: senha));
  final session = model.toEntity();
  await _persistSession(session);
  return session;
}

Future<void> _persistSession(AuthSession session) async {
  await cache.save(session);  // memory + storage
  httpClient.setAccessToken(session.accessToken);  // header Bearer
}
```

```dart
// AuthRemoteDatasource.login (data)
Future<AuthResponseModel> login(LoginRequestModel request) async {
  try {
    final response = await client.post('/users/auth/login', data: request.toJson());
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw failureFromDio(e, customByStatus: {
      400: 'Verifique os dados informados.',
      401: 'Email ou senha inválidos.',
    });
  }
}
```

Sequência (caso de sucesso):

1. Page chama `vm.login(email, senha)`.
2. VM seta `isLoading`, chama `repo.login`.
3. Repo chama `remote.login`, recebe `AuthResponseModel`.
4. Modelo vira `AuthSession`.
5. Repo salva no cache + persiste refresh + injeta access no HttpClient.
6. VM verifica `tipoUsuario`. Se "adotante" no painel web → logout + erro.
7. VM seta `session`, `isLoading = false`, retorna `true`.
8. Page faz `context.go('/home')`.

### 2. Bloqueio de adotante

A regra "adotante não pode usar o painel web" vive no **`AuthViewModel`**, não no repository. Razão: o repository é compartilhado entre desktop e mobile. No futuro, o app mobile vai precisar **permitir** adotantes (e bloquear ONGs talvez). Manter a regra no VM mantém o repo neutro.

Hoje o app mobile só tem placeholders, então não há `MobileAuthViewModel`. Quando aparecer:

```dart
// futuro: presentation/viewmodels/mobile/auth_viewmodel.dart
if (restored.usuario.tipoUsuario != Usuario.tipoAdotante) {
  _setError(Failure('O app é exclusivo para adotantes. Acesse o painel web.'));
  return false;
}
```

### 3. Bootstrap (auto-refresh ao abrir)

Toda vez que o app abre, `SplashPage` chama `auth.bootstrap()`:

```dart
// AuthViewModel.bootstrap
Future<void> bootstrap() async {
  if (bootstrapDone) return;
  try {
    session = await repository.tryRestoreSession();
  } catch (_) {
    session = null;
  }
  bootstrapDone = true;
  notifyListeners();
}
```

```dart
// AuthRepositoryImpl.tryRestoreSession
Future<AuthSession?> tryRestoreSession() async {
  final refreshToken = cache.loadRefreshTokenFromDisk();
  if (refreshToken == null) return null;

  try {
    final model = await remote.refresh(refreshToken);
    final session = model.toEntity();
    await _persistSession(session);
    return session;
  } on Failure catch (f) {
    if (f.message == 'SESSION_EXPIRED') {
      await cache.clear();  // refresh expirado: limpa storage
      return null;
    }
    return null;  // erro de rede: mantém storage (próxima abertura tenta de novo)
  }
}
```

Como o `app_router.dart` observa `auth.bootstrapDone`, ele fica em `/splash` enquanto isso roda. Após `notifyListeners`, o `redirect` decide entre `/home` (autenticado) e `/login` (não).

Detalhes do redirect em `ROUTING.md`.

### 4. Refresh em runtime (interceptor 401)

Quando o access token expira durante uso, o backend retorna **401** na próxima request. O `HttpClient` intercepta isso e tenta renovar **automaticamente**:

```dart
// HttpClient
_dio.interceptors.add(
  InterceptorsWrapper(
    onError: (error, handler) async {
      final status = error.response?.statusCode;
      final isRefreshEndpoint = error.requestOptions.path.contains('/auth/refresh');

      if (status == 401 &&
          onUnauthorized != null &&
          !_isRefreshing &&
          !isRefreshEndpoint) {
        _isRefreshing = true;
        try {
          final refreshed = await onUnauthorized!.call();
          if (refreshed) {
            final original = error.requestOptions;
            final newAuth = _dio.options.headers['Authorization'];
            if (newAuth != null) {
              original.headers['Authorization'] = newAuth;
            }
            final response = await _dio.fetch<dynamic>(original);
            handler.resolve(response);
            return;
          }
        } catch (_) {
          // ignora
        } finally {
          _isRefreshing = false;
        }
      }
      handler.next(error);
    },
  ),
);
```

Plug do callback no `main.dart`:

```dart
httpClient.onUnauthorized = authRepository.tryRefresh;
```

Sequência:

1. Request retorna 401.
2. Interceptor checa: não é endpoint de refresh, não está já refreshing, callback existe.
3. Chama `tryRefresh()`. Repo chama `remote.refresh` com refresh token em memória.
4. Se ok: `_persistSession`, header atualizado no HttpClient. Interceptor refaz a request original com o novo token.
5. Se falha: o 401 original é propagado pra o caller.

A flag `_isRefreshing` previne loop infinito (refresh dispara 401, gera outro refresh...).

### 5. Logout

```dart
// AuthRepositoryImpl.logout
Future<void> logout() async {
  final refreshToken = cache.refreshToken;
  if (refreshToken != null) {
    try {
      await remote.logout(refreshToken);
    } catch (_) {
      // best-effort: ignora erro ao revogar no backend
    }
  }
  await cache.clear();
  httpClient.setAccessToken(null);
}
```

Best-effort: o usuário pode estar offline ou o backend pode estar fora. **O logout local sempre acontece**, mesmo se o backend falhar.

```dart
// AuthViewModel.logout
Future<void> logout() async {
  try {
    await repository.logout();
  } catch (_) { /* best-effort */ }
  session = null;
  error = null;
  fieldErrors = {};
  notifyListeners();
}
```

Quando `session = null`, o `refreshListenable: auth` no router dispara o redirect → `/login`.

### 6. logout-all (encerrar todas as sessões)

Endpoint disponível: `POST /users/auth/logout-all` (revoga todos os refresh tokens do usuário). Útil para "Sair de todos os dispositivos".

Não está implementado no frontend ainda. Quando entrar:

```dart
// adicionar à AuthRepository
Future<void> logoutAll();
```

E o impl chama o endpoint, depois faz logout local.

## Storage

### Web

`SharedPreferences` na web usa `localStorage` do browser por baixo dos panos. **Não é seguro** contra XSS. Para um projeto acadêmico/MVP é aceitável.

Para produção real, considerar:

- HttpOnly cookie (precisa de mudança no backend pra setar cookie em vez de retornar no body).
- Refresh token criptografado (`encrypt` package) com chave derivada de algo do usuário.

### Mobile

`SharedPreferences` em Android/iOS persiste em arquivo seguro no app sandbox. Não é tão seguro quanto Keychain (iOS) ou Keystore (Android), mas é suficiente para refresh token. `flutter_secure_storage` seria a escolha "premium" — adiar até a primeira sprint mobile.

### Acesso

```dart
// lib/core/storage/auth_storage.dart
class AuthStorage {
  static const String _refreshKey = 'auth_refresh_token';

  final SharedPreferences _prefs;

  AuthStorage(this._prefs);

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshKey, token);
  }

  String? readRefreshToken() => _prefs.getString(_refreshKey);

  Future<void> clear() async {
    await _prefs.remove(_refreshKey);
  }
}
```

Apenas refresh token é persistido. Access fica só em memória (lifetime curto, pega via refresh quando precisar).

## DTOs envolvidos

```dart
// data/models/login_request_model.dart
class LoginRequestModel {
  final String email;
  final String senha;

  Map<String, dynamic> toJson() => {'email': email, 'senha': senha};
}

// data/models/auth_response_model.dart
class AuthResponseModel {
  final String accessToken;       // JWT
  final String refreshToken;      // opaco
  final int expiresIn;            // segundos
  final UsuarioModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) { ... }
  AuthSession toEntity() { ... }
}
```

Detalhes do contrato HTTP em `BACKEND_INTEGRATION.md`.

## Casos de borda testáveis

| Cenário | Comportamento esperado |
|---|---|
| Login OK | redirect `/home`, refresh persistido |
| Login email errado | banner "Email ou senha inválidos." |
| Login adotante (no painel web) | banner "Esta área é exclusiva...", storage limpo |
| F5 com refresh válido | splash → refresh → `/home` |
| F5 com refresh expirado/revogado | splash → 401 → storage limpo → `/login` |
| F5 com backend offline | splash → erro de rede → `/login`, storage **mantido** |
| Access expira durante uso | interceptor 401 → refresh → request original refeita transparentemente |
| Refresh expira durante uso | interceptor 401 → refresh falha → próximo erro propagado, sessão local limpa |
| `logout-all` em outra aba | próximo refresh em runtime falha → session limpa → `/login` |
| Logout com backend offline | ainda assim limpa local → `/login` |

## Verificação manual em DevTools

1. Após login: `localStorage` tem `auth_refresh_token`.
2. Network: `Authorization: Bearer ...` em requests autenticadas.
3. Network: `POST /users/auth/refresh` ao F5 em `/home`.
4. Após logout: `localStorage` limpo, requests sem Bearer.
