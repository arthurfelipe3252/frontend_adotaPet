# Estratégia multi-plataforma

## Decisão central

Um único projeto Flutter compila para web e mobile. **Domínio e dados são 100% compartilhados.** A divergência fica só na presentation.

| Plataforma | Público | Status |
|---|---|---|
| Web (Flutter web) | Painel de gestão de protetores e ONGs | **Em implementação** |
| Mobile (Android / iOS) | App do adotante | Sprints futuras |

Tese: o backend é o mesmo (mesmo NestJS), o domínio é o mesmo (Pet, Adoção, Match), então faz sentido compartilhar os contratos. Separar em dois projetos duplicaria a camada de dados sem benefício.

Detalhes do trade-off em `ARCHITECTURE.md`.

## Regras de separação

1. **`lib/domain/` é compartilhado.** Mesmas entities, repositories abstratos, params. Nada de `kIsWeb` aqui.
2. **`lib/data/` é compartilhado.** Mesmos models, datasources, repository impls. Nada de `kIsWeb` aqui.
3. **`lib/presentation/viewmodels/` é compartilhado.** A lógica de tela é a mesma — não duplica.
4. **`lib/presentation/widgets/` é compartilhado.** Componentes de UI reutilizados nas duas plataformas. Se um widget precisa se comportar diferente por plataforma, expor parâmetros (não usar `kIsWeb` dentro).
5. **`lib/presentation/pages/desktop/` e `lib/presentation/pages/mobile/`** são separadas. Cada tela pode ter (ou não) duas versões.
6. **`kIsWeb` só aparece em**:
   - `lib/core/routing/app_router.dart` — pra escolher entre `Page` desktop e `_MobilePlaceholder`.
   - `lib/core/network/http_client.dart` — pra escolher `baseUrl`.
   - `lib/core/platform/platform_info.dart` — helper centralizado.

## Estrutura

```
lib/
├── core/                         ← compartilhado
├── data/                         ← compartilhado (domínio do backend é o mesmo)
├── domain/                       ← compartilhado
└── presentation/
    ├── viewmodels/               ← compartilhado
    ├── widgets/                  ← compartilhado
    └── pages/
        ├── desktop/              ← painel web (ONG/protetor)
        └── mobile/               ← app adotante (sprint futura)
```

## `PlatformInfo` — único ponto de detecção

```dart
// lib/core/platform/platform_info.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PlatformInfo {
  PlatformInfo._();

  static const double desktopBreakpoint = 900;

  static bool get isWeb => kIsWeb;

  static bool isDesktopWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }
}
```

Use `PlatformInfo.isWeb` em vez de `kIsWeb` direto na `presentation` — facilita refatoração futura. (`kIsWeb` direto fica restrito a `app_router.dart` e `http_client.dart` por enquanto.)

`isDesktopWidth(ctx)` é pra layouts responsivos dentro do **web**: telas largas mostram split-screen, estreitas mostram só o card. Não é pra trocar entre `LoginPage` desktop e mobile (essa decisão é por `kIsWeb`).

## Roteamento por plataforma

Cada `GoRoute` decide qual Page renderizar:

```dart
GoRoute(
  path: '/login',
  builder: (_, _) => kIsWeb
      ? const LoginPage()                  // desktop
      : const _MobilePlaceholder(...),     // mobile
),
```

Quando o mobile for implementado:

```dart
GoRoute(
  path: '/login',
  builder: (_, _) => kIsWeb
      ? const LoginPageDesktop()
      : const LoginPageMobile(),
),
```

Note que **as classes podem ter o mesmo nome** (`LoginPage`) em `desktop/` e `mobile/`. Diferenciamos pelo path do import. No router, usamos alias quando há ambiguidade:

```dart
import 'package:adota_pet/presentation/pages/desktop/login_page.dart' as desktop;
import 'package:adota_pet/presentation/pages/mobile/login_page.dart' as mobile;

// ...
builder: (_, _) => kIsWeb ? const desktop.LoginPage() : const mobile.LoginPage(),
```

## ViewModels são compartilhados

A lógica de login é a mesma em desktop e mobile: validar email, chamar `repository.login`, salvar session, redirecionar. Por isso o `AuthViewModel` é único.

Diferenças entre plataformas (ex.: o painel web bloqueia adotante, mas o app mobile bloqueia ONG) são tratadas via **flag** ou **VM separado por plataforma**, dependendo da divergência:

- **Pequena divergência** (ex.: regra de bloqueio): tratar via parâmetro/flag no método ou no construtor do VM.
- **Grande divergência** (ex.: telas e fluxos completamente diferentes): criar VM dedicado para a plataforma.

Hoje não temos VMs específicos de plataforma. Quando aparecerem, eles vão em `presentation/viewmodels/desktop/` ou `mobile/` (subpastas a serem criadas).

## Plugins com comportamento diferente por plataforma

Quando um plugin não funciona em web ou exige variante (mapa, storage seguro, câmera, geolocalização, push), abstraímos atrás de uma **interface no domain** com **implementação por plataforma no data**.

Exemplos previstos para o AdotaPet:

| Necessidade | Mobile | Web | Estratégia |
|---|---|---|---|
| Storage de tokens | `flutter_secure_storage` | `localStorage` (via `shared_preferences`) | Hoje usamos `shared_preferences` nas duas (academic-grade). Quando precisar separar, fica `SecureStorage` (interface) + 2 impls. |
| Mapa | `google_maps_flutter` | `google_maps_flutter_web` | Interface `MapDatasource` com 2 impls. |
| Picker de mídia | câmera + galeria | `<input type=file>` | `file_picker` resolve hoje. Se quiser câmera direto, vira interface `MediaPicker`. |
| Notificações push | FCM | (não suportado em web) | Interface `PushService` com no-op no web. |

### Exemplo: HttpClient com baseUrl por plataforma

```dart
// lib/core/network/http_client.dart
HttpClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: kIsWeb
              ? 'http://localhost:3000/api/v1'
              : 'http://10.0.2.2:3000/api/v1',
          // ...
        ),
      );
```

`localhost` em web aponta pro processo do dev local. `10.0.2.2` é o IP que o emulador Android usa pra alcançar `localhost` da máquina host.

Em produção, o baseUrl não vai ser hardcoded — vai vir de `--dart-define=API_URL=...` ou config externa. Quando entrar prod, o tema vira `lib/core/config/`.

### Exemplo: ViaCEP via Dio próprio

`CepRemoteDatasource` cria seu próprio `Dio` (host externo, não usa o `HttpClient` da API):

```dart
class CepRemoteDatasource {
  final Dio _dio;

  CepRemoteDatasource()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://viacep.com.br',
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
  // ...
}
```

Funciona igual em web e mobile. ViaCEP responde com CORS aberto, então não há restrição em web.

## Rodando em cada plataforma

```bash
# Web
flutter run -d chrome --web-port=5555

# Web sem auto-attach (caso o auto cause problema):
flutter run -d web-server --web-port=5555

# Build estático servido externamente:
flutter build web
cd build/web && python -m http.server 5555

# Android (emulador rodando)
flutter run -d <emulator-id>

# iOS (simulador rodando)
flutter run -d <simulator-id>
```

`flutter devices` lista o que está disponível.

## Testando em ambas

Quando uma feature toca presentation, ela precisa ser testada nos dois alvos antes de commit:

1. `flutter analyze` (estático).
2. `flutter run -d chrome` (web).
3. `flutter run -d <emulator>` (mobile, pelo menos abrir e ver que a rota mostra placeholder ou a versão mobile).

Hoje o mobile só tem placeholders, mas a verificação é importante pra detectar quebras: por exemplo, se um plugin novo é incompatível com web ou vice-versa.

## Bundle size

Cada build contém **todo** o código (presentation desktop + mobile + datasources). Não usamos deferred imports nem entry points separados.

Não é problema na escala atual. Se virar (>5MB pra mobile, >2MB pra web inicial), os caminhos são:

1. **Deferred imports** — `import 'pages/mobile/...' deferred as mobile;` carrega lazy.
2. **Entry points separados** — `main_web.dart` e `main_mobile.dart`. Mais drástico.

Não fazer isso preventivamente. Custo de manutenção alto, ganho marginal nessa escala.

## Drift de código entre plataformas

Risco real: com tempo, `if (kIsWeb)` se espalha. Disciplina:

- Code review rejeita `kIsWeb` fora dos lugares permitidos (router, http client, platform_info).
- Quando aparece divergência de comportamento, criar abstração no domain — não condicional na presentation.
- ViewModels não conhecem a plataforma. Se um VM precisa saber (ex.: pra escolher entre `localStorage` e `secure_storage`), o serviço deve ser injetado pelo `main.dart` com a impl correta.
