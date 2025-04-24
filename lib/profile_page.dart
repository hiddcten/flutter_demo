import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'main.dart'; 

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (Route<dynamic> route) => false, 
      );
    } catch (e) {
      print("Error logging out: $e");
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

  Future<double?> _addNumbersWithCloudFunction(num a, num b) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'asia-east2').httpsCallable('addNumbers');
      final result = await callable.call({'a': a, 'b': b});
      if (result.data is Map && result.data['result'] != null) {
        return (result.data['result'] as num).toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
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
                      icon: const Icon(Icons.lock_reset, color: Colors.white),
                      label: const Text('Đổi mật khẩu'),
                      onPressed: _showChangePasswordDialog,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Cloud Function demo cộng hai số
                  const Divider(),
                  const Text('Demo Cloud Function cộng hai số',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _CloudAddNumbersDemo(addNumbers: _addNumbersWithCloudFunction),
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
            overflow: TextOverflow.ellipsis, 
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

class _CloudAddNumbersDemo extends StatefulWidget {
  final Future<double?> Function(num, num) addNumbers;

  const _CloudAddNumbersDemo({Key? key, required this.addNumbers})
      : super(key: key);

  @override
  State<_CloudAddNumbersDemo> createState() => _CloudAddNumbersDemoState();
}

class _CloudAddNumbersDemoState extends State<_CloudAddNumbersDemo> {
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _aController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số thứ nhất'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số thứ hai'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            final a = num.tryParse(_aController.text);
            final b = num.tryParse(_bController.text);
            if (a != null && b != null) {
              final result = await widget.addNumbers(a, b);
              setState(() {
                _result = result != null ? 'Kết quả: $result' : 'Lỗi khi gọi Cloud Function';
              });
            } else {
              setState(() {
                _result = 'Vui lòng nhập số hợp lệ';
              });
            }
          },
          child: const Text('Cộng hai số'),
        ),
        if (_result != null) ...[
          const SizedBox(height: 10),
          Text(_result!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }
}
