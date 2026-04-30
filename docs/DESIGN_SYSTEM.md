# Design system

Identidade visual derivada do protótipo Lovable. Todas as cores são `static const` em `lib/core/theme/app_theme.dart`. Fontes via `google_fonts`.

## Paleta

| Token | Cor | Hex | HSL original (protótipo) | Uso |
|---|---|---|---|---|
| `primary` | Laranja-terra | `#D2693A` | `hsl(18 65% 50%)` | Brand, botões principais, links |
| `primaryDark` | Laranja escuro | `#A84F26` | derivado | Hover/pressed |
| `primaryLight` | Laranja claro | `#E38559` | derivado | Acentos sutis |
| `accent` | Dourado/âmbar | `#EFA63B` | `hsl(35 80% 58%)` | Avisos, gradient hero |
| `sage` | Verde acinzentado | `#7AAD83` | `hsl(140 20% 55%)` | Botões "Próximo", success, toast verde |
| `sageMint` | Verde mint | `#6FBA9D` | `hsl(160 30% 60%)` | Variação |
| `background` | Creme | `#FAF6F1` | `hsl(30 33% 97%)` | Scaffold |
| `surface` | Creme claro | `#FCFAF7` | `hsl(30 25% 98%)` | Cards |
| `foreground` | Quase-preto morno | `#2A2622` | `hsl(20 10% 15%)` | Texto principal |
| `mutedForeground` | Cinza morno | `#8A8378` | derivado | Texto secundário, hints |
| `destructive` | Vermelho | `#D93939` | `hsl(0 72% 55%)` | Erros, banner vermelho, toast erro |
| `border` | Cinza-creme | `#E2DCD2` | `hsl(30 15% 88%)` | Bordas sutis, dividers |

Tom geral: acolhedor, quente, "pet-friendly" — laranja+dourado+creme com sage como complemento.

## Fontes

- **Quicksand** — display (h1 a h6, títulos). Pesos 400-900.
- **Nunito** — body (parágrafos, labels). Pesos 400-900.

Ambas via `google_fonts: ^6.2.1`.

```dart
final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
  displayLarge:    GoogleFonts.quicksand(fontSize: 44, fontWeight: FontWeight.w800, ...),
  displayMedium:   GoogleFonts.quicksand(fontSize: 36, fontWeight: FontWeight.w800, ...),
  headlineLarge:   GoogleFonts.quicksand(fontSize: 30, fontWeight: FontWeight.w700, ...),
  headlineMedium:  GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.w700, ...),
  headlineSmall:   GoogleFonts.quicksand(fontSize: 20, fontWeight: FontWeight.w700, ...),
  titleLarge:      GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w600, ...),
  labelLarge:      GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, ...),
);
```

## Tema (`AppTheme.light()`)

Aplicado em `MaterialApp.router(theme: AppTheme.light())`. Define:

- **`colorScheme`** — Material 3, cores custom (não `fromSeed`).
- **`scaffoldBackgroundColor`** — `background` (`#FAF6F1`).
- **`textTheme`** — composição Quicksand + Nunito acima.
- **`inputDecorationTheme`** — `TextField` com `fillColor: #F1ECE3`, border-radius 20, sem borda quando enabled, borda primary quando focused, destructive quando error. Padding 18×16.
- **`elevatedButtonTheme`** — primary, white text, padding 28×18, `StadiumBorder` (rounded full), peso 700.
- **`outlinedButtonTheme`** — foreground text, border `border`, mesmo padding e shape.
- **`textButtonTheme`** — primary text, peso 600.
- **`dividerTheme`** — cor `border`, espaço 1.

## Componentes compartilhados

Todos em `lib/presentation/widgets/`. Reutilizáveis em qualquer page.

### `AppLogo`

```dart
AppLogo({double size = 64, bool onDarkBackground = false})
```

Container quadrado com border-radius proporcional, gradient `primary → accent` (em background claro) ou alpha branco (em background escuro). Conteúdo: emoji 🐾.

Usos atuais: header da NavBar, splash, hero panel, telas mobile placeholder.

### `PrimaryButton`

```dart
enum PrimaryButtonVariant { primary, sage }

PrimaryButton({
  required String label,
  IconData? trailingIcon,
  bool isLoading = false,
  bool fullWidth = true,
  PrimaryButtonVariant variant = PrimaryButtonVariant.primary,
  VoidCallback? onPressed,
})
```

Wrapper de `ElevatedButton`. Variants:

- `primary` — laranja, usado em login, "Entrar".
- `sage` — verde acinzentado, usado nos botões "Próximo" e "Finalizar cadastro" do form de cadastro.

Quando `isLoading: true`, swap pra `CircularProgressIndicator` 20px branco no lugar do label.

### `TextFieldThemed`

```dart
TextFieldThemed({
  required String label,
  String? hint,
  TextEditingController? controller,
  String? errorText,
  bool obscureText = false,
  IconData? prefixIcon,
  Widget? suffix,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  ValueChanged<String>? onChanged,
  // ... + onEditingComplete, onSubmitted, maxLines, maxLength, etc
})
```

Wrapper de `TextField` com:

- Label acima (`labelLarge` do tema).
- Decoração consistente do `inputDecorationTheme`.
- `errorText` populado por `vm.fieldErrors[<chave>]`.
- `prefixIcon` opcional, `suffix` widget livre (ex.: ícone de olho pra senha).
- `counterText: ''` quando não há `maxLength` (esconde o "0/" default do Material).

Usado em todos os forms.

### `PasswordStrengthIndicator`

```dart
PasswordStrengthIndicator({required SenhaForca strength})
```

`SenhaForca` é record (`{String label, double progress, Color color}`) derivado da senha. Renderiza barra `LinearProgressIndicator` colorida + label "Fraca / Média / Forte".

Regra (computada no VM):

- `senha.length < 6` → Fraca / 0.33 / `destructive`.
- `senha.length >= 8 && hasMaiuscula && hasDigito` → Forte / 1.0 / `sage`.
- Caso contrário → Média / 0.66 / `accent`.

**Não bloqueia submit** — é informativo.

### `PfPjToggle`

```dart
PfPjToggle({required String selected, required ValueChanged<String> onChanged})
```

Duas pílulas grandes side-by-side: "Pessoa Física" (com `Icons.person_rounded`) e "Pessoa Jurídica" (com `Icons.business_rounded`). Selecionado tem fundo branco + sombra; não-selecionado fica transparente.

`selected` é `'protetor'` ou `'ong'`. Usado no `_Step1Fields` do cadastro.

### `FileUploadCard`

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

Card com border arredondado. Quando vazio, mostra ícone + label + hint + botão "Escolher arquivo". Quando preenchido, mostra checkmark verde + filename + tamanho formatado + botões "Remover" / "Trocar".

Usa `file_picker` 11.x:

```dart
final result = await FilePicker.pickFiles(
  type: FileType.custom,
  allowedExtensions: allowedExtensions,
  withData: true,  // necessário em web pra retornar bytes (não path)
);
```

### `ProgressStepper`

```dart
ProgressStepper({
  required int currentStep,
  required int totalSteps,
  List<String>? stepLabels,
})
```

Barra segmentada com N segmentos. Segmentos `<= currentStep` em cor `sage`, demais em `border`. Texto opcional embaixo: "Passo X de N — Label".

Usado no card de cadastro (2 steps).

### `AppNavBar`

```dart
AppNavBar({bool showLoginAction = true})
```

Header de 60px de altura. Esquerda: `AppLogo(size: 36)` + "AdotaPet" (Quicksand bold 20). Direita: "Já tem uma conta?" + `TextButton` "Entrar →" (vai pra `/login`).

Background creme translúcido (`#F2FAF6F1`) + border-bottom sutil. Posicionado no topo do `Stack` da page.

### `AppFooter`

```dart
AppFooter()
```

Rodapé com padding 32×14. Wrap centralizado com:

- "© 2026 AdotaPet · Conectando vidas, transformando histórias."
- Links placeholders: "Termos", "Privacidade", "Contato" (cor primary, underlined).

Background creme translúcido.

### `AnimatedSymbolsBackground`

```dart
AnimatedSymbolsBackground()
```

12 patinhas (`Icons.pets`) em laranja-terra com opacidade 14-22%, espalhadas pelos cantos da tela. Cada uma tem `AnimationController` próprio (períodos 6.5-11s, dessincronizados).

Movimento: deslocamento bidirecional (driftX e driftY próprios, 50-90px) + leve rotação (~±3°). Cria sensação de "andando" pelo fundo.

Respeita `MediaQuery.disableAnimations` (acessibilidade — `prefers-reduced-motion`). `RepaintBoundary` isola o paint para não invalidar o conteúdo.

Usado no `Stack` da `RegisterProtetorOngPage` atrás de tudo.

### `AppNotificationsHost`

Detalhes em `NOTIFICATIONS.md`.

## Layouts recorrentes

### Split-screen para auth (login, forgot-password)

```dart
Row(
  children: [
    if (PlatformInfo.isDesktopWidth(context))
      const Expanded(flex: 5, child: AuthHeroPanel()),
    Expanded(
      flex: 4,
      child: Center(
        child: SingleChildScrollView(
          padding: ...,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(...formContent...),
          ),
        ),
      ),
    ),
  ],
)
```

`AuthHeroPanel` (em `lib/presentation/pages/desktop/_auth_hero_panel.dart`) é o painel laranja gradiente à esquerda com logo, tagline e bullets.

Em telas estreitas (<900px), só o card aparece — o hero é escondido.

### Card centralizado para forms longos (cadastro)

```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 640),
    child: SizedBox(
      height: double.infinity,
      child: _UnifiedFormCard(...),
    ),
  ),
)
```

Card com altura fixa (toda a altura disponível entre nav e footer), width máxima 640. Scroll interno do card.

## Sombras e elevações

Sombra "soft" usada em cards principais:

```dart
boxShadow: const [
  BoxShadow(
    color: Color(0x1A000000),  // ~10% black
    blurRadius: 40,
    offset: Offset(0, 12),
  ),
],
```

Sombra "card" para botões/elementos secundários:

```dart
boxShadow: const [
  BoxShadow(
    color: Color(0x14000000),  // ~8% black
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
],
```

## Border radius

| Elemento | Radius |
|---|---|
| Inputs | 20 |
| Botões (Stadium) | full (height/2) |
| Cards principais | 28 |
| Cards secundários | 20 ou 16 |
| Toasts | 16 |
| File upload card | 20 |
| Pílulas internas (pf/pj toggle) | 16 |

Sempre com `BorderRadius.circular(N)`. Não usar `BorderRadius.all` quando todos os cantos são iguais.

## Princípio: compor, não duplicar

Todo componente visual reutilizável deve estar em `lib/presentation/widgets/`. Pages **não** redefinem botões, inputs, cards. Se precisar de uma variação, parametrize o widget existente — não crie um novo similar.

Exceção: helpers privados a um arquivo (prefixo `_`) podem viver no próprio arquivo da page. Ex.: `_AuthHeroPanel`, `_ErrorBanner` — usados só no contexto de auth/forms.
