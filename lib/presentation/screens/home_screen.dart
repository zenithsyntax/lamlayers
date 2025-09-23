import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/poster_repository.dart';
import 'poster_editor_screen.dart';
import '../../core/constants/app_colors.dart';
import '../bloc/editor/editor_bloc.dart';
import '../bloc/editor/editor_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _posterIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = RepositoryProvider.of<PosterRepository>(context);
    final ids = await repo.listPosterIds();
    setState(() {
      _posterIds = ids.reversed.toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasColor,
      appBar: AppBar(
        backgroundColor: AppColors.canvasColor,
        foregroundColor: AppColors.primaryColor,
        title: const Text('My Works', style: TextStyle(color: AppColors.primaryColor)),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            color: AppColors.primaryColor,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => EditorBloc(RepositoryProvider.of<PosterRepository>(context))..add(LoadPosterEvent()),
                child: const PosterEditorScreen(),
              ),
            ),
          ).then((_) => _load());
        },
        backgroundColor: AppColors.accentColor,
        label: const Text('New Poster'),
        icon: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posterIds.isEmpty
              ? const Center(
                  child: Text('No posters yet. Tap New Poster to create.', style: TextStyle(color: AppColors.primaryColor)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _posterIds.length,
                  itemBuilder: (context, index) {
                    final id = _posterIds[index];
                    return _PosterCard(id: id, onOpen: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => EditorBloc(RepositoryProvider.of<PosterRepository>(context))..add(LoadPosterEvent(posterId: id)),
                            child: PosterEditorScreen(posterId: id),
                          ),
                        ),
                      ).then((_) => _load());
                    });
                  },
                ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  final String id;
  final VoidCallback onOpen;
  const _PosterCard({required this.id, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.description, color: AppColors.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Poster $id',
                      style: const TextStyle(color: AppColors.primaryColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


