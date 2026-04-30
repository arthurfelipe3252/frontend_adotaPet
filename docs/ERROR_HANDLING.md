# Tratamento de erros

Princípio: **nenhum erro do backend ou da rede pode ficar silencioso pro usuário**, exceto refresh em background (que falha pra `/login` natural).

Cada cenário tem mensagem em PT-BR e local de exibição definido.

## A classe `Failure`

Arquivo: `lib/core/errors/failure.dart`.

```dart
class Failure implements Exception {
  final String message;
  final String? field;

  Failure(this.message, {this.field});

  @override
  String toString() =>
      'Failure: $message${field != null ? ' (field: $field)' : ''}';
}

/// Sentinel para HTTP 409 — usado para o repository diferenciar
/// "email já cadastrado" vs "cpf/cnpj já cadastrado" pela mensagem.
class ConflictFailure extends Failure {
  ConflictFailure(super.message);
}
```

- **`message`** — texto user-friendly em PT-BR.
- **`field`** — opcional. Quando presente (`'email'`, `'cpfCnpj'`, etc.), o ViewModel direciona para `fieldErrors[field]`. Ausente, vira banner.

## `failureFromDio` — helper compartilhado

Arquivo: `lib/data/datasources/_dio_error_helper.dart` (privado ao package data).

Converte `DioException` em `Failure` aplicando ordem de precedência:

```dart
Failure failureFromDio(DioException e, {Map<int, String>? customByStatus}) {
  // 1. Sem resposta — timeout / connection refused / offline
  if (e.response == null) {
    return Failure('Sem conexão. Verifique sua internet e tente novamente.');
  }

  final status = e.response!.statusCode ?? 0;

  // 2. 5xx — erro do servidor
  if (status >= 500 && status < 600) {
    return Failure('Erro no servidor. Tente novamente em instantes.');
  }

  // 3. mensagem custom por status
  if (customByStatus != null && customByStatus.containsKey(status)) {
    return Failure(customByStatus[status]!);
  }

  // 4-5. mensagem do backend
  final backendMessage = extractBackendMessage(e.response?.data);
  if (backendMessage != null) {
    return Failure(backendMessage);
  }

  // 6. fallback
  return Failure('Não foi possível concluir a operação.');
}

String? extractBackendMessage(dynamic data) {
  if (data is! Map) return null;
  final message = data['message'];
  if (message is String && message.trim().isNotEmpty) return message;
  if (message is List && message.isNotEmpty) {
    final first = message.first;
    if (first is String && first.trim().isNotEmpty) return first;
  }
  return null;
}
```

NestJS validator manda erros como **lista de strings** (`message: ['campo X é obrigatório', ...]`). O helper extrai o primeiro item.

## Uso típico no datasource

Cada datasource captura `DioException` e chama `failureFromDio` com `customByStatus` específico do endpoint:

```dart
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

## Sentinel `SESSION_EXPIRED`

O endpoint `/users/auth/refresh` retorna 401 quando o refresh token está expirado, revogado ou já foi usado. Esse é um cenário **silencioso** (não mostra erro pro usuário, só direciona pra `/login`).

Para isso, o datasource lança um `Failure('SESSION_EXPIRED')`:

```dart
Future<AuthResponseModel> refresh(String refreshToken) async {
  try {
    final response = await client.post('/users/auth/refresh', data: {'refreshToken': refreshToken});
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      throw Failure('SESSION_EXPIRED');
    }
    throw failureFromDio(e);
  }
}
```

E o repository captura essa string-sentinel:

```dart
@override
Future<bool> tryRefresh() async {
  final refreshToken = cache.refreshToken;
  if (refreshToken == null) return false;
  try {
    final model = await remote.refresh(refreshToken);
    await _persistSession(model.toEntity());
    return true;
  } on Failure catch (f) {
    if (f.message == 'SESSION_EXPIRED') {
      await cache.clear();
      httpClient.setAccessToken(null);
    }
    return false;
  }
}
```

## `ConflictFailure` — desambiguação no cadastro

`POST /users/protetores-ongs` retorna 409 tanto para email duplicado quanto para CPF/CNPJ duplicado. A mensagem do backend distingue, mas a UI quer um `fieldError` específico.

Por isso o datasource lança `ConflictFailure` quando o status é 409:

```dart
on DioException catch (e) {
  if (e.response?.statusCode == 409) {
    final msg = extractBackendMessage(e.response?.data) ?? '';
    throw ConflictFailure(msg);
  }
  throw failureFromDio(e, customByStatus: {
    400: 'Verifique os dados informados.',
  });
}
```

E o repository inspeciona a mensagem para decidir o `field`:

```dart
on ConflictFailure catch (f) {
  final lower = f.message.toLowerCase();
  if (lower.contains('email')) {
    throw Failure('Este email já está cadastrado.', field: 'email');
  }
  if (lower.contains('cpf') || lower.contains('cnpj')) {
    throw Failure('CPF/CNPJ já cadastrado.', field: 'cpfCnpj');
  }
  throw Failure('Email ou CPF/CNPJ já cadastrado.');
}
```

A decisão fica no **repository** (camada data) porque é a fronteira que conhece a estrutura do backend. O ViewModel só recebe um `Failure` com `field` já direcionado.

## ViewModel — distribuição via `_setError`

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

Cada VM tem seu `_setError` privado (são poucas linhas, não vale extrair em helper externo).

## Pages — onde cada mensagem aparece

| Tipo de erro | Componente | Posição | Onde implementar |
|---|---|---|---|
| `vm.error` (banner geral) | `ErrorBanner` (vermelho com ícone) | Logo acima do botão de submit | `if (vm.error != null) ErrorBanner(message: vm.error!)` |
| `vm.fieldErrors[key]` | `errorText` do `TextFieldThemed` | Abaixo do campo | `errorText: vm.fieldErrors['email']` |
| Sucesso (cadastro/forgot) | `AppNotifier` (toast verde) | Top-right da tela | `AppNotifier.instance.success('...')` |
| Erro inesperado | Idem ou banner | Idem | Decisão por contexto |

`ErrorBanner` é um widget privado em `lib/presentation/pages/desktop/_error_banner.dart`. Forma:

```dart
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0x1AD93939),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppTheme.destructive),
  ),
  child: Row(
    children: [
      const Icon(Icons.error_outline_rounded, color: AppTheme.destructive),
      const SizedBox(width: 10),
      Expanded(child: Text(message, style: ...)),
    ],
  ),
)
```

## Validações locais (cliente)

Antes de chamar o backend, ViewModels validam regras óbvias e populam `fieldErrors`. Tabela canônica:

| Cenário | Onde aparece | Mensagem |
|---|---|---|
| Email vazio/inválido | `fieldErrors['email']` | "Informe um email válido." |
| CPF inválido (DV) | `fieldErrors['cpfCnpj']` | "CPF inválido." |
| CNPJ inválido (DV) | `fieldErrors['cpfCnpj']` | "CNPJ inválido." |
| Senha < 8 chars | `fieldErrors['senha']` | "Senha precisa de pelo menos 8 caracteres." |
| Senha > 72 chars | `fieldErrors['senha']` | "Senha não pode passar de 72 caracteres." |
| Senha != Confirmar | `fieldErrors['confirmarSenha']` | "As senhas não conferem." |
| CEP < 8 dígitos | `fieldErrors['cep']` | "CEP inválido." |
| Estado != 2 chars | `fieldErrors['estado']` | "UF inválida (use 2 letras)." |
| Número vazio | `fieldErrors['numero']` | "Informe o número." |
| Bairro/Cidade/Logradouro vazio | `fieldErrors[<campo>]` | "Campo obrigatório." |
| Nome < 2 chars | `fieldErrors['nome']` | "Informe o nome completo." |
| Telefone com tamanho inválido | `fieldErrors['telefone']` | "Telefone inválido." |
| Termos não aceitos | `error` (banner) | "Você precisa aceitar os termos para continuar." |
| Documento ausente | `fieldErrors['documento']` | "Envie o documento comprobatório." |
| Foto > 5MB binário | `fieldErrors['imagem']` | "Imagem muito grande. Limite: 5MB." |
| Documento > 5MB binário | `fieldErrors['documento']` | "Documento muito grande. Limite: 5MB." |
| Descrição > 1800 chars | (bloqueado por `maxLength` no `TextField`) | (truncamento natural, contador `0/1800`) |

Validações locais usam `brasil_fields` para CPF/CNPJ:

```dart
import 'package:brasil_fields/brasil_fields.dart';

if (digits.length != 11 || !CPFValidator.isValid(digits)) {
  errors['cpfCnpj'] = 'CPF inválido.';
}
```

## Tabela completa de cenários do backend

| Cenário | HTTP | Onde aparece | Mensagem |
|---|---|---|---|
| Login OK | 200 | redirect | `/home` |
| Login email/senha errado | 401 | banner | "Email ou senha inválidos." |
| Login dados malformados | 400 | banner | "Verifique os dados informados." |
| Login adotante (regra UI) | (lógica VM) | banner | "Esta área é exclusiva para protetores e ONGs." |
| Login sem internet/timeout | n/a | banner | "Sem conexão. Verifique sua internet e tente novamente." |
| Login 5xx | 5xx | banner | "Erro no servidor. Tente novamente em instantes." |
| Login outro 4xx | 4xx | banner | mensagem do backend ou genérica |
| Cadastro OK | 201 | toast | "Cadastro realizado com sucesso!" → `/login` |
| Cadastro 400 (campo identificável) | 400 | fieldErrors[campo] | mensagem do backend |
| Cadastro 400 (genérico) | 400 | banner | "Verifique os dados informados." |
| Cadastro email duplicado | 409 | fieldErrors['email'] | "Este email já está cadastrado." |
| Cadastro CPF/CNPJ duplicado | 409 | fieldErrors['cpfCnpj'] | "CPF/CNPJ já cadastrado." |
| Cadastro 409 ambíguo | 409 | banner | "Email ou CPF/CNPJ já cadastrado." |
| Cadastro sem internet/timeout | n/a | banner | "Sem conexão. Verifique sua internet e tente novamente." |
| Cadastro 5xx | 5xx | banner | "Erro no servidor. Tente novamente em instantes." |
| Refresh em bootstrap 401 | 401 | (silencioso) | limpa storage → `/login` |
| Refresh em bootstrap network | n/a | (silencioso) | mantém storage → `/login` (próximo open tenta de novo) |
| Refresh em runtime (interceptor) 401 | 401 | (silencioso) | logout completo → `/login` |
| Refresh em runtime (interceptor) network | n/a | propaga 401 da request original | banner do VM correspondente |
| Logout 401 | 401 | (silencioso) | logout local sempre acontece |
| Logout network | n/a | (silencioso) | logout local sempre acontece |
| getMe 403 | 403 | (futura tela) | "Acesso negado a este perfil." |
| getMe 404 | 404 | (futura tela) | "Perfil não encontrado." |
| ViaCEP CEP não existe (`erro: true`) | 200 | (silencioso) | usuário preenche manual |
| ViaCEP network/timeout | n/a | (silencioso) | usuário preenche manual |
| Forgot password sucesso (mock) | (mock) | toast | "Se este email existir, enviamos um link de recuperação." |
| Forgot password validação | local | fieldErrors['email'] | "Informe um email válido." |

## Por que mensagens hardcoded em PT-BR

- I18n não é objetivo da versão atual.
- Centralizar mensagens em `strings.dart` agora seria over-engineering para um conjunto que cabe em duas tabelas.
- Quando entrar i18n, criamos uma camada de localização (`flutter_localizations` + `intl`) sem mexer na arquitetura — só substitui strings literais por chaves.

## Checklist ao adicionar um endpoint novo

1. Criar datasource com `try/catch` em `DioException`.
2. Definir `customByStatus` específico (status codes documentados pela API).
3. Decidir se algum status precisa de tratamento especial (sentinel, `ConflictFailure`).
4. No repository, capturar exceções específicas (se houver) e adicionar `field` quando aplicável.
5. No ViewModel, garantir que `_setError(f)` é chamado em todos os caminhos de erro.
6. Na page, garantir que `vm.error` e `vm.fieldErrors[<chave>]` aparecem nos lugares certos.
7. Atualizar a tabela de cenários acima.
