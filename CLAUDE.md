# AdotaPet Frontend

Aplicativo mobile Flutter para adoção responsável de pets. Clean Architecture + MVVM com Provider.

## Stack

- **Flutter + Dart** (SDK ^3.11.1)
- **Provider** (gerenciamento de estado)
- **Dio** (HTTP client)
- **Navigator** padrão (navegação)
- **DI manual** no `main.dart`

## Comandos

```bash
flutter pub get          # Instala dependências
flutter run              # Roda o app
flutter analyze          # Análise estática
flutter test             # Roda testes
```

## Arquitetura

Clean Architecture com MVVM na camada de apresentação. Estrutura flat por camada.

### Estrutura de pastas

```
lib/
├── main.dart                              ← Composição raiz (DI manual)
├── core/
│   ├── errors/failure.dart                ← Exceção customizada
│   └── network/http_client.dart           ← Wrapper do Dio (baseUrl: backend)
├── data/
│   ├── datasources/
│   │   ├── *_remote_datasource.dart       ← Chamadas HTTP (retorna Model)
│   │   └── *_cache_datasource.dart        ← Cache em memória (opcional)
│   ├── models/*_model.dart                ← Model com fromJson()/toJson()
│   └── repositories/*_repository_impl.dart ← Implementação (remote + cache fallback)
├── domain/
│   ├── entities/*.dart                    ← Entidade pura (imutável)
│   └── repositories/*_repository.dart     ← Interface abstrata
└── presentation/
    ├── viewmodels/*_viewmodel.dart         ← ChangeNotifier, chama repository
    └── pages/*_page.dart                  ← Widget com Consumer/context.watch
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

## Convenções de código

### Nomenclatura de arquivos

| Item | Padrão | Exemplo |
|---|---|---|
| Entity | `snake_case.dart` | `pet.dart` |
| Model | `snake_case_model.dart` | `pet_model.dart` |
| Repository interface | `snake_case_repository.dart` | `pet_repository.dart` |
| Repository impl | `snake_case_repository_impl.dart` | `pet_repository_impl.dart` |
| Remote datasource | `snake_case_remote_datasource.dart` | `pet_remote_datasource.dart` |
| Cache datasource | `snake_case_cache_datasource.dart` | `pet_cache_datasource.dart` |
| ViewModel | `snake_case_viewmodel.dart` | `pet_viewmodel.dart` |
| Page | `snake_case_page.dart` | `pet_page.dart` |

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

Usa `Consumer` ou `context.watch` para reagir ao estado:

```dart
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

### DI no main.dart

Composição manual na raiz. Injetar via `ChangeNotifierProvider`:

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

- Backend NestJS roda em `localhost:3000`
- `HttpClient` usa `baseUrl: http://10.0.2.2:3000` (emulador Android)
- Para dispositivo físico, usar o IP da máquina na rede local
