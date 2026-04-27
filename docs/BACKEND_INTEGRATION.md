# Integração com o backend

Backend NestJS rodando em `http://localhost:3000`, prefixo `/api/v1`. Documentação OpenAPI 3.0 em `GET /api/v1/docs-json` (UI em `/api/v1/docs`).

Este documento captura o **snapshot atual** do contrato. Se o backend evoluir, atualize aqui no mesmo PR.

## `baseUrl` por plataforma

```dart
// lib/core/network/http_client.dart
HttpClient()
    : _dio = Dio(BaseOptions(
        baseUrl: kIsWeb
            ? 'http://localhost:3000/api/v1'
            : 'http://10.0.2.2:3000/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ));
```

| Plataforma | baseUrl |
|---|---|
| Web (Flutter web) | `http://localhost:3000/api/v1` |
| Emulador Android | `http://10.0.2.2:3000/api/v1` |
| Emulador iOS | `http://localhost:3000/api/v1` |
| Dispositivo físico | IP da máquina na LAN (ex.: `http://192.168.0.10:3000/api/v1`) |

`10.0.2.2` é o IP que o emulador Android usa pra alcançar `localhost` da máquina host.

Em produção, virar config externa (`--dart-define=API_URL=...`).

## Autenticação

JWT no header `Authorization: Bearer <accessToken>`.

```dart
void setAccessToken(String? token) {
  if (token == null) {
    _dio.options.headers.remove('Authorization');
  } else {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
}
```

Detalhes do fluxo de login/refresh em `AUTHENTICATION.md`.

## Endpoints

### `Auth` — `/users/auth/*`

Todos retornam JSON.

#### `POST /users/auth/login`

Login com email + senha.

**Request:** `LoginDto`
```json
{
  "email": "string (max 150)",
  "senha": "string (8-72 chars)"
}
```

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 200 | `AuthResponseDto` | OK |
| 400 | `{ message }` | Dados inválidos |
| 401 | `{ message }` | Credenciais inválidas (email não existe, senha errada, ou conta inativa) |

#### `POST /users/auth/refresh`

Rotaciona o par de tokens.

**Request:** `RefreshTokenDto`
```json
{ "refreshToken": "string" }
```

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 200 | `AuthResponseDto` | Novo par emitido. Refresh anterior é revogado. |
| 400 | `{ message }` | Body inválido |
| 401 | `{ message }` | Refresh inválido / expirado / revogado / já usado |

#### `POST /users/auth/logout`

Revoga o refresh informado. Idempotente.

**Headers:** `Authorization: Bearer <accessToken>`
**Request:** `RefreshTokenDto`

**Responses:**

| Status | Significado |
|---|---|
| 204 | OK |
| 401 | Access token ausente ou inválido |

#### `POST /users/auth/logout-all`

Revoga **todos** os refresh tokens do usuário.

**Headers:** `Authorization: Bearer <accessToken>`

**Responses:**

| Status | Significado |
|---|---|
| 204 | OK |
| 401 | Access token ausente ou inválido |

### `Users` — `/users/*`

#### `POST /users/adotantes`

Cadastra um novo adotante (PF). Operação transacional: cria endereço + usuário (`tipoUsuario=adotante`) + adotante.

**Request:** `CriarAdotanteDto`
```json
{
  "nome": "string (2-150)*",
  "email": "string (max 150)*",
  "senha": "string (8-72)*",
  "cpf": "string (11 dígitos)*",
  "endereco": EnderecoDto*,
  "telefone": "string (10-11 dígitos, opcional)",
  "imagemBase64": "string (base64, ≤5MB binário, opcional)"
}
```

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 201 | `AdotanteResponseDto` | Criado |
| 400 | `{ message }` | Validação ou regra de domínio |
| 409 | `{ message }` | Email ou CPF já cadastrado |

#### `POST /users/protetores-ongs`

Cadastra protetor (PF) ou ONG (PJ). Operação transacional: cria endereço + usuário + perfil específico.

**Request:** `CriarProtetorOngDto`
```json
{
  "nome": "string (2-150)*",
  "email": "string (max 150)*",
  "senha": "string (8-72)*",
  "tipoUsuario": "'protetor' | 'ong' *",
  "cpfCnpj": "string (11 ou 14 dígitos, com DV válido)*",
  "documentoComprobatorio": "string (base64, ≤5MB binário)*",
  "endereco": EnderecoDto*,
  "telefone": "string (10-11 dígitos, opcional)",
  "telefoneContato": "string (10-11 dígitos, opcional)",
  "descricao": "string (max 2000, opcional)",
  "imagemBase64": "string (base64, ≤5MB binário, opcional)"
}
```

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 201 | `ProtetorOngResponseDto` | Criado |
| 400 | `{ message }` | Validação (ex.: CPF/CNPJ com DV inválido) |
| 409 | `{ message }` | Email ou CPF/CNPJ já cadastrado |

#### `GET /users/me`

Perfil base do usuário autenticado.

**Headers:** `Authorization: Bearer <accessToken>`

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 200 | `UsuarioResponseDto` | OK |
| 401 | | Token ausente ou inválido |

#### `GET /users/adotantes/me`

Perfil completo do adotante autenticado.

**Headers:** `Authorization: Bearer <accessToken>`

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 200 | `AdotanteResponseDto` | OK |
| 401 | | Token ausente ou inválido |
| 403 | | Usuário não é adotante |
| 404 | | Perfil não encontrado |

#### `GET /users/protetores-ongs/me`

Perfil completo do protetor/ONG autenticado.

**Headers:** `Authorization: Bearer <accessToken>`

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 200 | `ProtetorOngResponseDto` | OK |
| 401 | | Token ausente ou inválido |
| 403 | | Usuário não é protetor nem ong |
| 404 | | Perfil não encontrado |

#### `PATCH /users/me/password`

Altera a senha do usuário autenticado. Requer senha atual.

**Request:** `AlterarSenhaDto`
```json
{
  "senhaAtual": "string*",
  "senhaNova": "string (8-72)*"
}
```

**Responses:**

| Status | Body | Significado |
|---|---|---|
| 200 | `UsuarioResponseDto` | OK |
| 400 | | Body inválido |
| 401 | | Senha atual incorreta ou token inválido |

#### `PATCH /users/adotantes/me`

Atualiza dados do adotante autenticado.

**Request:** `AtualizarAdotanteDto` (todos os campos opcionais)
```json
{
  "nome": "string?",
  "telefone": "string?",
  "imagemBase64": "string?",
  "endereco": EnderecoDto?
}
```

`endereco` omitido = não mexe. `endereco` enviado = substitui in-place. **Não aceita `null`** (endereço é obrigatório).

**Imutáveis:** `cpf`, `email`, `tipoUsuario`.

#### `PATCH /users/protetores-ongs/me`

Atualiza dados do protetor/ong autenticado.

**Request:** `AtualizarProtetorOngDto` (todos os campos opcionais)
```json
{
  "nome": "string?",
  "telefone": "string?",
  "descricao": "string?",
  "telefoneContato": "string?",
  "imagemBase64": "string?",
  "endereco": EnderecoDto?
}
```

**Imutáveis:** `cpfCnpj`, `email`, `tipoUsuario`, `documentoComprobatorio`.

#### `GET /users/{id}`

Busca usuário pelo ID. Atualmente só permite buscar o próprio.

#### `PATCH /users/{id}`

Atualiza campos genéricos (nome, telefone). **Email NÃO** é mais aceito aqui.

#### `DELETE /users/{id}`

Soft delete (`ativo = false`).

### `Pets` — `/pets/*`

CRUD básico. DTOs ainda não documentados na spec OpenAPI atual. Quando começar a integrar, documentar aqui.

- `GET /pets` — lista com query params (`especie`, `porte`, `status`, `castrado`, `protetorId`).
- `POST /pets`
- `GET /pets/{id}`
- `PATCH /pets/{id}`
- `DELETE /pets/{id}`
- `GET /pets/protetor/{protetorId}` — pets de um protetor específico.

## DTOs

### `EnderecoDto`

```json
{
  "logradouro": "string (max 255)*",
  "numero": "string (max 20)*",
  "complemento": "string (max 100, opcional)",
  "bairro": "string (max 100)*",
  "cidade": "string (max 100)*",
  "estado": "string (2 chars)*",
  "cep": "string (8 dígitos, sem máscara)*"
}
```

### `EnderecoResponseDto`

Igual ao request + `id` (UUID), `createdAt`, `updatedAt` (ISO 8601).

### `UsuarioResponseDto`

```json
{
  "id": "UUID",
  "nome": "string",
  "email": "string",
  "telefone": "string?",
  "tipoUsuario": "'adotante' | 'protetor' | 'ong'",
  "ativo": "boolean",
  "createdAt": "ISO date",
  "updatedAt": "ISO date"
}
```

**Não tem `imagemBase64`** — a foto vive em `AdotanteResponseDto.imagemBase64` ou `ProtetorOngResponseDto.imagemBase64`.

### `AdotanteResponseDto`

```json
{
  "id": "UUID",
  "cpf": "string (11 dígitos sem máscara)",
  "imagemBase64": "string?",
  "enderecoId": "UUID?",
  "createdAt": "ISO date",
  "updatedAt": "ISO date",
  "usuario": UsuarioResponseDto,
  "endereco": EnderecoResponseDto?
}
```

### `ProtetorOngResponseDto`

```json
{
  "id": "UUID",
  "cpfCnpj": "string (11 ou 14 dígitos sem máscara)",
  "descricao": "string?",
  "telefoneContato": "string?",
  "imagemBase64": "string?",
  "documentoComprobatorio": "string (base64)",
  "enderecoId": "UUID?",
  "createdAt": "ISO date",
  "updatedAt": "ISO date",
  "usuario": UsuarioResponseDto,
  "endereco": EnderecoResponseDto?
}
```

### `AuthResponseDto`

```json
{
  "accessToken": "string (JWT)",
  "refreshToken": "string (opaco, base64url)",
  "expiresIn": "number (segundos)",
  "user": UsuarioResponseDto
}
```

## Limites de payload

- `imagemBase64` — **5MB binário** (~7MB de string base64).
- `documentoComprobatorio` — **5MB binário**.
- `descricao` — backend aceita até 2000, mas a UI limita a **1800** (margem de segurança).

Backend valida pelo tamanho do binário decodificado, então o frontend pode validar pelo `Uint8List.lengthInBytes` direto.

## Imutáveis após cadastro

| Campo | Adotante | Protetor/ONG |
|---|---|---|
| `cpf` | ✓ | — |
| `cpfCnpj` | — | ✓ |
| `email` | ✓ | ✓ |
| `tipoUsuario` | ✓ | ✓ |
| `documentoComprobatorio` | — | ✓ |

Para alterar qualquer um desses, o backend precisaria de endpoint dedicado (não há). Decisão de produto.

## Códigos de erro padronizados

Documentados em `ERROR_HANDLING.md`. Resumo:

| Status | Significado | Tratamento |
|---|---|---|
| 400 | Dados inválidos | Banner ou field error |
| 401 | Não autenticado / credenciais erradas | Banner "Email ou senha inválidos" no login; logout em runtime |
| 403 | Sem permissão (ex.: adotante acessando endpoint de protetor) | Mensagem específica por endpoint |
| 404 | Recurso não encontrado | Mensagem específica |
| 409 | Conflito (email/CPF/CNPJ duplicado) | `ConflictFailure` → repository decide field |
| 5xx | Erro do servidor | "Erro no servidor. Tente novamente em instantes." |

## Mensagens do backend

`response.data['message']` pode ser:

- **String** — mensagem direta.
- **Array de strings** — quando o NestJS validator rejeita múltiplos campos. O frontend pega a **primeira** mensagem útil.

Em produção, as mensagens de 409 distinguem ("Email já cadastrado" vs "CPF já cadastrado"). No Swagger essa distinção não aparece. O frontend usa substring matching no `UsersRepositoryImpl` pra decidir o `field`.

## Integrações externas

### ViaCEP

Endpoint: `https://viacep.com.br/ws/{cep}/json/`.

**Resposta sucesso:**
```json
{
  "cep": "01310-100",
  "logradouro": "Avenida Paulista",
  "complemento": "",
  "bairro": "Bela Vista",
  "localidade": "São Paulo",
  "uf": "SP",
  "ibge": "...",
  "ddd": "..."
}
```

**Resposta erro (CEP não existe):**
```json
{ "erro": true }
```

Não é HTTP 404 — sempre retorna 200 mesmo quando o CEP não existe. Detecta-se pelo body.

Implementação em `lib/data/datasources/cep_remote_datasource.dart`. Detalhes em `FORMS.md` (seção "Integração ViaCEP").

## Verificando o contrato atual

```bash
# Spec completa
curl http://localhost:3000/api/v1/docs-json | jq

# UI Swagger
open http://localhost:3000/api/v1/docs
```

Sempre que algo mudar no backend, refazer essa consulta e atualizar:

1. Este documento (`BACKEND_INTEGRATION.md`).
2. Os datasources/models afetados.
3. Possivelmente as tabelas em `ERROR_HANDLING.md`.

## Checklist ao integrar um endpoint novo

1. Confirmar request/response no Swagger.
2. Criar request model (se houver) com `toJson()`.
3. Criar response model com `fromJson()` + `toEntity()`.
4. Criar datasource com `try/catch` em `DioException` + `failureFromDio` com `customByStatus`.
5. Estender o repository com método novo.
6. Estender o ViewModel pra consumir.
7. Atualizar a página/widget.
8. Atualizar este documento (seção "Endpoints").
9. Rodar `flutter analyze`.
10. Testar manualmente os caminhos felizes e de erro.
