import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            shadowColor: const Color(0x221A73E8),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLogin = true;
  String? _error;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _isLoading = false;
      _error = null;
    });
    // Điều hướng sang trang Profile sau khi đăng nhập/đăng ký
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          name: _isLogin ? 'User' : _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _isLogin ? '0123456789' : _phoneController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: child,
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    _isLogin ? 'Login' : 'Register',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A73E8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên',
                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1A73E8)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF1A73E8)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1A73E8)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF1A73E8)),
                  ),
                  obscureText: true,
                ),
                AnimatedOpacity(
                  opacity: _error != null ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 28),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 6,
                      shadowColor: const Color(0x331A73E8),
                    ),
                    onPressed: _isLoading ? null : _handleAuth,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _isLoading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Đăng nhập' : 'Đăng ký',
                              key: ValueKey(_isLogin),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?'),
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _controller.reset();
                          _controller.forward();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1A73E8),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: Text(_isLogin ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 800),
                  child: const Text(
                    '© 2025 Google UI Inspired',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFB0B4BA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
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
