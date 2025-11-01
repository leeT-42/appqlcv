import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import 'task_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseService _authService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  String _errorMessage = '';

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Attempting ${_isLogin ? 'login' : 'signup'} with: ${_emailController.text}');
      
      User? user;
      if (_isLogin) {
        user = await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        user = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }

      print('Auth result: $user');
      
      if (user != null) {
        print('User UID: ${user.uid}');
        print('User email: ${user.email}');
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TaskListScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Đăng nhập thất bại: user null';
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorText = 'Có lỗi xảy ra';
      
      switch (e.code) {
        case 'invalid-email':
          errorText = 'Email không hợp lệ';
          break;
        case 'user-disabled':
          errorText = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'user-not-found':
          errorText = 'Không tìm thấy tài khoản';
          break;
        case 'wrong-password':
          errorText = 'Sai mật khẩu';
          break;
        case 'email-already-in-use':
          errorText = 'Email đã được sử dụng';
          break;
        case 'weak-password':
          errorText = 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
          break;
        case 'operation-not-allowed':
          errorText = 'Phương thức đăng nhập không được kích hoạt';
          break;
        default:
          errorText = 'Lỗi: ${e.code} - ${e.message}';
      }
      
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      
      if (mounted) {
        setState(() {
          _errorMessage = errorText;
        });
      }
    } catch (e) {
      print('General error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi không xác định: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskListScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi Google: ${e.message ?? e.code}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi Google: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  hintText: 'Ít nhất 6 ký tự',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
                    ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginWithGoogle,
                      icon: Icon(Icons.g_mobiledata),
                      label: Text('Google'),
                    ),
                  ),
                  
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _errorMessage = '';
                        });
                      },
                child: Text(_isLogin
                    ? 'Chưa có tài khoản? Đăng ký'
                    : 'Đã có tài khoản? Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}