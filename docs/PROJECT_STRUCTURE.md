# Estrutura do projeto

## Árvore atual

```
lib/
├── main.dart                                          ← Composição raiz (DI manual + go_router)
├── core/
│   ├── errors/
│   │   └── failure.dart                               ← Failure, ConflictFailure
│   ├── network/
│   │   └── http_client.dart                           ← Wrapper Dio + interceptor 401
│   ├── notifications/
│   │   └── app_notifier.dart                          ← Singleton de toasts
│   ├── platform/
│   │   └── platform_info.dart                        ← kIsWeb + breakpoints
│   ├── routing/
│   │   └── app_router.dart                            ← go_router config
│   ├── storage/
│   │   └── auth_storage.dart                          ← Wrapper SharedPreferences
│   └── theme/
│       └── app_theme.dart                             ← ThemeData + cores + fontes
├── data/
│   ├── datasources/
│   │   ├── _dio_error_helper.dart                     ← failureFromDio compartilhado
│   │   ├── auth_remote_datasource.dart
│   │   ├── auth_cache_datasource.dart
│   │   ├── users_remote_datasource.dart
│   │   └── cep_remote_datasource.dart
│   ├── models/
│   │   ├── auth_response_model.dart
│   │   ├── cep_response_model.dart
│   │   ├── criar_protetor_ong_request_model.dart
│   │   ├── endereco_model.dart
│   │   ├── login_request_model.dart
│   │   ├── protetor_ong_model.dart
│   │   └── usuario_model.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── cep_repository_impl.dart
│       └── users_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── auth_session.dart
│   │   ├── criar_protetor_ong_params.dart
│   │   ├── endereco.dart
│   │   ├── protetor_ong.dart
│   │   └── usuario.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── cep_repository.dart
│       └── users_repository.dart
└── presentation/
    ├── viewmodels/
    │   ├── auth_viewmodel.dart
    │   ├── forgot_password_viewmodel.dart
    │   └── register_protetor_ong_viewmodel.dart
    ├── widgets/
    │   ├── animated_symbols_background.dart
    │   ├── app_footer.dart
    │   ├── app_logo.dart
    │   ├── app_nav_bar.dart
    │   ├── app_notifications_host.dart
    │   ├── file_upload_card.dart
    │   ├── password_strength_indicator.dart
    │   ├── pf_pj_toggle.dart
    │   ├── primary_button.dart
    │   ├── progress_stepper.dart
    │   └── text_field_themed.dart
    └── pages/
        ├── desktop/
        │   ├── _auth_hero_panel.dart                  ← painel lateral compartilhado
        │   ├── _error_banner.dart                     ← banner inline reutilizado
        │   ├── forgot_password_page.dart
        │   ├── home_placeholder_page.dart
        │   ├── login_page.dart
        │   ├── register_protetor_ong_page.dart
        │   └── splash_page.dart
        └── mobile/                                    ← vazia (sprints futuras)
```

## Convenções de nomenclatura

### Arquivos

Todos `snake_case.dart`. Sufixo identifica o tipo:

| Item | Padrão | Localização | Exemplo |
|---|---|---|---|
| Entity | `<nome>.dart` | `domain/entities/` | `pet.dart` |
| Model | `<nome>_model.dart` | `data/models/` | `pet_model.dart` |
| Request Model | `<nome>_request_model.dart` | `data/models/` | `criar_protetor_ong_request_model.dart` |
| Response Model | `<nome>_response_model.dart` ou `<nome>_model.dart` | `data/models/` | `auth_response_model.dart` |
| Repository interface | `<nome>_repository.dart` | `domain/repositories/` | `auth_repository.dart` |
| Repository impl | `<nome>_repository_impl.dart` | `data/repositories/` | `auth_repository_impl.dart` |
| Remote datasource | `<nome>_remote_datasource.dart` | `data/datasources/` | `auth_remote_datasource.dart` |
| Cache datasource | `<nome>_cache_datasource.dart` | `data/datasources/` | `auth_cache_datasource.dart` |
| ViewModel | `<nome>_viewmodel.dart` | `presentation/viewmodels/` | `auth_viewmodel.dart` |
| Page (desktop) | `<nome>_page.dart` | `presentation/pages/desktop/` | `login_page.dart` |
| Page (mobile) | `<nome>_page.dart` | `presentation/pages/mobile/` | `login_page.dart` (mesmo nome) |
| Widget compartilhado | `<nome>.dart` | `presentation/widgets/` | `primary_button.dart` |

### Classes

`PascalCase`. Sufixo idêntico ao nome do arquivo (sem o snake e sem `.dart`):

- `pet.dart` → `class Pet`
- `pet_model.dart` → `class PetModel`
- `auth_repository.dart` → `abstract class AuthRepository`
- `auth_repository_impl.dart` → `class AuthRepositoryImpl implements AuthRepository`
- `auth_viewmodel.dart` → `class AuthViewModel extends ChangeNotifier`
- `login_page.dart` → `class LoginPage extends StatelessWidget` ou `StatefulWidget`

Pages com mesmo nome em `desktop/` e `mobile/` é o padrão esperado — distinguimos pelo path do import, não pelo nome.

### Helpers privados de arquivo

Arquivos auxiliares que **não** devem ser importados por outros módulos: prefixo `_` no arquivo.

- `data/datasources/_dio_error_helper.dart` — só usado por outros datasources do mesmo pacote.
- `presentation/pages/desktop/_auth_hero_panel.dart` — só páginas do diretório.
- `presentation/pages/desktop/_error_banner.dart` — idem.

Classes/funções dentro do arquivo também usam `_` na frente quando privadas a ele:

```dart
// app_notifications_host.dart
class _NotificationToast extends StatefulWidget { ... }   // privado
class AppNotificationsHost extends StatelessWidget { ... } // público
```

## Imports

**Sempre** absolutos com prefixo do package:

```dart
import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/domain/entities/pet.dart';
```

Nunca relativos (`../../core/...`). Imports relativos quebram quando arquivos são movidos.

Ordem dos imports (separados por linha em branco):

1. `dart:` (stdlib).
2. `package:flutter/...` e `package:flutter/...`.
3. Outros packages externos (`package:dio/...`, `package:provider/...`).
4. Imports do próprio projeto (`package:adota_pet/...`).

Exemplo:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/domain/entities/usuario.dart';
```

`dart format` aplica essa ordem automaticamente.

## Adicionando uma feature nova

Exemplo: nova feature de "favoritos de pet". Sequência sugerida:

1. **Entity** — `lib/domain/entities/favorito.dart`.
2. **Repo interface** — `lib/domain/repositories/favoritos_repository.dart` com `Future<List<Favorito>> listar()`, `Future<void> adicionar(String petId)`, etc.
3. **Models** — `lib/data/models/favorito_model.dart`, `lib/data/models/favoritar_request_model.dart`.
4. **Datasource** — `lib/data/datasources/favoritos_remote_datasource.dart`.
5. **Repo impl** — `lib/data/repositories/favoritos_repository_impl.dart`.
6. **Wire no `main.dart`** — instanciar datasource, repo, ViewModel; registrar Provider.
7. **ViewModel** — `lib/presentation/viewmodels/favoritos_viewmodel.dart`.
8. **Page(s)** — `lib/presentation/pages/desktop/favoritos_page.dart` e/ou `mobile/`.
9. **Rota** — `lib/core/routing/app_router.dart`.
10. **Documentação** — atualizar `BACKEND_INTEGRATION.md` se houver endpoints novos.

`flutter analyze` precisa sair limpo após cada commit.

## Princípio: a árvore é descobrível

Um desenvolvedor novo deve conseguir abrir o projeto, ler `lib/main.dart`, e em 10 minutos navegar a árvore inteira sabendo onde encontrar cada coisa. Não criamos pastas extras "porque parece organizado" — só quando há ≥3 arquivos claramente do mesmo domínio que ainda não têm casa. Por isso, por exemplo, `core/notifications/` existe (1 arquivo apenas, mas claramente uma sub-feature do core), e `core/routing/` também (vai crescer).
