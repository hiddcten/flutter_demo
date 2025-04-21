// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import your AuthPage if needed for navigation, or handle navigation differently
import 'main.dart'; // Assuming AuthPage is in main.dart or import its file

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  // final String? uid; // Optional: if you need the UID on this page

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    // this.uid,
  });

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
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
                        style: TextStyle(fontSize: 30, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildProfileInfoRow(Icons.person_outline, 'Họ tên:', name, theme),
                  const SizedBox(height: 15),
                   _buildProfileInfoRow(Icons.email_outlined, 'Email:', email, theme),
                  const SizedBox(height: 15),
                  _buildProfileInfoRow(Icons.phone_outlined, 'SĐT:', phone, theme),
                  // Add other info if needed
                  // const SizedBox(height: 20),
                  // Center(
                  //   child: ElevatedButton.icon(
                  //     icon: const Icon(Icons.logout),
                  //     label: const Text('Đăng xuất'),
                  //     onPressed: () => _logout(context),
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colors.redAccent,
                  //       foregroundColor: Colors.white,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 15),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
}