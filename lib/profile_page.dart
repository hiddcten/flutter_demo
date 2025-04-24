// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import your AuthPage if needed for navigation, or handle navigation differently
import 'main.dart'; // Assuming AuthPage is in main.dart or import its file

class ProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String name;
  late String phone;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    phone = widget.phone;
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to AuthPage and remove all routes behind it
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      print("Error logging out: $e");
      // Show a snackbar or dialog if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateNameOnFirebase(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Update displayName in Firebase Auth
    await user.updateDisplayName(newName);
    // Update name in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'name': newName});
  }

  Future<void> _updatePhoneOnFirebase(String newPhone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Update phone in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'phone': newPhone});
  }

  Future<void> _showEditDialog({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
    required String labelText,
    TextInputType? keyboardType,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: labelText),
          keyboardType: keyboardType,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    String? errorText;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Mật khẩu hiện tại'),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: confirmPassController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(errorText!,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPassController.text != confirmPassController.text) {
                    setState(() => errorText = 'Mật khẩu mới không khớp');
                    return;
                  }
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    final cred = EmailAuthProvider.credential(
                      email: user!.email!,
                      password: oldPassController.text,
                    );
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newPassController.text);
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'passwordChangedAt': DateTime.now()});
                    if (context.mounted) {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const AuthPage()),
                          (Route<dynamic> route) => false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.')),
                        );
                      }
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'wrong-password' ||
                        e.code == 'user-mismatch' ||
                        e.code == 'invalid-credential') {
                      setState(() => errorText = 'Mật khẩu cũ không chính xác');
                    } else {
                      setState(() =>
                          errorText = 'Đổi mật khẩu thất bại: ${e.message}');
                    }
                  } catch (e) {
                    setState(() =>
                        errorText = 'Đổi mật khẩu thất bại: ${e.toString()}');
                  }
                },
                child: const Text('Đổi'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin tài khoản'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                            fontSize: 30,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildEditableProfileInfoRow(
                    icon: Icons.person_outline,
                    label: 'Họ tên:',
                    value: name,
                    theme: theme,
                    onEdit: () => _showEditDialog(
                      title: 'Đổi họ tên',
                      initialValue: name,
                      labelText: 'Họ tên mới',
                      onSave: (newName) async {
                        if (newName.isNotEmpty) {
                          setState(() => name = newName);
                          await _updateNameOnFirebase(newName);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildProfileInfoRow(
                      Icons.email_outlined, 'Email:', widget.email, theme),
                  const SizedBox(height: 15),
                  _buildEditableProfileInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'SĐT:',
                    value: phone,
                    theme: theme,
                    onEdit: () => _showEditDialog(
                      title: 'Đổi số điện thoại',
                      initialValue: phone,
                      labelText: 'Số điện thoại mới',
                      keyboardType: TextInputType.phone,
                      onSave: (newPhone) async {
                        if (newPhone.isNotEmpty) {
                          setState(() => phone = newPhone);
                          await _updatePhoneOnFirebase(newPhone);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Đổi mật khẩu'),
                      onPressed: _showChangePasswordDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(
      IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 15),
        Text(
          label,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis, // Prevent long text overflow
          ),
        ),
      ],
    );
  }

  Widget _buildEditableProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 15),
        Text(
          label,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          tooltip: 'Chỉnh sửa',
          onPressed: onEdit,
        ),
      ],
    );
  }
}
