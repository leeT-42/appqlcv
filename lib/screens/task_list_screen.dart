import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/task.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';
import 'trash_screen.dart';
import 'reminder_screen.dart';
import 'auth_screen.dart'; // Added import for AuthScreen


class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final int _selectedMenuIndex = 0; // 0: công việc, 1: lời nhắc, 2: thùng rác

  

  
  Color _getTaskColor(Task task) {
    final now = DateTime.now();
    if (task.isCompleted) return Colors.green;
    if (task.endDate.isBefore(now)) return Colors.red;
    
    final difference = task.endDate.difference(now);
    if (difference.inHours <= 1) return Colors.orange;
    if (difference.inHours <= 24) return Colors.amber;
    
    return Colors.blue;
  }

  Color? _parseBg(String? hex) {
    if (hex == null) return null;
    try {
      final clean = hex.replaceFirst('#', '');
      int value = int.parse(clean, radix: 16);
      if (clean.length <= 6) value = 0xFF000000 | value;
      return Color(value);
    } catch (_) {
      return null;
    }
  }


  Widget _buildTaskItem(Task task) {
    final isInTrash = _selectedMenuIndex == 2;
    final bg = _parseBg(task.backgroundColorHex);
    return Card(
      color: (bg ?? _getTaskColor(task).withOpacity(0.1)),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: isInTrash
            ? Icon(Icons.delete_outline, color: Colors.red)
            : IconButton(
                icon: Icon(
                  task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: task.isCompleted ? Colors.green : Colors.grey,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    task.isCompleted = !task.isCompleted;
                    _firebaseService.updateTask(task);
                  });
                },
              ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (task.imageUrls.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                 task.imageUrls.first,
                 height: 140,
                 width: double.infinity,
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                 loadingBuilder: (context, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return Container(
                     height: 140,
                     alignment: Alignment.center,
                     child: const CircularProgressIndicator(strokeWidth: 2),
                   );
                 },
                ),
              ),
              SizedBox(height: 8),
            ],
            SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Bắt đầu: ${task.formattedStartDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.flag, size: 14, color: _getTaskColor(task)),
                SizedBox(width: 4),
                Text(
                  'Kết thúc: ${task.formattedEndDate}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTaskColor(task),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            if (task.isOverdue)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'QUÁ HẠN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (task.isDueSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SẮP ĐẾN HẠN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (task.isCompleted)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'HOÀN THÀNH',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(height: 8),
          ],
        ),
        trailing: isInTrash
            ? PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) async {
                  if (value == 'restore') {
                    await _firebaseService.restoreTask(task.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã khôi phục "${task.title}"'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (value == 'deletePermanent') {
                    await _firebaseService.deleteTaskPermanently(task.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã xóa vĩnh viễn "${task.title}"'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore_from_trash, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Khôi phục'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'deletePermanent',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Xóa vĩnh viễn'),
                      ],
                    ),
                  ),
                ],
              )
            : PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) {
                  _handleMenuSelection(value, task);
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'detail',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Xem chi tiết'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Xóa'),
                      ],
                    ),
                  ),
                ],
              ),
        onTap: isInTrash
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailScreen(task: task),
                  ),
                );
              },
      ),
    );
  }

  void _handleMenuSelection(String value, Task task) {
    switch (value) {
      case 'detail':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(task: task),
          ),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(task: task),
          ),
        );
        break;
      case 'delete':
        _showDeleteDialog(task);
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có công việc nào',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy tạo công việc đầu tiên của bạn!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: Text('Tạo công việc mới'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTaskScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Đang tải công việc...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý công việc'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              _showLogoutDialog();
            },
          ),
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
                selected: true,
                onTap: () => Navigator.pop(context),
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
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm công việc',
                hintText: 'Nhập tiêu đề hoặc mô tả...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Task Counter
          StreamBuilder<List<Task>>(
            stream: _firebaseService.getTasksByUser(_firebaseService.currentUser!.uid),
            builder: (context, snapshot) {
              final allTasks = snapshot.data ?? [];
              final completedTasks = allTasks.where((task) => task.isCompleted).length;
              final pendingTasks = allTasks.length - completedTasks;

              if (allTasks.isEmpty) return SizedBox();

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCounterCard('Tất cả', allTasks.length, Colors.blue),
                    _buildCounterCard('Đã hoàn thành', completedTasks, Colors.green),
                    _buildCounterCard('Chưa hoàn thành', pendingTasks, Colors.orange),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 8),

          // Tasks List
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _searchQuery.isNotEmpty
                  ? _firebaseService.searchTasks(_firebaseService.currentUser!.uid, _searchQuery)
                  : _firebaseService.getTasksByUser(_firebaseService.currentUser!.uid),
              builder: (context, snapshot) {
                // Kiểm tra trạng thái kết nối
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState('${snapshot.error}');
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Không tìm thấy kết quả',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thử với từ khóa khác',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskItem(task);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskScreen()),
          );
        },
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 4,
        child: Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildCounterCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa công việc "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _firebaseService.deleteTask(task.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã chuyển "${task.title}" vào Thùng rác'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),  
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await _firebaseService.signOut();
              if (mounted) {
                Navigator.pop(context); // Đóng dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}