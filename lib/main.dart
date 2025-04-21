// main.dart
import 'package:flutter/material.dart';
import 'profile_page.dart'; // Make sure this import is correct

// --- Firebase Imports ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp setup remains the same...
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
      // Optional: Auth State Listener (Recommended for robust navigation)
      // home: StreamBuilder<User?>( ... ),
       home: const AuthPage(), // Keep using AuthPage as entry for now
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

  // Firebase Instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

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

  // --- Updated handleAuth function ---
  Future<void> _handleAuth() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();

    // Basic validation... (keep existing validation)
    if (email.isEmpty || password.isEmpty) {
       setState(() { _error = 'Email và Mật khẩu không được để trống.'; _isLoading = false; }); return;
    }
    if (!_isLogin && (name.isEmpty || phone.isEmpty)) {
       setState(() { _error = 'Họ tên và SĐT không được để trống khi đăng ký.'; _isLoading = false; }); return;
    }

    try {
      UserCredential userCredential;

      if (_isLogin) {
        // --- LOGIN ---
        print('Attempting login for: $email');
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print("Signed in successfully: ${userCredential.user?.uid}");

        // --- Fetch user data from Firestore ---
        await _fetchDataAndNavigate(userCredential.user!); // Pass the user object

      // --- START: REGISTER block with added print statements ---
      } else {
        // --- REGISTER ---
        print('BẮT ĐẦU QUÁ TRÌNH ĐĂNG KÝ CHO: $email'); // <-- ADDED PRINT
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        final User? newUser = userCredential.user;
        print("Đăng ký Auth thành công! User ID: ${newUser?.uid}"); // <-- ADDED PRINT

        if (newUser != null) {
          // --- Save user data to Firestore ---
          print("CHUẨN BỊ LƯU DỮ LIỆU VÀO FIRESTORE CHO UID: ${newUser.uid}"); // <-- ADDED PRINT
          try {
            await _firestore.collection('users').doc(newUser.uid).set({ // <-- POINT TO CHECK
              'name': name,
              'email': email,
              'phone': phone,
              'createdAt': FieldValue.serverTimestamp(),
            });
             print("LƯU FIRESTORE THÀNH CÔNG!"); // <-- ADDED PRINT
          } catch (firestoreError) {
             print("!!! LỖI KHI LƯU VÀO FIRESTORE: $firestoreError"); // <-- ADDED PRINT (Very important)
             // Keep the setState for error feedback to the user
             if(mounted) {
               setState(() {
                 _error = "Đăng ký thành công nhưng có lỗi lưu thông tin.";
               });
             }
          }

           // Update Auth display name (optional but good practice)
           try {
              await newUser.updateDisplayName(name);
              print("Updated Auth display name.");
           } catch (profileError) {
               print("Error updating Auth display name: $profileError");
           }


          // Navigate after registration and saving data
          // Pass the data directly since we just got it from controllers
          _navigateToProfile(name, email, phone);

        } else {
           print("!!! LỖI: User mới tạo là null sau khi createUserWithEmailAndPassword"); // <-- ADDED PRINT
           // Throwing an exception here might be too harsh, setting an error state might be better
           if (mounted) {
              setState(() {
                 _error = "Lỗi tạo tài khoản, không nhận được thông tin người dùng.";
              });
           }
           // Consider not throwing here unless you have specific handling higher up
           // throw Exception("User creation resulted in null user object.");
        }
      }
      // --- END: REGISTER block with added print statements ---

    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          // Use existing user-friendly error messages
          switch (e.code) {
             case 'user-not-found': _error = 'Không tìm thấy người dùng với email này.'; break;
             case 'wrong-password': _error = 'Sai mật khẩu.'; break;
             case 'invalid-email': _error = 'Định dạng email không hợp lệ.'; break;
             case 'email-already-in-use': _error = 'Email này đã được sử dụng.'; break;
             case 'weak-password': _error = 'Mật khẩu quá yếu.'; break;
             case 'invalid-credential': _error = 'Thông tin đăng nhập không đúng.'; break;
             default: _error = e.message ?? 'Lỗi xác thực không xác định.';
          }
        });
      }
    } catch (e) {
      print('Unexpected error during auth/Firestore: $e');
      if (mounted) {
        setState(() {
          _error = 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Helper to Fetch Firestore data on Login ---
  Future<void> _fetchDataAndNavigate(User user) async {
      if (!mounted) return;
      print("Fetching Firestore data for UID: ${user.uid}");

      try {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

          if (userDoc.exists && userDoc.data() != null) {
              final data = userDoc.data() as Map<String, dynamic>;
              final String name = data['name'] ?? user.displayName ?? 'N/A'; // Fallback
              final String email = data['email'] ?? user.email ?? 'N/A'; // Fallback
              final String phone = data['phone'] ?? 'N/A'; // Fallback

              print("Data fetched: Name=$name, Email=$email, Phone=$phone");
              _navigateToProfile(name, email, phone); // Navigate with fetched data

          } else {
              print("User document not found in Firestore for UID: ${user.uid}");
              // Handle case where user exists in Auth but not Firestore
              if (mounted) {
                setState(() {
                 _error = "Không tìm thấy thông tin chi tiết người dùng.";
                });
              }
               // Optionally navigate with default data
               // _navigateToProfile(user.displayName ?? 'User', user.email ?? 'N/A', 'N/A');
          }
      } catch(e) {
           print("Error fetching Firestore data: $e");
            if (mounted) {
              setState(() {
                 _error = "Lỗi khi tải thông tin người dùng.";
              });
              // Optionally navigate with default data
              // _navigateToProfile(user.displayName ?? 'User', user.email ?? 'N/A', 'N/A');
            }
      }
  }


  // --- Updated Navigation Helper ---
  void _navigateToProfile(String name, String email, String phone) {
     if (!mounted) return;

     print("Navigating to Profile Page with: Name=$name, Email=$email, Phone=$phone");
     Navigator.of(context).pushReplacement( // Use pushReplacement
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            name: name,
            email: email,
            phone: phone,
          ),
        ),
      );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- Build method remains largely the same ---
    // Ensure it uses _isLoading, _error, and calls _handleAuth
    // Keep the SingleChildScrollView and layout structure
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      _isLogin ? 'Đăng nhập' : 'Đăng ký', // Updated Title
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- Registration Fields ---
                  if (!_isLogin) ...[
                    TextField( controller: _nameController, decoration: const InputDecoration( labelText: 'Họ tên', prefixIcon: Icon(Icons.person_outline, color: Color(0xFF1A73E8)), ), textCapitalization: TextCapitalization.words, enabled: !_isLoading, ),
                    const SizedBox(height: 18),
                    TextField( controller: _phoneController, decoration: const InputDecoration( labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF1A73E8)), ), keyboardType: TextInputType.phone, enabled: !_isLoading, ),
                    const SizedBox(height: 18),
                  ],
                  // --- Common Fields ---
                  TextField( controller: _emailController, decoration: const InputDecoration( labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF1A73E8)), ), keyboardType: TextInputType.emailAddress, enabled: !_isLoading, ),
                  const SizedBox(height: 18),
                  TextField( controller: _passwordController, decoration: const InputDecoration( labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF1A73E8)), ), obscureText: true, enabled: !_isLoading, ),
                  // --- Error Display ---
                  AnimatedOpacity(
                    opacity: _error != null ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: _error != null
                        ? Padding( padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text( _error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13.5), textAlign: TextAlign.center, ), )
                        : const SizedBox(height: 18), // Keep consistent spacing
                  ),
                  // --- Submit Button ---
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A73E8), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(14), ),
                        elevation: _isLoading ? 2 : 6, shadowColor: const Color(0x331A73E8),
                        disabledBackgroundColor: const Color(0xFF1A73E8).withOpacity(0.6),
                        disabledForegroundColor: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: _isLoading ? null : _handleAuth,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                        child: _isLoading
                            ? const SizedBox( key: ValueKey('loader'), width: 24, height: 24, child: CircularProgressIndicator( strokeWidth: 2.5, color: Colors.white, ), )
                            : Text( _isLogin ? 'Đăng nhập' : 'Đăng ký', key: ValueKey(_isLogin ? 'login_text' : 'register_text'), style: const TextStyle( fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.8, ), ),
                      ),
                    ),
                  ),
                  // --- Switch between Login/Register ---
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isLogin ? 'Chưa có tài khoản?' : 'Đã có tài khoản?'),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                           if (!mounted) return;
                          setState(() {
                            _isLogin = !_isLogin; _error = null; _controller.reset(); _controller.forward();
                            // Clear fields on switch for better UX
                            _emailController.clear(); _passwordController.clear();
                            _nameController.clear(); _phoneController.clear();
                          });
                        },
                        style: TextButton.styleFrom( foregroundColor: const Color(0xFF1A73E8), textStyle: const TextStyle(fontWeight: FontWeight.bold), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, ),
                        child: Text(_isLogin ? 'Đăng ký' : 'Đăng nhập'),
                      ),
                    ],
                  ),
                   const SizedBox(height: 6),
                   const Text( '© 2024 Firebase Firestore Demo', textAlign: TextAlign.center, style: TextStyle( color: Color(0xFFB0B4BA), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2, ), ), // Updated footer text
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}