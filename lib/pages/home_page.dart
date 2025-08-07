import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'face_recognition_page.dart';
import 'add_user_page.dart';
import 'users_log_page.dart';
import 'recognition_query_page.dart';
import '../services/face_api_services.dart';
import '../services/connectivity_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color greenColor = const Color(0xFF57b236);
  final Color borderColor = const Color(0xFF28283f);
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _connectivityService.startListening();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _checkInternetConnection() async {
    final isConnected = await _connectivityService.checkInternetConnection();
    if (!isConnected && mounted) {
      setState(() {
        _isConnected = false;
      });
      ConnectivityService.showNoInternetDialog(context);
    } else {
      setState(() {
        _isConnected = true;
      });
    }
  }

  void _navigateWithInternetCheck(VoidCallback navigation) async {
    final isConnected = await _connectivityService.checkInternetConnection();
    if (!isConnected) {
      ConnectivityService.showNoInternetSnackBar(context);
      return;
    }
    navigation();
  }

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
              onPressed: () => _navigateWithInternetCheck(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FaceRecognitionPage()),
                );
              }),
              width: constraints.maxWidth * 0.7,
            ),
            SizedBox(height: constraints.maxHeight * 0.016),
            _buildButton(
              icon: Icons.person_add,
              label: 'Kişi Kaydet',
              onPressed: () => _navigateWithInternetCheck(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddUserPage()),
                );
              }),
              width: constraints.maxWidth * 0.7,
            ),
            SizedBox(height: constraints.maxHeight * 0.016),
            _buildButton(
              icon: Icons.people,
              label: 'Kullanıcıları Görüntüle',
              onPressed: () => _navigateWithInternetCheck(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersPage()),
                );
              }),
              width: constraints.maxWidth * 0.7,
            ),
            SizedBox(height: constraints.maxHeight * 0.016),
            _buildButton(
              icon: Icons.search,
              label: 'Tanıma Sorgula',
              onPressed: () => _navigateWithInternetCheck(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecognitionQueryPage()),
                );
              }),
              width: constraints.maxWidth * 0.7,
            ),

            SizedBox(height: constraints.maxHeight * 0.03),
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

        // İnternet bağlantısı uyarısı (üstte)
        if (!_isConnected)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İnternet bağlantısı yok!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkInternetConnection,
                    child: Text(
                      'Tekrar Dene',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
                    onPressed: () => _navigateWithInternetCheck(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FaceRecognitionPage()),
                      );
                    }),
                    width: constraints.maxWidth * 0.25,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  _buildButton(
                    icon: Icons.person_add,
                    label: 'Kişi Kaydet',
                    onPressed: () => _navigateWithInternetCheck(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddUserPage()),
                      );
                    }),
                    width: constraints.maxWidth * 0.25,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  _buildButton(
                    icon: Icons.people,
                    label: 'Kullanıcıları Görüntüle',
                    onPressed: () => _navigateWithInternetCheck(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UsersPage()),
                      );
                    }),
                    width: constraints.maxWidth * 0.25,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  _buildButton(
                    icon: Icons.search,
                    label: 'Tanıma Sorgula',
                    onPressed: () => _navigateWithInternetCheck(() {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RecognitionQueryPage()),
                      );
                    }),
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

        // İnternet bağlantısı uyarısı (landscape - üstte)
        if (!_isConnected)
          Positioned(
            top: 16,
            left: 16,
            right: 200, // Çıkış butonunun solunda
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'İnternet bağlantısı yok!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkInternetConnection,
                    child: Text(
                      'Tekrar Dene',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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