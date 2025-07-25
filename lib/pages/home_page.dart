import 'package:flutter/material.dart';
import 'face_recognition_page.dart';
import 'add_user_page.dart';
import 'users_log_page.dart';

class HomePage extends StatelessWidget {
  final Color greenColor = const Color(0xFF57b236);
  final Color borderColor = const Color(0xFF28283f);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yüz Tanıma Sistemi')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Üstteki Face ID logosu
            Image.asset(
              'assets/face-id.png',
              height: 250,
            ),
            const SizedBox(height: 40),

            // 3 Düğme
            _buildButton(
              icon: Icons.face,
              label: 'Yüz Tanıma Yap',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => FaceRecognitionPage()),
              ),
            ),
            const SizedBox(height: 16),
            _buildButton(
              icon: Icons.person_add,
              label: 'Kişi Kaydet',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddUserPage()),
              ),
            ),
            const SizedBox(height: 16),
            _buildButton(
              icon: Icons.people,
              label: 'Kullanıcıları Görüntüle',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UsersPage()),
              ),
            ),

            const SizedBox(height: 60),

            // Alt logo
            Image.asset(
              'assets/logo.png',
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 260,
      height: 50,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: greenColor),
        label: Text(
          label,
          style: TextStyle(color: greenColor, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: borderColor, width: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Daha dikdörtgen
          ),
        ),
      ),
    );
  }
}