import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/screens/poster_editor_screen.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/poster_repository.dart';
import 'presentation/bloc/editor/editor_bloc.dart';
import 'presentation/bloc/editor/editor_event.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = PosterRepository();
  await repo.init();
  runApp(LayersPosterMakerApp(repository: repo));
}

class LayersPosterMakerApp extends StatelessWidget {
  final PosterRepository repository;
  const LayersPosterMakerApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MaterialApp(
        title: 'Layers Poster Maker',
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
