# AdotaPet Frontend

Aplicativo Flutter multi-plataforma (web + mobile) para adoção responsável de pets. Clean Architecture + MVVM com Provider.

- **Web (navegador):** painel da ONG/protetor (gestão de pets, solicitações, eventos, métricas).
- **Mobile (APK/IPA):** app do adotante (catálogo, match, solicitação, timeline).

Mesmo backend NestJS, mesmo domínio, mesma camada de dados. A divergência fica só na camada de apresentação.

## Stack

- **Flutter + Dart** (SDK ^3.11.1)
- **Provider** (gerenciamento de estado)
- **Dio** (HTTP client)
- **go_router** (navegação — URL real na web, deep link no mobile)
- **DI manual** no `main.dart`

## Comandos

```bash
flutter pub get          # Instala dependências
flutter run              # Roda o app
flutter analyze          # Análise estática
flutter test             # Roda testes
```

## Arquitetura

Clean Architecture com MVVM na camada de apresentação. Estrutura flat por camada, com presentation dividida por plataforma.

### Estrutura de pastas

```
lib/
├── main.dart                                ← Composição raiz (DI manual + go_router)
├── core/
│   ├── errors/failure.dart                  ← Exceção customizada
│   ├── network/http_client.dart             ← Wrapper do Dio (baseUrl: backend)
│   ├── platform/                            ← Helpers de plataforma (kIsWeb, breakpoints)
│   └── routing/app_router.dart              ← Configuração do go_router
├── data/
│   ├── datasources/
│   │   ├── *_remote_datasource.dart         ← Chamadas HTTP (retorna Model)
│   │   └── *_cache_datasource.dart          ← Cache em memória (opcional)
│   ├── models/*_model.dart                  ← Model com fromJson()/toJson()
│   └── repositories/*_repository_impl.dart  ← Implementação (remote + cache fallback)
├── domain/
│   ├── entities/*.dart                      ← Entidade pura (imutável)
│   └── repositories/*_repository.dart       ← Interface abstrata
└── presentation/
    ├── viewmodels/*_viewmodel.dart           ← ChangeNotifier, chama repository (compartilhado)
    ├── widgets/                              ← Widgets reutilizados pelas duas plataformas
    └── pages/
        ├── desktop/*_page.dart               ← Telas para web (painel ONG)
        └── mobile/*_page.dart                ← Telas para Android/iOS (app adotante)
```

### Fluxo de dependências

```
presentation → domain ← data
     ↓                    ↓
  ViewModel          Repository Impl
     ↓                    ↓
  Repository (abs)   Datasource + Model
     ↓
  Entity
```

- **Domain** não depende de nada. É o centro.
- **Data** implementa as interfaces do domain.
- **Presentation** consome apenas o domain (entities + repository interfaces).
- **`domain/` e `data/` são 100% compartilhados** entre web e mobile. Nada de `kIsWeb` nessas camadas.

## Multi-plataforma (web + mobile)

### Regras de separação

1. **`domain/` e `data/` são compartilhados.** Mesmas entities, repositories, models e datasources rodam em ambos. Backend é o mesmo.
2. **`presentation/viewmodels/` é compartilhado.** A lógica de tela (validação, chamada ao repository, estado) é a mesma — não duplicar.
3. **`presentation/pages/` é separado por plataforma.** Cada tela tem (ou pode ter) duas versões: `pages/desktop/login_page.dart` e `pages/mobile/login_page.dart`. Ambas consomem o mesmo `LoginViewModel`.
4. **Widgets reutilizáveis** (botões, inputs, logo, cards) ficam em `presentation/widgets/`. Se um widget precisa se comportar diferente por plataforma, abstrair em duas variantes ou aceitar parâmetros — não usar `kIsWeb` dentro dele.

### Seleção da página por plataforma

No `app_router.dart`, cada rota mapeia para a Page correspondente à plataforma. Padrão:

```dart
GoRoute(
  path: '/login',
  builder: (ctx, state) => kIsWeb ? const DesktopLoginPage() : const MobileLoginPage(),
),
```

Se quiser breakpoint (web em janela pequena vira mobile), usar `LayoutBuilder` no nível do `MaterialApp`. Por padrão, usar `kIsWeb` simples.

### Plugins com comportamento diferente por plataforma

Quando um plugin não funciona em web ou exige variante (mapa, storage seguro, câmera, geolocalização, push), abstrair atrás de um **datasource** ou **service** no `core/` ou `data/`, com implementação por plataforma. A camada de domain/viewmodel não conhece a diferença.

Exemplos previstos para o AdotaPet:
- `MapDatasource` — `google_maps_flutter` (mobile) vs `google_maps_flutter_web` (web).
- `SecureStorage` — `flutter_secure_storage` (mobile) vs `localStorage` (web).
- `MediaPicker` — câmera/galeria (mobile) vs `<input type="file">` (web).

## Convenções de código

### Nomenclatura de arquivos

| Item | Padrão | Localização | Exemplo |
|---|---|---|---|
| Entity | `snake_case.dart` | `domain/entities/` | `pet.dart` |
| Model | `snake_case_model.dart` | `data/models/` | `pet_model.dart` |
| Repository interface | `snake_case_repository.dart` | `domain/repositories/` | `pet_repository.dart` |
| Repository impl | `snake_case_repository_impl.dart` | `data/repositories/` | `pet_repository_impl.dart` |
| Remote datasource | `snake_case_remote_datasource.dart` | `data/datasources/` | `pet_remote_datasource.dart` |
| Cache datasource | `snake_case_cache_datasource.dart` | `data/datasources/` | `pet_cache_datasource.dart` |
| ViewModel | `snake_case_viewmodel.dart` | `presentation/viewmodels/` | `pet_viewmodel.dart` |
| Page (web) | `snake_case_page.dart` | `presentation/pages/desktop/` | `pet_page.dart` |
| Page (mobile) | `snake_case_page.dart` | `presentation/pages/mobile/` | `pet_page.dart` |
| Widget compartilhado | `snake_case.dart` | `presentation/widgets/` | `primary_button.dart` |

> Páginas com mesmo nome em `desktop/` e `mobile/` é o padrão esperado — diferenciamos pelo caminho de import, não pelo nome do arquivo.

### Entity (domain)

Classe imutável com campos `final` e construtor `const`:

```dart
class Pet {
  final String id;
  final String name;
  final String species;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
  });
}
```

### Model (data)

Espelho da entity com `fromJson()` e `toJson()`:

```dart
class PetModel {
  final String id;
  final String name;
  final String species;

  PetModel({required this.id, required this.name, required this.species});

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      name: json['name'],
      species: json['species'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'species': species};
  }
}
```

### Repository interface (domain)

Classe abstrata que define o contrato:

```dart
abstract class PetRepository {
  Future<List<Pet>> getPets();
  Future<Pet?> getPetById(String id);
  Future<void> createPet(Pet pet);
}
```

### Repository impl (data)

Implementação com remote datasource + cache fallback:

```dart
class PetRepositoryImpl implements PetRepository {
  final PetRemoteDatasource remote;
  final PetCacheDatasource cache;

  PetRepositoryImpl(this.remote, this.cache);

  @override
  Future<List<Pet>> getPets() async {
    try {
      final models = await remote.getPets();
      cache.save(models);
      return models.map((m) => Pet(id: m.id, name: m.name, species: m.species)).toList();
    } catch (e) {
      final cached = cache.get();
      if (cached != null) {
        return cached.map((m) => Pet(id: m.id, name: m.name, species: m.species)).toList();
      }
      throw Failure("Não foi possível carregar os pets");
    }
  }
}
```

### Remote datasource (data)

Usa o `HttpClient` para chamar a API:

```dart
class PetRemoteDatasource {
  final HttpClient client;

  PetRemoteDatasource(this.client);

  Future<List<PetModel>> getPets() async {
    final response = await client.get('/pets');
    final List data = response.data;
    return data.map((json) => PetModel.fromJson(json)).toList();
  }
}
```

### Cache datasource (data)

Cache simples em memória:

```dart
class PetCacheDatasource {
  List<PetModel>? _cache;

  void save(List<PetModel> pets) { _cache = pets; }
  List<PetModel>? get() { return _cache; }
}
```

### ViewModel (presentation)

Usa `ChangeNotifier` do Provider:

```dart
class PetViewModel extends ChangeNotifier {
  final PetRepository repository;

  bool isLoading = false;
  List<Pet> pets = [];
  String? error;

  PetViewModel(this.repository);

  Future<void> loadPets() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      pets = await repository.getPets();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
```

### Page (presentation)

Vive em `presentation/pages/desktop/` ou `presentation/pages/mobile/`. Usa `Consumer` ou `context.watch` para reagir ao estado. O nome da classe é o mesmo nas duas plataformas — diferenciamos pelo caminho do import.

```dart
// presentation/pages/mobile/pet_page.dart
class PetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pets')),
      body: Consumer<PetViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          if (vm.error != null) return Center(child: Text(vm.error!));
          return ListView.builder(
            itemCount: vm.pets.length,
            itemBuilder: (_, i) => ListTile(title: Text(vm.pets[i].name)),
          );
        },
      ),
    );
  }
}
```

### Roteamento (`go_router`)

`core/routing/app_router.dart` define todas as rotas. A escolha desktop vs mobile é feita no `builder` da rota.

```dart
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/login',
      builder: (ctx, state) => kIsWeb
          ? const desktop.LoginPage()
          : const mobile.LoginPage(),
    ),
    // ... demais rotas
  ],
);
```

Imports usam alias para distinguir as duas Pages:

```dart
import 'package:adota_pet/presentation/pages/desktop/login_page.dart' as desktop;
import 'package:adota_pet/presentation/pages/mobile/login_page.dart' as mobile;
```

### DI no main.dart

Composição manual na raiz. Injetar via `ChangeNotifierProvider` e passar o `appRouter` ao `MaterialApp.router`:

```dart
void main() {
  final client = HttpClient();
  // ... montar datasources, repositories, viewmodels
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => petViewModel),
      ],
      child: const AdotaPetApp(),
    ),
  );
}
```

## Conexão com o backend

Backend NestJS em `localhost:3000`. O `baseUrl` do `HttpClient` muda por plataforma:

| Plataforma | `baseUrl` |
|---|---|
| Web (Flutter web) | `http://localhost:3000` |
| Emulador Android | `http://10.0.2.2:3000` |
| Emulador iOS | `http://localhost:3000` |
| Dispositivo físico | IP da máquina na rede local (ex: `http://192.168.0.10:3000`) |

A escolha pode ser feita com `kIsWeb` + `Platform.isAndroid` no `HttpClient`, ou via configuração externa (`--dart-define`).
