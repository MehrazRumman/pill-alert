import 'package:flutter/material.dart';

import 'repository.dart';
import 'settings_store.dart';

/// Gives screens access to the repository/settings without a DI framework — the direct equivalent
/// of the Kotlin `LocalAppContainer`.
class AppContainer {
  const AppContainer({required this.repository, required this.settings});

  final NirbhorRepository repository;
  final SettingsStore settings;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.container, required super.child});

  final AppContainer container;

  static AppContainer of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.container;
  }

  @override
  bool updateShouldNotify(AppScope old) => container != old.container;
}

extension AppScopeContext on BuildContext {
  AppContainer get app => AppScope.of(this);
  NirbhorRepository get repo => AppScope.of(this).repository;
  SettingsStore get settingsStore => AppScope.of(this).settings;
}

/// Re-runs [query] whenever the repository reports a write, keeping the previous value on screen
/// while the new one loads. This is the Flow-collecting `collectAsStateWithLifecycle` of the
/// Compose original: screens declare what they need and never hold a stale row.
class RepoBuilder<T> extends StatefulWidget {
  const RepoBuilder({
    super.key,
    required this.query,
    required this.builder,
    this.loading,
  });

  final Future<T> Function(NirbhorRepository repo) query;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;

  @override
  State<RepoBuilder<T>> createState() => _RepoBuilderState<T>();
}

class _RepoBuilderState<T> extends State<RepoBuilder<T>> {
  NirbhorRepository? _repo;
  T? _data;
  bool _hasData = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = context.repo;
    if (identical(repo, _repo)) return;
    _repo?.removeListener(_refresh);
    _repo = repo..addListener(_refresh);
    _refresh();
  }

  @override
  void didUpdateWidget(RepoBuilder<T> old) {
    super.didUpdateWidget(old);
    _refresh();
  }

  @override
  void dispose() {
    _repo?.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    final repo = _repo;
    if (repo == null) return;
    final generation = ++_generation;
    final result = await widget.query(repo);
    // A later query already answered — dropping this one keeps the newest write on screen.
    if (!mounted || generation != _generation) return;
    setState(() {
      _data = result;
      _hasData = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tracked separately from the value: a query of type `T?` legitimately answers null (no
    // caregiver yet), and that answer must reach the builder rather than read as still loading.
    if (!_hasData) return widget.loading ?? const SizedBox.shrink();
    return widget.builder(context, _data as T);
  }
}
