# Documentação Técnica — AdotaPet Frontend

Esta pasta concentra a documentação técnica do projeto. O `CLAUDE.md` da raiz é o resumo executivo (instruções vivas para a Claude). Este conjunto aqui é a referência completa.

## Índice

| Documento | O que cobre |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Visão geral da arquitetura (Clean Architecture + MVVM), princípios, decisões |
| [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) | Árvore de pastas, convenções de nomenclatura, organização de arquivos |
| [CODING_PATTERNS.md](CODING_PATTERNS.md) | Padrões de código por camada (entity, model, repo, datasource, VM, page) |
| [STATE_MANAGEMENT.md](STATE_MANAGEMENT.md) | Provider + ChangeNotifier, estados padrão, padrões reativos |
| [ERROR_HANDLING.md](ERROR_HANDLING.md) | `Failure`, `ConflictFailure`, `failureFromDio`, tabela exaustiva de cenários |
| [ROUTING.md](ROUTING.md) | `go_router`, guard de autenticação, redirect, bootstrap, escolha desktop/mobile |
| [MULTIPLATFORM.md](MULTIPLATFORM.md) | Estratégia web + mobile, sub-pastas, abstração de plugins por plataforma |
| [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) | Cores, fontes, tema, widgets compartilhados |
| [NOTIFICATIONS.md](NOTIFICATIONS.md) | Sistema centralizado de toasts (`AppNotifier`) |
| [AUTHENTICATION.md](AUTHENTICATION.md) | Login, refresh com rotação, bootstrap, bloqueio adotante, storage |
| [FORMS.md](FORMS.md) | Padrão de forms (sem `Form`), validação, máscaras, upload, ViaCEP, multi-step |
| [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md) | Contrato com a API NestJS, endpoints, DTOs, headers |

## Como usar

- **Implementando uma feature nova?** Comece por `CODING_PATTERNS.md` para entender a estrutura por camada e siga o exemplo do `pet_*` ou de uma feature equivalente.
- **Tratando um erro novo?** `ERROR_HANDLING.md` tem a tabela com todos os cenários conhecidos e onde a mensagem aparece.
- **Adicionando uma rota ou tela?** `ROUTING.md` + `MULTIPLATFORM.md` cobrem como mapear pra desktop/mobile.
- **Mudando algo visual?** `DESIGN_SYSTEM.md` tem todas as cores, fontes e widgets reutilizáveis.

## Documentação de produto (separada)

A pasta `docs/` também contém artefatos de produto/negócio que **não** são documentação técnica:

- `AdotaPet - Escopo do Projeto.docx` — escopo de produto.
- `Modelo de Negócio AdotaPet.docx`.
- `Proposta de Projeto – AdotaPet.docx`.
- `URS - AdotaPet.docx.pdf` — User Requirements Specification.
- `context_map_adotapet.drawio` + `exemplo_de_context_mapping.png` — mapa de bounded contexts (DDD).
- `Criacao_*.png`, `tela_login_mobile.png` — screenshots do protótipo Lovable.

Esses arquivos não são modificados pela equipe técnica. Servem como referência do que o produto deve ser.

## Mantendo a documentação

A regra é simples: **se uma decisão arquitetural ou um padrão muda, o documento correspondente muda no mesmo PR**. Documentação desatualizada é pior que documentação ausente — induz erro.

Convenções:

- Markdown padrão (CommonMark + GitHub-flavored).
- Snippets Dart com paths reais do projeto (`lib/...`).
- Tabelas para resumos comparativos.
- PT-BR para texto, exemplos e identificadores no código.
- Datas absolutas (`2026-04-26`), não relativas (`semana passada`).
