import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import 'dart:io';

class AddTaskScreen extends StatefulWidget {
  final Task? task;

  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(hours: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));
  Color? _backgroundColor;
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _startDate = widget.task!.startDate;
      _endDate = widget.task!.endDate;
      _startTime = TimeOfDay.fromDateTime(widget.task!.startDate);
      _endTime = TimeOfDay.fromDateTime(widget.task!.endDate);
      // Áp dụng màu nền hiện có (nếu có)
      if (widget.task!.backgroundColorHex != null) {
        final hex = widget.task!.backgroundColorHex!.replaceFirst('#', '');
        try {
          int value = int.parse(hex, radix: 16);
          if (hex.length <= 6) value = 0xFF000000 | value;
          _backgroundColor = Color(value);
        } catch (_) {}
      }
    } else {
      // Set thời gian mặc định: bắt đầu từ hiện tại, kết thúc sau 1 giờ
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      _endDate = DateTime(now.year, now.month, now.day, now.hour + 1, now.minute);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _startTime.hour,
            _startTime.minute,
          );
          // Nếu ngày bắt đầu thay đổi, điều chỉnh ngày kết thúc nếu cần
          if (_endDate.isBefore(_startDate)) {
            _endDate = DateTime(
              picked.year,
              picked.month,
              picked.day,
              _endTime.hour,
              _endTime.minute,
            ).add(Duration(days: 1));
          }
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _endTime.hour,
            _endTime.minute,
          );
        }
        _validateDates();
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startDate = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endTime = picked;
          _endDate = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            picked.hour,
            picked.minute,
          );
        }
        _validateDates();
      });
    }
  }

  void _validateDates() {
    // Đảm bảo thời gian kết thúc không trước thời gian bắt đầu
    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _endDate = _startDate.add(Duration(hours: 1));
        _endTime = TimeOfDay.fromDateTime(_endDate);
      });
    }
  }

  
  void _pickBackgroundColor(Color color) {
    setState(() {
      _backgroundColor = color;
    });
  }

  String _formatDateTime(DateTime date) {
    return '${DateFormat('dd/MM/yyyy').format(date)} - ${DateFormat('HH:mm').format(date)}';
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    // Tạo DateTime với cả ngày và giờ
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    
    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text,
      description: _descriptionController.text,
      startDate: startDateTime,
      endDate: endDateTime,
      isCompleted: widget.task?.isCompleted ?? false,
      userId: _firebaseService.currentUser!.uid,
      backgroundColorHex: _backgroundColor != null ? '#${_backgroundColor!.value.toRadixString(16)}' : null,
    );

    try {
      // Ảnh: giữ ảnh cũ khi edit, thêm ảnh mới nếu có
      List<String> imageUrls = List<String>.from(widget.task?.imageUrls ?? const []);
      for (final file in _selectedImages) {
        final url = await _firebaseService.uploadTaskImage(
          file: file,
          userId: task.userId,
        );
        imageUrls.add(url);
      }

      final Task toSave = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        startDate: task.startDate,
        endDate: task.endDate,
        isCompleted: task.isCompleted,
        userId: task.userId,
        backgroundColorHex: task.backgroundColorHex,
        imageUrls: imageUrls,
      );

      String savedId = toSave.id ?? '';
      if (widget.task == null) {
        savedId = await _firebaseService.addTask(toSave);
        toSave.id = savedId;
      } else {
        await _firebaseService.updateTask(toSave);
      }

      // Schedule notification at end time
      await NotificationService().scheduleTaskReminder(
        id: toSave.id ?? savedId,
        title: toSave.title,
        body: 'Đến giờ kết thúc:  ${_formatDateTime(toSave.endDate)}',
        dateTime: toSave.endDate,
      );

      // Schedule notification BEFORE 1 DAY
      final DateTime notifyTime = toSave.endDate.subtract(Duration(days: 1));
      if (notifyTime.isAfter(DateTime.now())) {
        await NotificationService().scheduleTaskReminder(
          id: (toSave.id ?? savedId) + '__before1d',
          title: toSave.title,
          body: 'Công việc "${toSave.title}" sẽ kết thúc sau 1 ngày!',
          dateTime: notifyTime,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Thêm công việc' : 'Sửa công việc'),
      ),
      body: Container(
        color: _backgroundColor?.withOpacity(0.15),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề công việc',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả công việc',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Thời gian bắt đầu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian bắt đầu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Icon(Icons.calendar_today, color: Colors.blue),
                              title: Text('Ngày bắt đầu'),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                              onTap: () => _selectDate(context, true),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Icon(Icons.access_time, color: Colors.green),
                              title: Text('Giờ bắt đầu'),
                              subtitle: Text(_startTime.format(context)),
                              onTap: () => _selectTime(context, true),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Bắt đầu: ${_formatDateTime(_startDate)}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Thời gian kết thúc
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian kết thúc',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: Icon(Icons.calendar_today, color: Colors.blue),
                              title: Text('Ngày kết thúc'),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                              onTap: () => _selectDate(context, false),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Icon(Icons.access_time, color: Colors.red),
                              title: Text('Giờ kết thúc'),
                              subtitle: Text(_endTime.format(context)),
                              onTap: () => _selectTime(context, false),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Kết thúc: ${_formatDateTime(_endDate)}',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Hiển thị cảnh báo nếu thời gian không hợp lệ
              if (_endDate.isBefore(_startDate))
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thời gian kết thúc phải sau thời gian bắt đầu',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Nền và ảnh
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Chọn nền', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final color in [
                      Colors.white,
                      Colors.yellow[100]!,
                      Colors.orange[100]!,
                      Colors.red[100]!,
                      Colors.green[100]!,
                      Colors.blue[100]!,
                      Colors.purple[100]!,
                      Colors.grey[200]!,
                    ])
                      GestureDetector(
                        onTap: () => _pickBackgroundColor(color),
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _backgroundColor == color ? Colors.blue : Colors.grey[300]!,
                              width: _backgroundColor == color ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              
              

              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.task == null ? 'Thêm công việc' : 'Cập nhật công việc',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}