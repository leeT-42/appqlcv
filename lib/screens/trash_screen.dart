import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/task.dart';
import 'task_list_screen.dart';
import 'reminder_screen.dart';


class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('Công việc'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TaskListScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Lời nhắc'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ReminderScreen()),
                  );
                },
              ),
             
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Thùng rác'),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseService.getDeletedTasks(_firebaseService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Thùng rác trống'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    onSelected: (value) async {
                      if (value == 'restore') {
                        await _firebaseService.restoreTask(task.id!);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã khôi phục "${task.title}"'), backgroundColor: Colors.green),
                        );
                      } else if (value == 'deletePermanent') {
                        await _firebaseService.deleteTaskPermanently(task.id!);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã xóa vĩnh viễn "${task.title}"'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: const [
                            Icon(Icons.restore_from_trash, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Khôi phục'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deletePermanent',
                        child: Row(
                          children: const [
                            Icon(Icons.delete_forever, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Xóa vĩnh viễn'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  
}


