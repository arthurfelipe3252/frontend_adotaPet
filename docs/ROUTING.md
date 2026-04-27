# Roteamento

## Stack

- **`go_router` ^14.6** para todas as rotas.
- Configuração centralizada em `lib/core/routing/app_router.dart`.
- `MaterialApp.router(routerConfig: ...)` no `main.dart`.

Não usamos `Navigator.push/pop` direto. A escolha do `go_router` é documentada em `ARCHITECTURE.md`.

## Configuração

```dart
// lib/core/routing/app_router.dart
GoRouter buildAppRouter(AuthViewModel auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      // ... lógica de guard ...
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => kIsWeb ? const LoginPage() : ...),
      GoRoute(path: '/register-org', builder: ...),
      GoRoute(path: '/forgot-password', builder: ...),
      GoRoute(path: '/home', builder: ...),
    ],
  );
}
```

`buildAppRouter` é uma **função**, não uma instância global. Ela recebe o `AuthViewModel` como dependência. Permite que o router observe mudanças de autenticação via `refreshListenable: auth`.

`auth` é `ChangeNotifier`, então qualquer `notifyListeners()` no `AuthViewModel` re-avalia o `redirect`.

## Lógica de redirect

```dart
redirect: (context, state) {
  final loc = state.matchedLocation;

  // 1. Antes do bootstrap terminar, fica em /splash
  if (!auth.bootstrapDone) {
    return loc == '/splash' ? null : '/splash';
  }

  // 2. Bootstrap terminou na splash: decide pra onde ir
  if (loc == '/splash') {
    return auth.isAuthenticated ? '/home' : '/login';
  }

  // 3. Já autenticado tentando acessar tela de auth
  final isAuthRoute = loc == '/login' ||
      loc == '/register-org' ||
      loc == '/forgot-password';
  if (auth.isAuthenticated && isAuthRoute) {
    return '/home';
  }

  // 4. Não autenticado tentando acessar área protegida
  if (!auth.isAuthenticated && loc == '/home') {
    return '/login';
  }

  return null; // permite a navegação
},
```

Quatro regras simples cobrem todos os casos:

1. Se ainda está fazendo bootstrap, força `/splash`.
2. Quando bootstrap termina e está na splash, decide entre `/home` (autenticado) ou `/login`.
3. Se está autenticado e tenta acessar `/login` ou cadastro, redireciona pra `/home` (não faz sentido logar de novo).
4. Se não está autenticado e tenta acessar `/home`, redireciona pra `/login`.

`return null` permite a navegação sem redirect.

## Bootstrap pattern

A `SplashPage` chama `auth.bootstrap()` no `initState`:

```dart
class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthViewModel>().bootstrap();
    });
  }
  // ... renderiza spinner ...
}
```

O `bootstrap()` chama `tryRestoreSession()` no repository (que tenta refresh com o token salvo). Quando termina, `bootstrapDone = true; notifyListeners()`. Como o router está como `refreshListenable: auth`, ele re-avalia o redirect e leva pra `/home` ou `/login`.

Sem flicker, sem tela branca prolongada, sem race condition.

Detalhes em `AUTHENTICATION.md`.

## Escolha desktop / mobile por rota

Cada rota usa `kIsWeb` (do `flutter/foundation.dart`) pra escolher entre a `Page` desktop e um placeholder mobile:

```dart
GoRoute(
  path: '/login',
  builder: (_, _) => kIsWeb
      ? const LoginPage()
      : const _MobilePlaceholder(message: 'Login mobile em breve'),
),
```

Quando o app de adotante (mobile) for implementado, `kIsWeb ? LoginPageDesktop : LoginPageMobile`.

`_MobilePlaceholder` é um widget privado dentro do mesmo arquivo:

```dart
class _MobilePlaceholder extends StatelessWidget {
  final String message;

  const _MobilePlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Rotas atuais

| Rota | Tela | Acesso | Status |
|---|---|---|---|
| `/splash` | `SplashPage` | público (transitória) | implementada |
| `/login` | `LoginPage` (desktop) | público | implementada |
| `/register-org` | `RegisterProtetorOngPage` (desktop) | público | implementada |
| `/forgot-password` | `ForgotPasswordPage` (desktop) | público (mock) | implementada |
| `/home` | `HomePlaceholderPage` (desktop) | autenticado | placeholder |

Mobile: nenhuma das rotas tem versão mobile ainda. Todas mostram `_MobilePlaceholder`.

## Navegação na page

Use os helpers do `go_router` via context:

```dart
context.go('/home');           // troca rota (replace)
context.push('/forgot-password'); // empilha (mantém histórico)
context.pop();                  // volta (se houver histórico)
context.replace('/login');      // troca sem adicionar ao histórico
```

`go` x `push`:

- `go` — troca a rota corrente. Útil em login bem-sucedido (`/login → /home`).
- `push` — empilha. Útil em navegação interna (`/login → /forgot-password`, com botão "voltar").

## Adicionando uma rota nova

1. Criar a Page (`lib/presentation/pages/desktop/<nome>_page.dart`).
2. Adicionar `GoRoute` no `app_router.dart`:
   ```dart
   GoRoute(
     path: '/nova-rota',
     builder: (_, _) => kIsWeb
         ? const NovaPage()
         : const _MobilePlaceholder(message: 'Em breve'),
   ),
   ```
3. Se for rota protegida, adicionar lógica de redirect (ex.: `if (!auth.isAuthenticated && loc == '/nova-rota') return '/login'`).
4. Atualizar a tabela "Rotas atuais" deste documento.

## Path params e query params

Padrão go_router:

```dart
// definição
GoRoute(path: '/pet/:id', builder: (ctx, state) {
  final id = state.pathParameters['id']!;
  return PetDetailPage(id: id);
}),

// uso
context.go('/pet/abc-123');

// query
context.go('/catalog?especie=gato&porte=pequeno');
state.uri.queryParameters['especie']; // 'gato'
```

Nenhuma rota atual usa path params, mas o padrão fica documentado para uso futuro.

## Testes manuais de fluxo

Cenários esperados pra validar o router:

| Ação | Resultado esperado |
|---|---|
| Abrir app pela primeira vez | `/splash` → bootstrap → `/login` |
| F5 em `/home` quando logado | `/splash` → refresh → `/home` |
| F5 em `/home` com refresh expirado | `/splash` → falha silenciosa → `/login` |
| Tentar `/home` sem login | redirect → `/login` |
| Tentar `/login` já logado | redirect → `/home` |
| Logout em `/home` | `/login` (auth.session vira null, redirect dispara) |
| Login adotante no painel web | mantém `/login` com banner de erro |

## Por que `refreshListenable: auth` em vez de mover redirect pro VM

`refreshListenable` faz o router re-avaliar o `redirect` quando o listenable notifica. É a forma idiomática do go_router pra reagir a mudanças globais (auth) sem expor a UI de navegação ao VM.

Alternativa rejeitada: chamar `context.go('/home')` direto dentro do VM (em `login()`). Acopla VM ao Navigator e quebra testabilidade.

## Bootstrap NÃO bloqueia o `runApp`

Considerei rodar `await authViewModel.bootstrap()` antes de `runApp` (sem splash). Vantagem: zero flicker. Desvantagem: tela branca por 200-1000ms (depende do refresh).

Decisão: usar splash explícito com spinner. Mais Flutter-idiomático, mais profissional, e o overhead de código é mínimo.
