import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'face_recognition_page.dart';
import 'add_user_page.dart';
import 'users_log_page.dart';
import 'recognition_query_page.dart';
import '../services/face_api_services.dart';

class HomePage extends StatelessWidget {
  final Color greenColor = const Color(0xFF57b236);
  final Color borderColor = const Color(0xFF28283f);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
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
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Üstteki Face ID logosu
            Image.asset(
              'assets/face3.png',
              height: constraints.maxHeight * 0.5,
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

            SizedBox(height: constraints.maxHeight * 0.03),

            // Alt logo
            Image.asset(
              'assets/logo.png',
              height: constraints.maxHeight * 0.03,
            ),
          ],
        ),
        
        // Çıkış butonu
        Positioned(
          top: 16,
          left: 2,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Uygulamadan Çıkış'),
                    content: Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Çıkış'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  SystemNavigator.pop(); // Uygulamadan çıkış
                }
              },
              tooltip: 'Uygulamadan Çıkış',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, BoxConstraints constraints) {
    return Stack(
      children: [
        Row(
          children: [
            // Sol taraf - Logo
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/face3.png',
                    height: constraints.maxHeight * 0.4,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  Image.asset(
                    'assets/logo.png',
                    height: constraints.maxHeight * 0.05,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.1),
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
        ),
        
        // Çıkış butonu (landscape)
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Uygulamadan Çıkış'),
                    content: Text('Uygulamadan çıkmak istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Çıkış'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  SystemNavigator.pop(); // Uygulamadan çıkış
                }
              },
              tooltip: 'Uygulamadan Çıkış',
            ),
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
        icon: Icon(icon, color: Colors.teal),
        label: Text(
          label,
          style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.teal, width: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}