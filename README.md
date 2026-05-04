# ffs — Flutter Foundation Scaffold

A friendly, one-command CLI for scaffolding Flutter projects with the boring
parts already wired up: an architecture preset (Clean / MVVM / Simple),
optional Firebase, and optional Supabase.

Inspired by `flutterfire`, but broader in scope. Cross-platform: works on
**macOS, Windows, and Linux**.

```
$ ffs create my_app --arch clean --firebase --supabase
```

## Install

`ffs` is a Dart CLI, so it runs anywhere the Dart SDK is installed (which
ships with every Flutter install).

From this repo:

```bash
dart pub global activate --source path .
```

That puts an `ffs` executable on your `$PATH` (you may need to add Dart's
`pub-cache/bin` to your PATH the first time — Dart prints the path).

## Commands

| Command                       | Purpose |
| ----------------------------- | ------- |
| `ffs create <name>`           | Create a new Flutter project with an architecture preset. |
| `ffs add feature <name>`      | Add a feature module to an existing project, auto-detecting its architecture. |
| `ffs firebase`                | Run `flutterfire configure` against the current Flutter project (installs `flutterfire_cli` if missing). |
| `ffs supabase`                | Add `supabase_flutter`, scaffold a `SupabaseConfig`, and write a `.env` placeholder. |
| `ffs doctor`                  | Verify Flutter / Dart / flutterfire / Firebase / Node / git are reachable. |
| `ffs --version`, `ffs --help` | The usual. |

### `ffs create`

```
ffs create <project_name>
  -a, --arch          [simple | mvvm | clean]   default: mvvm
      --org           reverse-domain id          default: com.example
      --description   project description
      --platforms     comma list                 default: android,ios,web
      --firebase      run flutterfire configure after creation
      --supabase      add Supabase config + client
      --overwrite     replace existing directory
```

The Flutter version used to scaffold the project is **whatever `flutter` is
on your PATH** — `ffs` calls `flutter create` under the hood, so the SDK and
template come from the user's existing install.

### Architectures

- **simple** — `lib/features/<name>/<name>_page.dart` with stateful widgets.
- **mvvm** — `models/`, `view_models/` (extending a `BaseViewModel` with
  `ChangeNotifier`), and `views/`.
- **clean** — Layered into `domain/` (entities, repositories, usecases),
  `data/` (repository impls), and `presentation/` (controllers, pages), plus
  shared `core/` (failures, base usecase).

`ffs add feature <name>` inspects the existing project and generates a feature
matching the architecture you used at create time.

## Architecture (of `ffs` itself)

The CLI is built with the `args` package's `CommandRunner`. Each command is a
self-contained `Command<int>` subclass under `lib/src/commands/` and is wired
up in `lib/ffs.dart`. To add a new top-level feature:

1. Drop `lib/src/commands/<thing>_command.dart`.
2. Add `addCommand(<Thing>Command());` in `FfsRunner`.

That's the whole extension story — no plugin loader, no codegen, no global
state. Templates live in `lib/src/templates/` and are plain Dart strings (so
you can edit and re-run without any build step).

Cross-platform notes: shell calls go through `lib/src/utils/shell.dart`, which
uses `runInShell: true` and probes for executables with `where` on Windows
and `which` elsewhere.

## Development

```bash
dart pub get
dart analyze
dart run bin/ffs.dart --help
```

## Status

This is `0.1.0` — happy to layer on more (state management presets,
networking layer, theming generator, build runner setup, CI templates).
