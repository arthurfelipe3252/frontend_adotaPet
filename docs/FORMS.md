# Forms

Padrões para formulários no projeto. Cobre validação, máscaras, upload, integração ViaCEP, multi-step.

## Princípio: ViewModel é a fonte da verdade

**Não usamos `Form` / `GlobalKey<FormState>`** do Material. Justificativa:

- O ViewModel já mantém o estado do form (`String nome`, `String email`, etc.) e expõe `fieldErrors` por campo.
- `Form` introduziria uma segunda fonte de verdade (estado interno do `FormState`) que precisaria ser sincronizada.
- `TextFormField.validator` valida campo isoladamente — não fala com vizinhos. Validar `senha` vs `confirmarSenha`, ou `cpf` vs `cnpj` (que dependem de `tipoUsuario`), exige ver vários campos juntos. No VM, `validateStepN()` examina tudo de uma vez.
- A integração `vm.fieldErrors[key]` → `TextField.errorText` é trivial e 100% imperativa, sem mágica.

Resultado: usamos `TextField` puro, com `errorText` populado via `vm.fieldErrors`.

## Estrutura de um form simples

```dart
class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

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
    if (ok) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Column(
      children: [
        TextFieldThemed(
          label: 'E-mail',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          errorText: vm.fieldErrors['email'],
          textInputAction: TextInputAction.next,
        ),
        TextFieldThemed(
          label: 'Senha',
          controller: _senhaCtrl,
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          errorText: vm.fieldErrors['senha'],
        ),
        PrimaryButton(
          label: 'Entrar',
          isLoading: vm.isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
```

`TextEditingController` vive no `State` da page (estado de UI puro). O VM tem `String email` populado via `onChanged`/`onSubmitted` ou diretamente lendo `controller.text` no submit (depende do que faz mais sentido).

## ViewModel — estado e setters

```dart
class FormViewModel extends ChangeNotifier {
  // Campos do form
  String nome = '';
  String email = '';
  // ... outros ...

  // Estado padrão
  bool isLoading = false;
  String? error;
  Map<String, String> fieldErrors = {};

  // Setters explícitos (não setField genérico)
  void setNome(String v) => _setField('nome', v, (x) => nome = x);
  void setEmail(String v) => _setField('email', v, (x) => email = x.trim());

  void _setField(String key, String value, void Function(String) apply) {
    apply(value);
    fieldErrors.remove(key);
  }
}
```

Por que setters explícitos?

- IDE auto-complete.
- Lógica específica por campo (ex.: `setEmail` faz `trim`; `setTipoUsuario` limpa `cpfCnpj`).
- Sem strings mágicas.

Setters de campos que afetam UI **reativamente** (senha → indicador de força, cep → autocomplete) chamam `notifyListeners()`. Setters de campos que só importam no submit (nome, email) não chamam — o `TextField` mantém seu estado via controller.

```dart
void setSenha(String v) {
  senha = v;
  fieldErrors.remove('senha');
  notifyListeners(); // afeta o indicador de força
}

void setNome(String v) => _setField('nome', v, (x) => nome = x); // sem notify
```

## Validação local (cliente)

Antes de chamar o backend, o VM valida o que pode ser validado offline. Popula `fieldErrors`.

```dart
bool validateStep1() {
  final errors = <String, String>{};

  if (nome.trim().length < 2) {
    errors['nome'] = 'Informe o nome completo.';
  }

  if (email.trim().isEmpty || !_emailRegex.hasMatch(email.trim())) {
    errors['email'] = 'Informe um email válido.';
  }

  // CPF ou CNPJ dependendo do tipo
  final digits = cpfCnpj.replaceAll(RegExp(r'\D'), '');
  if (tipoUsuario == tipoProtetor) {
    if (digits.length != 11 || !CPFValidator.isValid(digits)) {
      errors['cpfCnpj'] = 'CPF inválido.';
    }
  } else {
    if (digits.length != 14 || !CNPJValidator.isValid(digits)) {
      errors['cpfCnpj'] = 'CNPJ inválido.';
    }
  }

  fieldErrors = errors;
  error = null;
  notifyListeners();
  return errors.isEmpty;
}
```

A tabela canônica de validações está em `ERROR_HANDLING.md`.

### Email regex

```dart
static final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);
```

Não é RFC-completo, mas captura 99% dos casos reais. Se passar pelo regex e o backend rejeitar, o erro do backend vira o feedback final.

### Validação de CPF/CNPJ — `brasil_fields`

```dart
import 'package:brasil_fields/brasil_fields.dart';

CPFValidator.isValid('33461671002');   // checa DV
CNPJValidator.isValid('12175094000119');
```

Validação de dígito verificador é client-side. O backend revalida (não confiar só no front), mas o feedback rápido melhora UX.

## Máscaras

Usamos `mask_text_input_formatter`:

```dart
final cpfMask = MaskTextInputFormatter(
  mask: '###.###.###-##',
  filter: {'#': RegExp(r'\d')},
);

final cnpjMask = MaskTextInputFormatter(
  mask: '##.###.###/####-##',
  filter: {'#': RegExp(r'\d')},
);

final telefoneMask = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {'#': RegExp(r'\d')},
);

final cepMask = MaskTextInputFormatter(
  mask: '#####-###',
  filter: {'#': RegExp(r'\d')},
);
```

Aplicar no `TextField`:

```dart
TextFieldThemed(
  label: 'CPF',
  controller: cpfCnpjCtrl,
  keyboardType: TextInputType.number,
  inputFormatters: [cpfMask],
  // ...
)
```

### Trocar máscara dinamicamente (CPF ↔ CNPJ)

Quando `tipoUsuario` muda, a máscara do mesmo controller precisa virar de CPF pra CNPJ. Solução:

```dart
inputFormatters: [isPF ? cpfMask : cnpjMask],
```

E ao trocar `tipoUsuario`, **resetar a máscara antiga e o controller**:

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

`_syncFromVm` é chamado no `build()`. Idempotente e barato.

## Upload de arquivos

`file_picker` 11.x retorna bytes diretamente:

```dart
final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  withData: true, // necessário em web
);

if (result != null && result.files.isNotEmpty) {
  final file = result.files.first;
  if (file.bytes != null) {
    vm.setDocumento(file.bytes!, file.name);
  }
}
```

`withData: true` é **obrigatório** em web (não há filesystem path em browser, só bytes). Em mobile/desktop também funciona.

ViewModel guarda os bytes:

```dart
Uint8List? imagemBytes;
String? imagemFilename;
Uint8List? documentoBytes;
String? documentoFilename;

void setImagem(Uint8List? bytes, String? filename) {
  imagemBytes = bytes;
  imagemFilename = filename;
  fieldErrors.remove('imagem');
  notifyListeners();
}
```

A codificação base64 acontece **só no `toJson()` do request model** (camada data):

```dart
// data/models/criar_protetor_ong_request_model.dart
Map<String, dynamic> toJson() {
  return {
    // ...
    'documentoComprobatorio': base64Encode(documentoBytes),
    if (imagemBytes != null) 'imagemBase64': base64Encode(imagemBytes!),
  };
}
```

Por que tão tarde? Manter `Uint8List` em memória até a hora do submit é mais leve (string base64 infla 33%) e mantém a separação de responsabilidades — encoding é detalhe de transporte.

### Validação de tamanho

Backend aceita até 5MB **binário**. Validação local antes do submit:

```dart
static const int maxFileSizeBytes = 5 * 1024 * 1024;

if (documentoBytes != null && documentoBytes!.lengthInBytes > maxFileSizeBytes) {
  errors['documento'] = 'Documento muito grande. Limite: 5MB.';
}
```

`lengthInBytes` é o tamanho real do binário. O backend valida pelo tamanho do binário decodificado, então não precisa se preocupar com a inflação base64 do lado do cliente — basta checar o `Uint8List`.

### Componente: `FileUploadCard`

Detalhes em `DESIGN_SYSTEM.md`. API:

```dart
FileUploadCard({
  required String label,
  required String hint,
  required IconData icon,
  required Uint8List? bytes,
  required String? filename,
  required List<String> allowedExtensions,
  required void Function(Uint8List bytes, String filename) onPick,
  VoidCallback? onRemove,
  String? errorText,
})
```

Vazio: ícone + botão "Escolher arquivo". Preenchido: filename + tamanho formatado + botões "Remover"/"Trocar".

## Integração ViaCEP

Endpoint: `https://viacep.com.br/ws/{cep}/json/`. Datasource em `lib/data/datasources/cep_remote_datasource.dart` (Dio próprio, host externo).

### Disparo automático ao digitar

No CEP field:

```dart
TextFieldThemed(
  label: 'CEP',
  controller: cepCtrl,
  keyboardType: TextInputType.number,
  inputFormatters: [cepMask],
  errorText: vm.fieldErrors['cep'],
  onChanged: onCepChanged, // delega ao parent
)
```

E no parent state:

```dart
Timer? _cepDebounce;

void _onCepChanged(String value, RegisterProtetorOngViewModel vm) {
  vm.setCep(value);
  _cepDebounce?.cancel();
  final clean = value.replaceAll(RegExp(r'\D'), '');
  if (clean.length == 8) {
    _cepDebounce = Timer(
      const Duration(milliseconds: 500),
      () => vm.consultarCep(),
    );
  }
}
```

Debounce de 500ms evita request por dígito digitado. Timer é cancelado se o usuário continua digitando — só dispara após pausa.

### Comportamento do VM

```dart
Future<void> consultarCep() async {
  final clean = cep.replaceAll(RegExp(r'\D'), '');
  if (clean.length != 8) return;

  isCepLoading = true;
  notifyListeners();

  final endereco = await cepRepository.consultarCep(clean);

  isCepLoading = false;
  if (endereco != null) {
    logradouro = endereco.logradouro;
    bairro = endereco.bairro;
    cidade = endereco.cidade;
    estado = endereco.estado;
    fieldErrors.remove('logradouro');
    fieldErrors.remove('bairro');
    fieldErrors.remove('cidade');
    fieldErrors.remove('estado');
  }
  notifyListeners();
}
```

Em sucesso: preenche logradouro/bairro/cidade/estado. **Não bloqueia** o usuário — ele pode editar depois.

Em erro (CEP não existe ou rede falhou): silencioso. Usuário continua preenchendo manual. Detalhes em `ERROR_HANDLING.md`.

### Sincronizar controllers com VM

Como `consultarCep` muda o state do VM (popula logradouro/bairro/etc.), os `TextEditingController` na page precisam ser atualizados:

```dart
void _syncFromVm(RegisterProtetorOngViewModel vm) {
  if (_logradouroCtrl.text != vm.logradouro) {
    _logradouroCtrl.text = vm.logradouro;
  }
  if (_bairroCtrl.text != vm.bairro) {
    _bairroCtrl.text = vm.bairro;
  }
  // ... outros ...
}
```

Chamado no início do `build()`. Idempotente.

## Multi-step forms

Padrão: **um único ViewModel** com `currentStep` (int) e métodos `validateStepN`/`nextStep`/`prevStep`/`submit`.

```dart
int currentStep = 0;

bool validateStep1() { /* popula fieldErrors do step 1 */ }
bool validateStep2() { /* popula fieldErrors do step 2 */ }

bool nextStep() {
  if (currentStep != 0) return true;
  if (!validateStep1()) return false;
  currentStep = 1;
  notifyListeners();
  return true;
}

void prevStep() {
  if (currentStep == 0) return;
  currentStep = 0;
  error = null;
  notifyListeners();
}

Future<bool> submit() async {
  if (!validateStep2()) return false;
  // ... chama repo ...
}
```

Page renderiza condicionalmente:

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 200),
  transitionBuilder: (child, animation) =>
      FadeTransition(opacity: animation, child: child),
  child: vm.currentStep == 0
      ? _Step1Fields(key: const ValueKey('step-1'), ...)
      : _Step2Fields(key: const ValueKey('step-2'), ...),
)
```

`AnimatedSwitcher` faz cross-fade entre os steps. `ValueKey` distinto força a transição.

### Por que não `IndexedStack`

`IndexedStack` reserva o espaço do filho **maior** — se o step 2 tem 800px e o step 1 só 300px, no step 1 sobra um vazio gigantesco abaixo.

Render condicional resolve. Os `TextEditingController` ficam no `State` do parent, então estado dos campos é preservado mesmo quando o widget filho é descartado.

### Direcionar erro do backend pro step certo

Se o submit do step 2 retorna 409 com `field: 'email'` (campo do step 1), o VM volta o usuário pro step 1:

```dart
on Failure catch (f) {
  _setError(f);
  if (f.field == 'email' || f.field == 'cpfCnpj') {
    currentStep = 0;
    notifyListeners();
  }
  return false;
}
```

## Indicador de força da senha

Computado no VM como **getter derivado** (não state):

```dart
typedef SenhaForca = ({String label, double progress, Color color});

SenhaForca get senhaForca {
  if (senha.isEmpty) {
    return (label: '', progress: 0, color: AppTheme.mutedForeground);
  }
  final hasUpper = senha.contains(RegExp(r'[A-Z]'));
  final hasDigit = senha.contains(RegExp(r'\d'));
  if (senha.length < 6) {
    return (label: 'Fraca', progress: 0.33, color: AppTheme.destructive);
  }
  if (senha.length >= 8 && hasUpper && hasDigit) {
    return (label: 'Forte', progress: 1.0, color: AppTheme.sage);
  }
  return (label: 'Média', progress: 0.66, color: AppTheme.accent);
}
```

Reage automaticamente porque `setSenha` chama `notifyListeners()` e o getter é puro. O widget `PasswordStrengthIndicator` consome direto.

**Não bloqueia submit.** Senha fraca passa — o backend só rejeita se < 8 chars, e a UI já valida isso. O indicador é informativo.

## Submit padrão

```dart
Future<bool> submit() async {
  if (!validateStep2()) return false;

  isLoading = true;
  error = null;
  notifyListeners();

  try {
    final params = CriarProtetorOngParams(/* monta a partir do state */);
    await usersRepository.criarProtetorOng(params);
    isLoading = false;
    sent = true;
    notifyListeners();
    return true;
  } on Failure catch (f) {
    _setError(f);
    if (f.field == 'email' || f.field == 'cpfCnpj') {
      currentStep = 0;
      notifyListeners();
    }
    return false;
  } catch (_) {
    _setError(Failure('Não foi possível concluir o cadastro.'));
    return false;
  }
}
```

E na page:

```dart
Future<void> _onSubmit() async {
  final vm = context.read<RegisterProtetorOngViewModel>();
  final ok = await vm.submit();
  if (!mounted) return;
  if (ok) {
    AppNotifier.instance.success('Cadastro realizado com sucesso! 🐾');
    context.go('/login');
  }
}
```

## Reset de form

Quando o form precisa voltar ao estado inicial (ex.: após sucesso, indo pra outra tela), o VM expõe `reset()`:

```dart
void reset() {
  email = '';
  sent = false;
  isLoading = false;
  fieldErrors = {};
  notifyListeners();
}
```

A page chama explicitamente quando apropriado. Não automatizamos isso — às vezes manter estado é desejável (volta pelo botão "voltar" e vê o que preencheu).

## Checklist ao adicionar um campo novo

1. Declarar `String campo = '';` (ou tipo apropriado) no VM.
2. Criar `setCampo(String v)` com `_setField`.
3. Criar `TextEditingController` na page.
4. Adicionar `dispose()` do controller.
5. `TextFieldThemed(label: '...', controller: ..., onChanged: vm.setCampo, errorText: vm.fieldErrors['campo'])`.
6. Adicionar regra no `validateStepN` se necessário.
7. Incluir no `toJson()` do request model se vai pro backend.
8. Atualizar `ERROR_HANDLING.md` se a validação tem mensagem nova.
