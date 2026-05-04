import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/fs.dart';

/// Supported architectures. Each writes its own folder layout into `lib/` and
/// replaces `lib/main.dart` with an entrypoint that imports the architecture.
enum Architecture {
  simple('simple', 'Stateful widgets only — no formal layering.'),
  mvvm('mvvm', 'Model–View–ViewModel with ChangeNotifier.'),
  clean('clean', 'Clean Architecture: data / domain / presentation layers.');

  const Architecture(this.id, this.description);
  final String id;
  final String description;

  static Architecture? fromId(String id) {
    for (final a in Architecture.values) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Scaffold the chosen architecture inside [projectDir]. Assumes
/// `flutter create` has already populated the project.
void scaffoldArchitecture(
  String projectDir,
  String packageName,
  Architecture arch,
) {
  switch (arch) {
    case Architecture.simple:
      _scaffoldSimple(projectDir, packageName);
    case Architecture.mvvm:
      _scaffoldMvvm(projectDir, packageName);
    case Architecture.clean:
      _scaffoldClean(projectDir, packageName);
  }
}

String _libPath(String projectDir, [String relative = '']) =>
    p.join(projectDir, 'lib', relative);

void _scaffoldSimple(String projectDir, String pkg) {
  writeFile(_libPath(projectDir, 'core/theme/app_theme.dart'), _appTheme);
  writeFile(_libPath(projectDir, 'features/home/home_page.dart'),
      _simpleHomePage(pkg));
  writeFile(_libPath(projectDir, 'main.dart'), _mainSimple(pkg));
}

void _scaffoldMvvm(String projectDir, String pkg) {
  writeFile(_libPath(projectDir, 'core/theme/app_theme.dart'), _appTheme);
  writeFile(_libPath(projectDir, 'core/base/base_view_model.dart'),
      _baseViewModel);
  writeFile(_libPath(projectDir, 'features/home/models/counter_model.dart'),
      _counterModel);
  writeFile(
      _libPath(projectDir, 'features/home/view_models/home_view_model.dart'),
      _homeViewModel(pkg));
  writeFile(_libPath(projectDir, 'features/home/views/home_view.dart'),
      _homeView(pkg));
  writeFile(_libPath(projectDir, 'main.dart'), _mainMvvm(pkg));
}

void _scaffoldClean(String projectDir, String pkg) {
  writeFile(_libPath(projectDir, 'core/theme/app_theme.dart'), _appTheme);
  writeFile(_libPath(projectDir, 'core/error/failures.dart'), _failures);
  writeFile(_libPath(projectDir, 'core/usecase/usecase.dart'), _useCaseBase);

  writeFile(_libPath(projectDir, 'features/home/domain/entities/counter.dart'),
      _counterEntity);
  writeFile(
      _libPath(projectDir,
          'features/home/domain/repositories/counter_repository.dart'),
      _counterRepoIface(pkg));
  writeFile(
      _libPath(projectDir,
          'features/home/domain/usecases/increment_counter.dart'),
      _incrementUsecase(pkg));

  writeFile(
      _libPath(projectDir,
          'features/home/data/repositories/counter_repository_impl.dart'),
      _counterRepoImpl(pkg));

  writeFile(
      _libPath(projectDir,
          'features/home/presentation/controllers/home_controller.dart'),
      _homeController(pkg));
  writeFile(
      _libPath(
          projectDir, 'features/home/presentation/pages/home_page.dart'),
      _cleanHomePage(pkg));

  writeFile(_libPath(projectDir, 'main.dart'), _mainClean(pkg));
}

// Remove the default Flutter counter file if it exists; we replace main.dart.
void cleanupDefaults(String projectDir) {
  final test = File(p.join(projectDir, 'test', 'widget_test.dart'));
  if (test.existsSync()) {
    // Replace the boilerplate widget test so it compiles against new main.dart.
    writeFile(test.path, _genericWidgetTest);
  }
}

// =====================================================================
// Shared snippets
// =====================================================================

const _appTheme = '''
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
''';

const _genericWidgetTest = '''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
''';

// =====================================================================
// Simple
// =====================================================================

String _simpleHomePage(String pkg) => '''
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Text('Count: \$_count', style: Theme.of(context).textTheme.headlineMedium),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

String _mainSimple(String pkg) => '''
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$pkg',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomePage(),
    );
  }
}
''';

// =====================================================================
// MVVM
// =====================================================================

const _baseViewModel = '''
import 'package:flutter/foundation.dart';

enum ViewState { idle, busy, error }

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setState(ViewState s, {String? error}) {
    _state = s;
    _errorMessage = error;
    notifyListeners();
  }
}
''';

const _counterModel = '''
class CounterModel {
  const CounterModel({this.value = 0});
  final int value;

  CounterModel copyWith({int? value}) => CounterModel(value: value ?? this.value);
}
''';

String _homeViewModel(String pkg) => '''
import 'package:$pkg/core/base/base_view_model.dart';
import 'package:$pkg/features/home/models/counter_model.dart';

class HomeViewModel extends BaseViewModel {
  CounterModel _counter = const CounterModel();
  CounterModel get counter => _counter;

  void increment() {
    _counter = _counter.copyWith(value: _counter.value + 1);
    notifyListeners();
  }
}
''';

String _homeView(String pkg) => '''
import 'package:flutter/material.dart';
import 'package:$pkg/features/home/view_models/home_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _vm = HomeViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _vm.removeListener(_onChange);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home (MVVM)')),
      body: Center(
        child: Text('Count: \${_vm.counter.value}',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _vm.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

String _mainMvvm(String pkg) => '''
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/views/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$pkg',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeView(),
    );
  }
}
''';

// =====================================================================
// Clean Architecture
// =====================================================================

const _failures = '''
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
''';

const _useCaseBase = '''
abstract class UseCase<T, P> {
  Future<T> call(P params);
}

class NoParams {
  const NoParams();
}
''';

const _counterEntity = '''
class Counter {
  const Counter(this.value);
  final int value;
}
''';

String _counterRepoIface(String pkg) => '''
import 'package:$pkg/features/home/domain/entities/counter.dart';

abstract class CounterRepository {
  Future<Counter> get();
  Future<Counter> increment();
}
''';

String _incrementUsecase(String pkg) => '''
import 'package:$pkg/core/usecase/usecase.dart';
import 'package:$pkg/features/home/domain/entities/counter.dart';
import 'package:$pkg/features/home/domain/repositories/counter_repository.dart';

class IncrementCounter implements UseCase<Counter, NoParams> {
  IncrementCounter(this.repository);
  final CounterRepository repository;

  @override
  Future<Counter> call(NoParams params) => repository.increment();
}
''';

String _counterRepoImpl(String pkg) => '''
import 'package:$pkg/features/home/domain/entities/counter.dart';
import 'package:$pkg/features/home/domain/repositories/counter_repository.dart';

class InMemoryCounterRepository implements CounterRepository {
  Counter _value = const Counter(0);

  @override
  Future<Counter> get() async => _value;

  @override
  Future<Counter> increment() async {
    _value = Counter(_value.value + 1);
    return _value;
  }
}
''';

String _homeController(String pkg) => '''
import 'package:flutter/foundation.dart';
import 'package:$pkg/core/usecase/usecase.dart';
import 'package:$pkg/features/home/domain/entities/counter.dart';
import 'package:$pkg/features/home/domain/usecases/increment_counter.dart';

class HomeController extends ChangeNotifier {
  HomeController(this._increment);

  final IncrementCounter _increment;

  Counter _counter = const Counter(0);
  Counter get counter => _counter;

  Future<void> increment() async {
    _counter = await _increment(const NoParams());
    notifyListeners();
  }
}
''';

String _cleanHomePage(String pkg) => '''
import 'package:flutter/material.dart';
import 'package:$pkg/features/home/presentation/controllers/home_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});
  final HomeController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home (Clean)')),
      body: Center(
        child: Text('Count: \${widget.controller.counter.value}',
            style: Theme.of(context).textTheme.headlineMedium),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
''';

String _mainClean(String pkg) => '''
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/data/repositories/counter_repository_impl.dart';
import 'features/home/domain/usecases/increment_counter.dart';
import 'features/home/presentation/controllers/home_controller.dart';
import 'features/home/presentation/pages/home_page.dart';

void main() {
  final repo = InMemoryCounterRepository();
  final increment = IncrementCounter(repo);
  final controller = HomeController(increment);
  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$pkg',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: HomePage(controller: controller),
    );
  }
}
''';
