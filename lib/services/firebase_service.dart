import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart' as storage;
import 'dart:io';
import '../models/task.dart' as app_model;
import 'notification_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Đăng ký
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  // Đăng nhập
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw e;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // người dùng hủy
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  // Thêm công việc
  Future<String> addTask(app_model.Task task) async {
    try {
      String taskId = _database.child('tasks').push().key!;
      task.id = taskId;
      await _database.child('tasks').child(taskId).set(task.toJson());
      return taskId;
    } catch (e) {
      throw e;
    }
  }

  // Upload ảnh lên Firebase Storage, trả về URL công khai
  Future<String> uploadTaskImage({required File file, required String userId}) async {
    final storageInst = storage.FirebaseStorage.instance;
    final String path = 'users/$userId/tasks/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = storageInst.ref().child(path);
    final uploadTask = await ref.putFile(file);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  // Cập nhật công việc
  Future<void> updateTask(app_model.Task task) async {
    try {
      await _database.child('tasks').child(task.id!).update(task.toJson());
    } catch (e) {
      throw e;
    }
  }

  // Xóa công việc
  Future<void> deleteTask(String taskId) async {
    try {
      // Soft delete: chuyển vào thùng rác
      await _database.child('tasks').child(taskId).update({'isDeleted': true});
      await NotificationService().cancelByIdString(taskId);
    } catch (e) {
      throw e;
    }
  }

  // Khôi phục công việc đã xóa mềm
  Future<void> restoreTask(String taskId) async {
    try {
      await _database.child('tasks').child(taskId).update({'isDeleted': false});
    } catch (e) {
      throw e;
    }
  }

  // Xóa vĩnh viễn công việc (xóa node khỏi database)
  Future<void> deleteTaskPermanently(String taskId) async {
    try {
      await _database.child('tasks').child(taskId).remove();
      await NotificationService().cancelByIdString(taskId);
    } catch (e) {
      throw e;
    }
  }

  // Lấy danh sách công việc theo user
  Stream<List<app_model.Task>> getTasksByUser(String userId) {
    return _database
        .child('tasks')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      Map<dynamic, dynamic>? tasksMap = event.snapshot.value as Map?;
      if (tasksMap == null) return [];
      
      List<app_model.Task> tasks = [];
      tasksMap.forEach((key, value) {
        app_model.Task task = app_model.Task.fromJson(Map<String, dynamic>.from(value));
        task.id = key.toString();
        if (!task.isDeleted) {
          tasks.add(task);
        }
      });
      
      // Sắp xếp theo thời gian kết thúc
      tasks.sort((a, b) => a.endDate.compareTo(b.endDate));
      return tasks;
    });
  }

  // Danh sách công việc trong thùng rác
  Stream<List<app_model.Task>> getDeletedTasks(String userId) {
    return _database
        .child('tasks')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      Map<dynamic, dynamic>? tasksMap = event.snapshot.value as Map?;
      if (tasksMap == null) return [];
      final List<app_model.Task> tasks = [];
      tasksMap.forEach((key, value) {
        final app_model.Task task = app_model.Task.fromJson(Map<String, dynamic>.from(value));
        task.id = key.toString();
        if (task.isDeleted) tasks.add(task);
      });
      tasks.sort((a, b) => b.endDate.compareTo(a.endDate));
      return tasks;
    });
  }

  // Công việc sắp hết hạn (24h tới), chưa bị xóa
  Stream<List<app_model.Task>> getDueSoonTasks(String userId) {
    return getTasksByUser(userId).map((tasks) =>
        tasks.where((t) => t.isDueSoon && !t.isDeleted).toList());
  }

  // Tìm kiếm công việc
  Stream<List<app_model.Task>> searchTasks(String userId, String query) {
    return _database
        .child('tasks')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      Map<dynamic, dynamic>? tasksMap = event.snapshot.value as Map?;
      if (tasksMap == null) return [];
      
      List<app_model.Task> tasks = [];
      tasksMap.forEach((key, value) {
        app_model.Task task = app_model.Task.fromJson(Map<String, dynamic>.from(value));
        task.id = key.toString();
        
        // Tìm kiếm theo tiêu đề hoặc mô tả
        if (!task.isDeleted &&
            (task.title.toLowerCase().contains(query.toLowerCase()) ||
             task.description.toLowerCase().contains(query.toLowerCase()))) {
          tasks.add(task);
        }
      });
      
      tasks.sort((a, b) => a.endDate.compareTo(b.endDate));
      return tasks;
    });
  }

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;
}