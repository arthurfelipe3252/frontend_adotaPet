# frontend_adotaPet
Interface da plataforma AdotaPet para adoção responsável de pets. Aplicativo mobile em Flutter (Android e iOS) para adotantes e painel web para gestão de ONGs e protetores. Catálogo de pets com filtros, sistema de match, chat integrado, timeline pós-adoção e mapa de pontos de adoção.

# AdotaPet

Aplicativo Flutter multiplataforma para adoção responsável de pets, conectando adotantes a ONGs e protetores. Implementa arquitetura MVVM, comunicação com API REST real e persistência local de sessão.

## Descrição do app

O AdotaPet é composto por uma interface mobile (Android/iOS) dedicada ao **adotante** e um painel web dedicado à **gestão de ONGs e protetores**, ambos rodando a partir do mesmo código-base Flutter.

No fluxo mobile do adotante, o app oferece:

- Catálogo de pets disponíveis para adoção, com busca textual e filtros (espécie, porte, sexo, vacinação/castração);
- Tela de detalhe de cada pet;
- Quiz de compatibilidade (match) entre o perfil do adotante e o pet;
- Envio e acompanhamento de solicitações de adoção;
- Chat entre adotante e protetor;
- Autenticação com sessão persistida localmente, permitindo login automático em aberturas futuras do app.

No painel web, ONGs e protetores podem cadastrar e editar pets, gerenciar solicitações de adoção recebidas e acompanhar métricas/relatórios.

## Como executar

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.11.1 (Dart ^3.11.1) instalado e configurado (`flutter doctor` sem erros bloqueantes).
- Um dispositivo/emulador Android ou iOS conectado, **ou** um navegador (para rodar a versão web), **ou** o Chrome/Edge para `flutter run -d chrome`.

### Passo a passo

```bash
# 1. Clonar o repositório
git clone <url-do-repositorio>
cd frontend_adotaPet

# 2. Instalar as dependências
flutter pub get

# 3. Rodar o app (escolhe automaticamente um dispositivo conectado)
flutter run

# Alternativas explícitas:
flutter run -d chrome     # versão web, no navegador
flutter run -d android    # emulador/dispositivo Android
flutter run -d ios        # simulador/dispositivo iOS
```

O app já está configurado para consumir a API em produção (`https://adotapet-api.upperlavtech.com/api/v1`), portanto **não é necessário rodar o backend localmente** para usar o app normalmente — basta ter conexão com a internet.

## Padrão escolhido

Além da arquitetura **MVVM** (obrigatória, descrita no relatório técnico), o projeto aplica como padrão de projeto adicional o **Singleton**, combinado com **Observer**:

- **Singleton** — classe `AppNotifier` (`lib/core/notifications/app_notifier.dart`), responsável pelas notificações globais (toasts de sucesso/erro/informação) do aplicativo. Possui construtor privado e uma única instância estática (`AppNotifier.instance`), acessível de qualquer ViewModel sem necessidade de injeção de dependência explícita.
- **Observer** — todo `ViewModel` estende `ChangeNotifier` e notifica suas `Views` via `notifyListeners()`, consumido pelo pacote `provider`. O próprio `AppNotifier` também é um `ChangeNotifier`, sendo simultaneamente Singleton e Observable.

O detalhamento de por que esse padrão foi escolhido e onde exatamente foi aplicado está na Seção 3 do relatório técnico (`Relatorio_Tecnico_AdotaPet.docx`).

## API utilizada

O app consome uma **API REST própria**, desenvolvida em NestJS (arquitetura de microsserviços — catálogo, autenticação, chat, match, adoção e relatórios), versionada sob o prefixo `/api/v1`.

- **Base URL em uso:** `https://adotapet-api.upperlavtech.com/api/v1`
- **Cliente HTTP:** [Dio](https://pub.dev/packages/dio), encapsulado em `lib/core/network/http_client.dart`, com interceptor de renovação automática de token (HTTP 401).
- **Autenticação:** JWT (`Authorization: Bearer <accessToken>`), com par de tokens (access + refresh).

Principais endpoints consumidos:

| Endpoint | Método | Uso no app |
|---|---|---|
| `/users/auth/login` | POST | Login por e-mail e senha |
| `/users/auth/refresh` | POST | Renovação do par de tokens |
| `/pets` | GET | Lista de pets disponíveis (catálogo) |
| `/pets/{id}` | GET | Detalhe de um pet |
| `/adoption-requests` | POST / GET | Criação e listagem de solicitações de adoção |

## Solução de armazenamento local

A persistência local é feita com [`shared_preferences`](https://pub.dev/packages/shared_preferences), encapsulado pela classe `AuthStorage` (`lib/core/storage/auth_storage.dart`).

- **O que é persistido:** apenas o **refresh token** da sessão de autenticação. O access token (JWT de curta duração) fica somente em memória, reduzindo a exposição de credenciais de longa duração no armazenamento do dispositivo.
- **Por quê:** o refresh token persistido é o que permite restaurar a sessão automaticamente ao reabrir o app — sem ele, o usuário precisaria fazer login a cada nova abertura.
- **Como é recuperado:** ao iniciar, a tela de splash dispara `AuthViewModel.bootstrap()`, que chama `AuthRepositoryImpl.tryRestoreSession()`. Esse método lê o refresh token salvo em disco e solicita um novo par de tokens à API; se válido, a sessão é restaurada e o usuário vai direto à tela principal. Se o token estiver expirado/revogado, o armazenamento é limpo e o usuário é direcionado ao login.

Mais detalhes técnicos (incluindo trechos de código) estão na Seção 5 do relatório técnico.