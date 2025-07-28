import 'package:flutter/material.dart';
import 'face_recognition_page.dart';
import 'add_user_page.dart';
import 'users_log_page.dart';
import 'recognition_query_page.dart';

class HomePage extends StatelessWidget {
  final Color greenColor = const Color(0xFF57b236);
  final Color borderColor = const Color(0xFF28283f);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yüz Tanıma Sistemi')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          
          return Center(
            child: isLandscape 
                ? _buildLandscapeLayout(context, constraints)
                : _buildPortraitLayout(context, constraints),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, BoxConstraints constraints) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Üstteki Face ID logosu
        Image.asset(
          'assets/face-id.png',
          height: constraints.maxHeight * 0.25,
        ),
        SizedBox(height: constraints.maxHeight * 0.04),

        // 4 Düğme
        _buildButton(
          icon: Icons.face,
          label: 'Yüz Tanıma Yap',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FaceRecognitionPage()),
          ),
          width: constraints.maxWidth * 0.7,
        ),
        SizedBox(height: constraints.maxHeight * 0.016),
        _buildButton(
          icon: Icons.person_add,
          label: 'Kişi Kaydet',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddUserPage()),
          ),
          width: constraints.maxWidth * 0.7,
        ),
        SizedBox(height: constraints.maxHeight * 0.016),
        _buildButton(
          icon: Icons.people,
          label: 'Kullanıcıları Görüntüle',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UsersPage()),
          ),
          width: constraints.maxWidth * 0.7,
        ),
        SizedBox(height: constraints.maxHeight * 0.016),
        _buildButton(
          icon: Icons.search,
          label: 'Tanıma Sorgula',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecognitionQueryPage()),
          ),
          width: constraints.maxWidth * 0.7,
        ),

        SizedBox(height: constraints.maxHeight * 0.06),

        // Alt logo
        Image.asset(
          'assets/logo.png',
          height: constraints.maxHeight * 0.03,
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, BoxConstraints constraints) {
    return Row(
      children: [
        // Sol taraf - Logo
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/face-id.png',
                height: constraints.maxHeight * 0.4,
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              Image.asset(
                'assets/logo.png',
                height: constraints.maxHeight * 0.05,
              ),
            ],
          ),
        ),
        
        // Sağ taraf - Butonlar
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                icon: Icons.face,
                label: 'Yüz Tanıma Yap',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FaceRecognitionPage()),
                ),
                width: constraints.maxWidth * 0.25,
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              _buildButton(
                icon: Icons.person_add,
                label: 'Kişi Kaydet',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddUserPage()),
                ),
                width: constraints.maxWidth * 0.25,
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              _buildButton(
                icon: Icons.people,
                label: 'Kullanıcıları Görüntüle',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersPage()),
                ),
                width: constraints.maxWidth * 0.25,
              ),
              SizedBox(height: constraints.maxHeight * 0.02),
              _buildButton(
                icon: Icons.search,
                label: 'Tanıma Sorgula',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecognitionQueryPage()),
                ),
                width: constraints.maxWidth * 0.25,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required double width,
  }) {
    return SizedBox(
      width: width,
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}