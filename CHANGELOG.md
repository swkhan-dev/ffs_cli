## 0.1.0

Initial release.

- `ffs create <name>` — scaffold a Flutter project with `--arch [simple|mvvm|clean]`, optional `--firebase` and `--supabase`.
- `ffs add feature <name>` — add a feature module that auto-detects the project's architecture.
- `ffs firebase` — install `flutterfire_cli` (if missing), add `firebase_core`, run `flutterfire configure`.
- `ffs supabase` — add `supabase_flutter`, generate a `SupabaseConfig`, scaffold `.env`.
- `ffs doctor` — verify Flutter, Dart, flutterfire, Firebase, Node, and git are reachable.
- Cross-platform: macOS, Linux, Windows.
