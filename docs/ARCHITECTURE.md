# Arquitetura

## Stack confirmada

| Item | Escolha | Versão |
|---|---|---|
| Framework | Flutter + Dart | SDK ^3.11.1 |
| Estado | Provider | ^6.1.5 |
| HTTP | Dio | ^5.8 |
| Navegação | go_router | ^14.6 |
| Storage | shared_preferences | ^2.5 |
| Tipografia | google_fonts (Quicksand + Nunito) | ^6.2 |
| Máscaras | mask_text_input_formatter | ^2.9 |
| Validação BR | brasil_fields | ^1.19 |
| Upload de arquivos | file_picker | ^11.0 |
| JWT (decode) | jwt_decoder | ^2.0 |

DI manual no `main.dart` (sem `get_it` ou injetor automático).

## Plataformas alvo

Um único projeto Flutter compila para:

- **Web** — painel de gestão para protetores e ONGs.
- **Mobile (Android/iOS)** — app do adotante (a ser implementado em sprints futuras).

A divergência entre plataformas fica **só na camada de apresentação**. Domínio e dados são 100% compartilhados.

## Princípios

### Clean Architecture

Três camadas com a regra de dependência sempre apontando para o centro:

```
presentation → domain ← data
     │                    │
  ViewModel          Repository Impl
     │                    │
  Repository (abs)   Datasource + Model
     │
  Entity
```

- **Domain** — não importa nada externo (nem Flutter, nem Dio, nem `dart:convert`). É o coração: define entidades imutáveis e contratos abstratos de repositório.
- **Data** — implementa as interfaces do domain. Conhece HTTP (Dio), JSON, base64, cache em memória, storage.
- **Presentation** — consome **apenas** o domain (entities + repository interfaces). Nunca importa de `data/`.

### MVVM na presentation

`Model-View-ViewModel` aplicado dentro da camada de apresentação:

- **View** = `Page` (Widget). Burra: só renderiza estado e dispara métodos do ViewModel.
- **ViewModel** = `ChangeNotifier`. Lógica de tela, validação, chama repository, mantém estado (`isLoading`, `error`, `fieldErrors`, dados).
- **Model** (no contexto MVVM) = entidades do domain consumidas pela tela.

A camada de presentation não tem `Use Cases` separados — a complexidade é absorvida pelo ViewModel + Repository. Use Cases entram só se a lógica ficar genuinamente complexa (vários repositórios, regras intrincadas), e mesmo assim são opcionais.

### Inversion of Control via repositórios

A presentation depende da **interface** do repositório, não da implementação. A composição (DI manual no `main.dart`) injeta a versão concreta. Isso permite:

- Testar ViewModels com fakes/mocks de repositório (sem rede).
- Trocar implementação (ex.: passar de Dio para outro client) sem tocar em ViewModels.
- Garantir que ViewModels não tenham acesso direto a HTTP ou storage.

### Imutabilidade no domain

Entidades são `final` + `const`. Mudar significa criar nova instância. Isso evita "ações à distância" e simplifica equality.

## Fluxo de uma operação típica

Exemplo: usuário toca "Entrar" em `/login`.

```
1. LoginPage.onPressed
   └── AuthViewModel.login(email, senha)            [presentation]
       │
       ├── isLoading = true; notifyListeners()
       │
       └── await repository.login(email, senha)      [domain interface]
           │
           └── AuthRepositoryImpl.login              [data]
               │
               ├── AuthRemoteDatasource.login
               │   ├── HttpClient.post('/users/auth/login', ...)
               │   └── DioException? → failureFromDio(...) → throw Failure
               │
               ├── if user.tipoUsuario == 'adotante':
               │       throw Failure (bloqueio painel web)
               │
               ├── AuthCacheDatasource.save(session)
               └── HttpClient.setAccessToken(...)
```

Nenhum widget conversa com Dio. Nenhum datasource conhece o ViewModel. Cada camada é responsável por uma coisa só.

## Por que Provider e não Riverpod/BLoC

| Critério | Provider | Riverpod | BLoC |
|---|---|---|---|
| Curva de aprendizado | Baixa | Média | Alta |
| Boilerplate | Baixo | Médio | Alto |
| Familiaridade do time | Alta (já usado em aulas) | Baixa | Média |
| Fit pra MVVM | Excelente (`ChangeNotifier`) | Bom | Indireto |
| Escala (>50 telas) | OK com disciplina | Melhor | Melhor |

Para um projeto acadêmico, com escopo bem-definido e equipe pequena, Provider é o sweet spot. A disciplina vem dos padrões documentados aqui.

## Por que `go_router` e não `Navigator` direto

Web exige URL real, deep link, botão "voltar" do browser. `Navigator.push/pop` clássico não dá conta disso. `go_router` resolve com `redirect` declarativo, suporte a query params, `refreshListenable` ligado ao `AuthViewModel`. Em mobile funciona transparentemente.

## Composição (DI manual)

Toda a wiring acontece em `lib/main.dart`. Nenhuma biblioteca de DI:

```dart
final prefs = await SharedPreferences.getInstance();
final authStorage = AuthStorage(prefs);
final httpClient = HttpClient();

final authCache  = AuthCacheDatasource(authStorage);
final authRemote = AuthRemoteDatasource(httpClient);
final usersRemote = UsersRemoteDatasource(httpClient);
final cepRemote   = CepRemoteDatasource();

final authRepository  = AuthRepositoryImpl(remote: authRemote,  cache: authCache, httpClient: httpClient);
final usersRepository = UsersRepositoryImpl(usersRemote);
final cepRepository   = CepRepositoryImpl(cepRemote);

httpClient.onUnauthorized = authRepository.tryRefresh;

final authViewModel = AuthViewModel(authRepository);

runApp(MultiProvider(...));
```

O DI manual é mais verboso que `get_it`/`injectable`, mas mantém o grafo visível. Em projeto desse tamanho, vale a verbosidade.

## Decisões arquiteturais

### `domain/` e `data/` são 100% compartilhados entre plataformas

Nenhum `if (kIsWeb)` em domain ou data. Se algo precisa ser diferente por plataforma (ex.: `flutter_secure_storage` mobile vs `localStorage` web), abstrai-se atrás de uma interface no `domain` e implementações específicas vivem no `data`.

### Sem `Form`/`GlobalKey<FormState>`

Os ViewModels já são a fonte da verdade do estado de formulário. Adicionar `FormState` cria uma segunda fonte e quebra a relação entre campos vizinhos (validar `senha` vs `confirmarSenha` exige falar com dois `TextFormField.validator` de uma vez). Detalhes em `FORMS.md`.

### `bool isLoading` + `String? error` em vez de enum/sealed

Estado simples, ergonômico, lê-se rápido (`if (vm.isLoading) ...`). Enum só compensa quando há 4+ estados ortogonais — aqui não há.

### Sem `Use Cases` separados

Equipe pequena, cobertura funcional média. Repo + ViewModel cobrem 95% dos casos sem fragmentar a lógica. Use Cases entram só se a complexidade pedir.

### Mensagens hardcoded em PT-BR

I18n não é objetivo desta versão. Strings ficam direto no código. Quando entrar i18n, criamos uma camada de localização sem mexer em arquitetura.

## O que está fora desta arquitetura

- **Testes** — não há cobertura nesta sprint. Quando entrar, ficam em `test/` espelhando a estrutura de `lib/`.
- **CI/CD** — sem pipeline configurado.
- **Analytics/Tracking** — não há.
- **Feature flags** — não há.

Quando esses temas surgirem, vão ganhar seus próprios documentos.
