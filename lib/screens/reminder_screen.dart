import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';
import 'task_list_screen.dart';
import 'trash_screen.dart';


class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  Color _getTaskColor(Task task) {
    final now = DateTime.now();
    if (task.isCompleted) return Colors.green;
    if (task.endDate.isBefore(now)) return Colors.red;
    final difference = task.endDate.difference(now);
    if (difference.inHours <= 1) return Colors.orange;
    if (difference.inHours <= 24) return Colors.amber;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lời nhắc'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
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
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Thùng rác'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TrashScreen()),
                  );
                },
              ),
              
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseService.getDueSoonTasks(_firebaseService.currentUser!.uid),
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
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Không có công việc sắp đến hạn'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                color: _getTaskColor(task).withOpacity(0.1),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: IconButton(
                    icon: Icon(
                      task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: task.isCompleted ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    onPressed: () async {
                      setState(() {
                        task.isCompleted = !task.isCompleted;
                      });
                      await _firebaseService.updateTask(task);
                    },
                  ),
                  title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.alarm, color: Colors.orange),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}


