# Padrões de código por camada

Cada padrão abaixo tem **forma**, **regra** e **exemplo do projeto atual**. Copiar e adaptar é o caminho — não reinventar.

## Entity (domain)

**Forma:** classe imutável com `final` + construtor `const`.

**Regra:** sem dependências externas (nem Flutter, nem Dio, nem `dart:convert`). Pode importar outras entities do mesmo `domain/entities/`.

```dart
// lib/domain/entities/usuario.dart
class Usuario {
  static const String tipoAdotante = 'adotante';
  static const String tipoProtetor = 'protetor';
  static const String tipoOng = 'ong';

  final String id;
  final String nome;
  final String email;
  final String tipoUsuario;
  final String? telefone;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.telefone,
  });

  bool get isAdotante => tipoUsuario == tipoAdotante;
  bool get isProtetor => tipoUsuario == tipoProtetor;
  bool get isOng => tipoUsuario == tipoOng;
  bool get isProtetorOuOng => isProtetor || isOng;
}
```

Constantes de classe expõem valores estáveis (em vez de strings mágicas espalhadas). Getters derivados (`isAdotante`) tornam código que consome a entidade mais expressivo.

### `*_params.dart` para entradas multi-campo

Quando uma operação de domínio recebe muitos parâmetros (ex.: cadastro), criamos uma classe `*Params`:

```dart
// lib/domain/entities/criar_protetor_ong_params.dart
class CriarProtetorOngParams {
  final String nome;
  final String email;
  final String senha;
  final String tipoUsuario;
  final String cpfCnpj;
  final Uint8List documentoBytes;
  final String documentoFilename;
  final Endereco endereco;
  final String? telefone;
  // ...

  const CriarProtetorOngParams({
    required this.nome,
    // ...
  });
}
```

Vantagem: a interface do repository fica enxuta (`Future<ProtetorOng> criarProtetorOng(CriarProtetorOngParams params)`) e adicionar/remover campos não quebra a assinatura do método.

`Uint8List` aqui é exceção — é tipo do `dart:typed_data` (stdlib do Dart, não Flutter). Pode no domain.

## Model (data)

**Forma:** classe espelhando o DTO do backend, com `fromJson()`, `toJson()` (quando faz sentido) e `toEntity()`.

**Regra:** carrega responsabilidade de serialização. É onde acontecem `base64Encode`, parsing de strings de data, conversão de tipos.

```dart
// lib/data/models/usuario_model.dart
class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final String tipoUsuario;
  final String? telefone;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.telefone,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      tipoUsuario: json['tipoUsuario'] as String,
      telefone: json['telefone'] is String ? json['telefone'] as String : null,
    );
  }

  Usuario toEntity() {
    return Usuario(
      id: id,
      nome: nome,
      email: email,
      tipoUsuario: tipoUsuario,
      telefone: telefone,
    );
  }
}
```

### Request models codificam binário

Quando há upload (foto, documento), o request model **codifica** os bytes em base64 no `toJson()` — não antes:

```dart
// lib/data/models/criar_protetor_ong_request_model.dart
Map<String, dynamic> toJson() {
  return {
    'nome': nome,
    'email': email,
    'senha': senha,
    'tipoUsuario': tipoUsuario,
    'cpfCnpj': cpfCnpj,
    'documentoComprobatorio': base64Encode(documentoBytes),
    'endereco': endereco.toJson(),
    if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
    if (descricao != null && descricao!.isNotEmpty) 'descricao': descricao,
    if (imagemBytes != null) 'imagemBase64': base64Encode(imagemBytes!),
  };
}
```

ViewModel guarda `Uint8List`. Conversão pra base64 é detalhe de transporte e fica em `data/`.

## Repository interface (domain)

**Forma:** classe `abstract`, métodos `Future<...>`. Documenta o contrato.

**Regra:** **lança `Failure`** quando algo dá errado. Nunca retorna `Either<L, R>` ou wrappers complicados. Mantém a leitura linear.

```dart
// lib/domain/repositories/auth_repository.dart
import 'package:adota_pet/domain/entities/auth_session.dart';

abstract class AuthRepository {
  /// Faz login com email e senha. Retorna a sessão completa.
  /// Lança `Failure` em erro de credenciais ou rede.
  Future<AuthSession> login({
    required String email,
    required String senha,
  });

  /// Tenta restaurar a sessão usando o refresh token salvo no storage.
  /// Retorna `null` se não há refresh token ou se ele já expirou (silencioso).
  Future<AuthSession?> tryRestoreSession();

  /// Renova o par de tokens usando o refresh token em memória.
  /// Retorna `true` se renovou com sucesso, `false` se falhou.
  /// Usado pelo interceptor 401 do HttpClient.
  Future<bool> tryRefresh();

  /// Encerra a sessão local e revoga o refresh token no backend (best-effort).
  Future<void> logout();
}
```

Comentário em cada método explica o **comportamento contratual**: o que retorna, quando lança, qual o efeito colateral.

## Repository impl (data)

**Forma:** classe que `implements` a interface, recebe datasources via construtor, traduz erros.

**Regra:** essa é a fronteira onde "internet ruim" vira "mensagem amigável". Se o datasource lança `DioException`, o repository captura e relança como `Failure`.

```dart
// lib/data/repositories/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remote;
  final AuthCacheDatasource cache;
  final HttpClient httpClient;

  AuthRepositoryImpl({
    required this.remote,
    required this.cache,
    required this.httpClient,
  });

  @override
  Future<AuthSession> login({required String email, required String senha}) async {
    final model = await remote.login(LoginRequestModel(email: email, senha: senha));
    final session = model.toEntity();
    await _persistSession(session);
    return session;
  }

  @override
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
        await cache.clear();
        return null;
      }
      return null; // erro de rede: mantém storage, próxima abertura tenta de novo
    }
  }

  Future<void> _persistSession(AuthSession session) async {
    await cache.save(session);
    httpClient.setAccessToken(session.accessToken);
  }
  // ...
}
```

### Padrão remote + cache fallback

Para leitura, o padrão default é tentar remoto, salvar cache, retornar. Se remoto falha, retorna cache (quando aplicável). O exemplo no `CLAUDE.md`:

```dart
@override
Future<List<Pet>> getPets() async {
  try {
    final models = await remote.getPets();
    cache.save(models);
    return models.map((m) => m.toEntity()).toList();
  } catch (e) {
    final cached = cache.get();
    if (cached != null) {
      return cached.map((m) => m.toEntity()).toList();
    }
    throw Failure('Não foi possível carregar os pets');
  }
}
```

## Remote datasource (data)

**Forma:** classe que recebe `HttpClient` no construtor, métodos `Future<Model>` chamando endpoints.

**Regra:** captura `DioException` e converte em `Failure` via `failureFromDio` com `customByStatus` específico.

```dart
// lib/data/datasources/auth_remote_datasource.dart
class AuthRemoteDatasource {
  final HttpClient client;

  AuthRemoteDatasource(this.client);

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
  // ...
}
```

`customByStatus` é onde traduzimos códigos HTTP em mensagens user-friendly específicas do endpoint. O fallback do helper cuida do resto (rede, 5xx, mensagem do backend).

Detalhes em `ERROR_HANDLING.md`.

## Cache datasource (data)

**Forma:** in-memory simples (Map ou List), opcionalmente persistido.

**Regra:** sem complexidade. Se o cache precisa de TTL, write-through, etc., promove pra serviço separado.

```dart
// lib/data/datasources/auth_cache_datasource.dart
class AuthCacheDatasource {
  final AuthStorage storage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;

  AuthCacheDatasource(this.storage);

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasMemorySession => _accessToken != null && _refreshToken != null;

  Future<void> save(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _expiresAt = session.expiresAt;
    await storage.saveRefreshToken(session.refreshToken);
  }

  String? loadRefreshTokenFromDisk() {
    final token = storage.readRefreshToken();
    if (token == null || token.isEmpty) return null;
    _refreshToken = token;
    return token;
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    await storage.clear();
  }
}
```

## ViewModel (presentation)

**Forma:** `extends ChangeNotifier`. Estado é exposto via campos públicos. Lógica em métodos.

**Regra:** chama `notifyListeners()` após mutar estado. Usa `_setError(Failure)` para padronizar tratamento de erro.

```dart
// lib/presentation/viewmodels/auth_viewmodel.dart
class AuthViewModel extends ChangeNotifier {
  final AuthRepository repository;

  bool isLoading = false;
  String? error;
  Map<String, String> fieldErrors = {};
  AuthSession? session;
  bool bootstrapDone = false;

  AuthViewModel(this.repository);

  bool get isAuthenticated => session != null;

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

  Future<bool> login(String email, String senha) async {
    isLoading = true;
    error = null;
    fieldErrors = {};
    notifyListeners();

    try {
      final restored = await repository.login(email: email.trim(), senha: senha);
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

  void _setError(Failure f) {
    if (f.field != null) {
      fieldErrors = {f.field!: f.message};
      error = null;
    } else {
      fieldErrors = {};
      error = f.message;
    }
    isLoading = false;
    notifyListeners();
  }
  // ...
}
```

Detalhes do estado padrão e helper `_setError` em `STATE_MANAGEMENT.md` e `ERROR_HANDLING.md`.

## Page (presentation)

**Forma:** `StatefulWidget` ou `StatelessWidget`. Lê o ViewModel via `context.watch` (ou `Consumer`). Dispara métodos via `context.read`.

**Regra:** **sem lógica de negócio**. A page só renderiza estado e chama métodos. Validação, transições, regras — tudo no ViewModel.

```dart
// lib/presentation/pages/desktop/login_page.dart (recorte)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.login(_emailCtrl.text, _senhaCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    // ...
    return Scaffold(
      body: ...,
    );
  }
}
```

Diferenças entre `read` e `watch`:

- `context.watch<X>()` — usa-se no `build`, faz rebuild quando o VM notifica.
- `context.read<X>()` — usa-se em handlers (onPressed, onChanged), não dispara rebuild.

`Consumer<X>` faz rebuild só do filho — útil quando o widget tem partes pesadas que não dependem do VM.

### Controllers de TextField vivem no Page (não no VM)

`TextEditingController` é estado de UI puro. Vive no `State` da page. O VM tem `String` simples, populado via `onChanged: vm.setFoo`.

Trocar PF/PJ no cadastro precisa limpar o controller? Sincroniza no build:

```dart
void _syncFromVm(RegisterProtetorOngViewModel vm) {
  if (_lastTipoUsuario != vm.tipoUsuario) {
    _lastTipoUsuario = vm.tipoUsuario;
    _cpfCnpjCtrl.clear();
    _cpfMask.clear();
    _cnpjMask.clear();
  }
}
```

Chamado no início do `build`.

## Widget compartilhado (presentation)

**Forma:** `StatelessWidget` na maioria dos casos, `StatefulWidget` quando há `AnimationController` ou state local.

**Regra:** parametrizável via construtor. Não importa ViewModel diretamente — recebe callbacks/valores.

```dart
// lib/presentation/widgets/primary_button.dart
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final PrimaryButtonVariant variant;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
    this.variant = PrimaryButtonVariant.primary,
    this.onPressed,
  });
  // ...
}
```

Widgets que dependem de identidade visual (cores, fontes) leem de `AppTheme` direto.

## Comentários

Regra geral: **escreva poucos**. Código autoexplicativo > comentário óbvio.

Comente quando:

- A intenção não é óbvia pelo nome (ex.: workaround pra bug específico).
- A regra de negócio tem origem externa (ex.: "limite imposto pelo backend").
- Há trade-off não óbvio na escolha (ex.: "usamos `IndexedStack` em vez de `if/else` porque preserva state").

Não comente:

- O que o código já diz (`// incrementa i`).
- Histórico de mudanças (`// removido em 2026-01`).
- TODOs sem dono ou data.
