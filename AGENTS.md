# Savvy Stock (`savvy_lite`) — Agent Guide

## Project

Flutter business ERP for stock/sales/inventory management. Targets all 6 platforms.

## Commands

| Action | Command |
|--------|---------|
| Run all tests | `flutter test` |
| Single test | `flutter test test/trial_form_test.dart` |
| Analyze | `flutter analyze` |
| Build Android | `flutter build apk` |
| Build Windows | `flutter build windows` |
| Launcher icons | `dart run flutter_launcher_icons` |
| Run app | `flutter run` |

## Current Dev Mode

`lib/core/config/app_config.dart` sets `isTestMode=true`, `bypassApi=true`, `useFakeData=true` — app runs fully offline with fake data. Change these to connect to real backend.

## Key Architecture

- **State**: flutter_bloc ^9.1 (`Bloc`/`Cubit`)
- **DI**: GetIt singleton (`lib/core/di/injection_container.dart`)
- **Routing**: GoRouter ^16 (`lib/core/routes/app_router.dart`) with 80+ route constants in `lib/core/constants/app_routes.dart`. RouteGuard enforces privilege-based access.
- **Local DB**: SQLite via sqflite (mobile) / sqflite_ffi (desktop). Schema version 1. Desktop DB at `%APPDATA%/SavvyStock/savvy_stock.db`.
- **Backend**: Supabase for auth; custom Java server for business data sync.
- **Models**: Manually written (no json_serializable/freezed codegen).
- **Sync**: Every local write creates a `sync_event` (table `sync_event`). `SyncService` processes the queue on a 1-min timer. Entity processing order defined in `lib/core/constants/sync_sequence.json` (40+ entities).

## Repo Conventions

- **Commits**: conventional commits (`fix:`, `feat:`, `refactor:`, etc.)
- **Branch**: work on `new-structure` (default branch)
- **Testing**: minimal — no mockito/mocktail/bloc_test in dev deps. Tests are integration-level only.
- **No CI/CD**: no workflows, no pre-commit hooks.
- **Refactor script**: `refactor_inserts.dart` at root — bulk code transformation utility for sync capture wrapping.

## Gotchas

- `.env` with Supabase creds is tracked in git (added before `.gitignore` rule). Do not rotate unless asked.
- `flutter analyze` has been observed crashing (access violation) on this project. If it hangs or crashes, try `flutter clean && flutter pub get`.
- Two crash logs (`flutter_01.log`, `flutter_02.log`) at root — safe to delete.
- `lib/app/app.dart` and `lib/app/app_bloc_observer.dart` are empty placeholders.
- License validation uses `flutter_secure_storage` + `pointycastle`/`crypto`/`x509_plus` for certificate-based checks.
