import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello: $name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Email: $email', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('SĐT: $phone', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 32),
                SizedBox(
                  width: 180,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.logout, size: 20, color: Colors.white),
                    label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935), // Red Google style
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0x33E53935),
                    ).copyWith(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => states.contains(MaterialState.hovered) ? Colors.redAccent.withOpacity(0.15) : null,
                      ),
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
