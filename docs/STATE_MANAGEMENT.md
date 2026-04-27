# Gerenciamento de estado

## Stack

- **Provider** ^6.1.5 (`MultiProvider`, `ChangeNotifierProvider`).
- **`ChangeNotifier`** como base de cada ViewModel.
- **DI manual** no `main.dart` para wiring.

Não usamos `Riverpod`, `BLoC`, `MobX`, `Redux` ou `GetX`.

## Estado padrão de um ViewModel

Todo ViewModel reativo segue o mesmo conjunto de campos quando aplicável:

```dart
class XxxViewModel extends ChangeNotifier {
  bool isLoading = false;
  String? error;                          // erro de banner geral
  Map<String, String> fieldErrors = {};   // erros por campo do form
  // ... estado específico (entidades, listas, flags) ...
}
```

- **`isLoading`** — operação assíncrona em andamento. UI mostra spinner ou desabilita botões.
- **`error`** — mensagem de erro que vira **banner** (acima do form). `null` quando não há erro.
- **`fieldErrors`** — mapa `campo → mensagem`. Cada `TextFieldThemed` consome `vm.fieldErrors['<campo>']` no `errorText`.

Quando um VM tem múltiplos estados de "sucesso" distintos, criamos campos específicos:

```dart
bool sent = false; // ForgotPasswordViewModel
AuthSession? session; // AuthViewModel
bool bootstrapDone = false; // AuthViewModel
```

## Ciclo de uma operação

```dart
Future<bool> login(String email, String senha) async {
  isLoading = true;
  error = null;
  fieldErrors = {};
  notifyListeners();

  try {
    // ... operação ...
    isLoading = false;
    notifyListeners();
    return true;
  } on Failure catch (f) {
    _setError(f);
    return false;
  } catch (_) {
    _setError(Failure('Não foi possível concluir.'));
    return false;
  }
}
```

Padrão:

1. Sinaliza `isLoading = true`, limpa erros antigos, **notifica**.
2. Chama o repositório.
3. Em sucesso: atualiza estado, `isLoading = false`, **notifica**, retorna `true`.
4. Em `Failure`: passa pra `_setError(f)`, retorna `false`.
5. Em outro erro inesperado: encapsula em `Failure` genérico e passa pra `_setError`.

`return bool` permite à page decidir se navega após sucesso (`if (ok) context.go('/home')`).

## `_setError` — direciona Failure para banner ou field

Helper privado em cada VM que processa o `Failure` direcionando ao lugar certo:

```dart
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
```

- Se `Failure.field != null` (ex.: 409 mapeado para `email`): vai pro `fieldErrors`, sem banner.
- Senão: vira banner geral em `error`.

Ambos os modos sempre limpam o outro (não acumulam).

Detalhes em `ERROR_HANDLING.md`.

## `notifyListeners()` — quando chamar

Sempre que mutar estado **observável** (que afeta UI). Regras:

- **Sempre** após mutar `isLoading`, `error`, `fieldErrors`, ou estado relevante.
- **Não** chamar dentro de getters/setters de UI nada-a-ver (ex.: trocar valor de input que só importa no submit).
- **Cuidado** com chamadas em sequência: cada `notifyListeners` causa rebuild dos consumers. Mute tudo, depois notifique uma vez:

```dart
// bom
isLoading = true;
error = null;
fieldErrors = {};
notifyListeners();

// ruim
isLoading = true;
notifyListeners();
error = null;
notifyListeners();
fieldErrors = {};
notifyListeners();
```

## Setters explícitos vs `setField` genérico

Usamos **setters explícitos** por campo no form (ex.: `setNome`, `setEmail`, `setCep`). Verboso, mas:

- IDE descobre auto-complete.
- Lógica específica por campo é local (ex.: `setTipoUsuario` que limpa `cpfCnpj` junto).
- Nunca precisa lembrar uma string mágica.

```dart
void setNome(String v) => _setField('nome', v, (x) => nome = x);
void setEmail(String v) => _setField('email', v, (x) => email = x.trim());

void setTipoUsuario(String value) {
  if (value != tipoProtetor && value != tipoOng) return;
  if (value == tipoUsuario) return;
  tipoUsuario = value;
  cpfCnpj = '';
  fieldErrors.remove('cpfCnpj');
  notifyListeners();
}

void _setField(String key, String value, void Function(String) apply) {
  apply(value);
  fieldErrors.remove(key);
}
```

Setters de campos que afetam UI reativa imediatamente (`senha` para o indicador de força, `cep` para autocomplete) chamam `notifyListeners()`. Setters de campos cujo valor só importa no submit (nome, email, etc.) não chamam — o `TextField` guarda seu próprio estado via controller.

## Sem `Form` / `GlobalKey<FormState>`

Decisão consciente. Usamos `TextField` puro com `errorText: vm.fieldErrors[key]`.

Razões:

- O VM já é a fonte da verdade do estado de form. `Form` cria uma segunda fonte (estado interno do `FormState`).
- `TextFormField.validator` valida campo a campo, isolado. Não fala com vizinhos. Mas regras como "senha === confirmar" precisam ver dois campos. No VM, `validateStep2()` examina tudo de uma vez.
- Bind via `errorText` é trivial e lê 100% imperativo, sem mágica.

Detalhes em `FORMS.md`.

## Provider — composição

`MultiProvider` no `main.dart` registra todos os ViewModels:

```dart
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
```

- **`.value`** — quando a instância já existe (ex.: `AuthViewModel` precisa ser instanciado **antes** do runApp porque o router depende dele).
- **`create:`** — quando o Provider deve instanciar (lazy).

## `context.watch` vs `context.read` vs `Consumer`

| Forma | Quando usar | Reage a notify? |
|---|---|---|
| `context.watch<X>()` | Dentro de `build()`, quando o widget reage a mudanças | Sim |
| `context.read<X>()` | Em handlers (`onPressed`, `onChanged`) ou `initState` | Não |
| `Consumer<X>(builder: ...)` | Quando só uma parte do widget precisa reagir | Sim (só o filho) |
| `Selector<X, Y>(...)` | Quando reage só a uma fatia específica do estado | Sim (com diff) |

Padrão default: `context.watch` no `build`, `context.read` em handlers. `Consumer` quando há partes pesadas (ex.: lista grande) que não dependem do VM.

### Exemplo

```dart
@override
Widget build(BuildContext context) {
  final vm = context.watch<AuthViewModel>();
  // ... usa vm.error, vm.isLoading ...
}

Future<void> _submit() async {
  final vm = context.read<AuthViewModel>(); // não rebuild aqui
  await vm.login(...);
}
```

## Singletons (não-VM)

Existem hoje:

- **`AppNotifier.instance`** (`lib/core/notifications/app_notifier.dart`) — `ChangeNotifier` singleton para toasts globais. Não precisa de Provider porque só o `AppNotificationsHost` o consome, e o resto da app o usa via `AppNotifier.instance.success(...)` sem precisar de `BuildContext`.

Singletons só são justificados quando:

- O serviço é genuinamente global (não escopado a uma rota).
- A API consumida não tem `BuildContext` à mão (ex.: dentro de um repository).

Quando dúvida, prefira Provider escopado.

## Bootstrap

Para inicializações que **devem rodar antes** de a UI decidir o que mostrar (ex.: tentar restaurar sessão no abrir do app), criamos um método `bootstrap()` no VM, chamado no `initState` da `SplashPage`.

O `app_router.dart` observa `auth.bootstrapDone` para decidir entre `/login` e `/home`. Antes do bootstrap terminar, fica em `/splash`.

Detalhes em `AUTHENTICATION.md` e `ROUTING.md`.

## Lifecycle do ViewModel

ViewModels registrados via `ChangeNotifierProvider(create: ...)` são **descartados** quando o widget pai do Provider sai da árvore. No nosso caso, todos os VMs ficam no nível do `MultiProvider` raiz, então vivem o tempo todo (até a app fechar).

Isso significa: **o estado dos forms persiste** entre navegações. Ir pra `/home` e voltar pra `/register-org` mantém o que estava preenchido. Para resetar, exponha `reset()` no VM e chame na page quando apropriado:

```dart
// ForgotPasswordViewModel
void reset() {
  email = '';
  sent = false;
  isLoading = false;
  fieldErrors = {};
  notifyListeners();
}
```

Hoje só o `ForgotPasswordViewModel` tem `reset()` — o cadastro mantém estado intencionalmente (se o usuário voltou pelo erro, vê o que preencheu).
