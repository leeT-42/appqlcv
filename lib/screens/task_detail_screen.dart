import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import 'add_task_screen.dart';
import 'dart:ui';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final FirebaseService _firebaseService = FirebaseService();

  TaskDetailScreen({super.key, required this.task});

  void _showDeleteDialog(BuildContext context) {
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
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Quay lại màn hình trước
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleCompleteStatus() {
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      description: task.description,
      startDate: task.startDate,
      endDate: task.endDate,
      isCompleted: !task.isCompleted,
      userId: task.userId,
    );
    _firebaseService.updateTask(updatedTask);
  }

  Color _getStatusColor() {
    final now = DateTime.now();
    if (task.isCompleted) return Colors.green;
    if (task.endDate.isBefore(now)) return Colors.red;
    
    final difference = task.endDate.difference(now);
    if (difference.inHours <= 1) return Colors.orange;
    if (difference.inHours <= 24) return Colors.amber;
    
    return Colors.blue;
  }

  String _getStatusText() {
    final now = DateTime.now();
    if (task.isCompleted) return 'ĐÃ HOÀN THÀNH';
    if (task.endDate.isBefore(now)) return 'QUÁ HẠN';
    
    final difference = task.endDate.difference(now);
    if (difference.inHours <= 1) return 'SẮP ĐẾN HẠN (${difference.inMinutes} phút)';
    if (difference.inHours <= 24) return 'SẮP ĐẾN HẠN (${difference.inHours} giờ)';
    
    return 'ĐANG THỰC HIỆN';
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    if (task.backgroundColorHex != null) {
      try {
        final hex = task.backgroundColorHex!.replaceFirst('#', '');
        int value = int.parse(hex, radix: 16);
        if (hex.length <= 6) value = 0xFF000000 | value;
        bgColor = Color(value);
      } catch (_) {}
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết công việc'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTaskScreen(task: task),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với tiêu đề và trạng thái
            Card(
              color: (bgColor ?? _getStatusColor()).withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Switch(
                            value: task.isCompleted,
                            onChanged: (value) => _toggleCompleteStatus(),
                            activeColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Ảnh đính kèm
            if (task.imageUrls.isNotEmpty) ...[
              Text(
                'Hình ảnh đính kèm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: task.imageUrls.length,
                itemBuilder: (context, index) {
                  final url = task.imageUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover),
                  );
                },
              ),
              SizedBox(height: 16),
            ],

            // Mô tả công việc
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      task.description,
                      style: TextStyle(fontSize: 16, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Thông tin thời gian
            Text(
              'Thông tin thời gian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 8),

            _buildInfoRow(
              'Thời gian bắt đầu',
              task.formattedStartDate,
              Icons.play_arrow,
              Colors.green,
            ),

            SizedBox(height: 8),

            _buildInfoRow(
              'Thời gian kết thúc',
              task.formattedEndDate,
              Icons.stop,
              Colors.red,
            ),

            SizedBox(height: 8),

            _buildInfoRow(
              'Tổng thời gian',
              _calculateDuration(),
              Icons.timer,
              Colors.orange,
            ),

            SizedBox(height: 16),

            // Thống kê
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildStatItem('Trạng thái', _getStatusText(), _getStatusColor()),
                    _buildStatItem('Ngày tạo', _getCreatedDate(), Colors.grey),
                    _buildStatItem('ID công việc', task.id ?? 'N/A', Colors.grey),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Nút hành động
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('Chỉnh sửa'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTaskScreen(task: task),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Xóa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showDeleteDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration() {
    final duration = task.endDate.difference(task.startDate);
    
    if (duration.inDays > 0) {
      return '${duration.inDays} ngày ${duration.inHours.remainder(24)} giờ';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} giờ ${duration.inMinutes.remainder(60)} phút';
    } else {
      return '${duration.inMinutes} phút';
    }
  }

  String _getCreatedDate() {
    // Nếu không có ID, coi như task mới tạo
    if (task.id == null) return 'Vừa tạo';
    
    // Có thể lấy thời gian tạo từ ID (timestamp trong ID của Firebase)
    try {
      // Firebase push ID chứa timestamp
      final timestamp = int.tryParse(task.id!.substring(0, 8), radix: 16);
      if (timestamp != null) {
        final createdDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        return DateFormat('dd/MM/yyyy HH:mm').format(createdDate);
      }
    } catch (e) {
      print('Error parsing created date: $e');
    }
    
    return 'Không xác định';
  }
}