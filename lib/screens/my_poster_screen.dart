import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';

class MyDesignsScreen extends StatefulWidget {
  const MyDesignsScreen({Key? key}) : super(key: key);

  @override
  State<MyDesignsScreen> createState() => _MyDesignsScreenState();
}

class _MyDesignsScreenState extends State<MyDesignsScreen> {
  late Box<PosterProject> _projectBox;

  @override
  void initState() {
    super.initState();
    _openProjectBox();
  }

  Future<void> _openProjectBox() async {
    _projectBox = await Hive.openBox<PosterProject>('posterProjects');
    setState(() {}); // Refresh UI after box is opened
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<PosterProject>('posterProjects').listenable(),
        builder: (context, Box<PosterProject> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No projects yet. Create a new one!'),
            );
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final project = box.getAt(index);
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(project?.name ?? 'Unnamed Project'),
                  subtitle: Text(project?.description ?? 'No description'),
                  onTap: () {
                    // Navigate to poster maker screen with existing project
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PosterMakerScreen(projectId: project?.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to poster maker screen to create a new project
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PosterMakerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
