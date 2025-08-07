import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  // İnternet bağlantısı durumunu dinlemeye başla
  void startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _isConnected = result != ConnectivityResult.none;
        print('🌐 İnternet bağlantısı durumu: ${_isConnected ? 'Bağlı' : 'Bağlantı yok'}');
      },
      onError: (error) {
        print('❌ İnternet bağlantısı kontrol hatası: $error');
        _isConnected = false;
      },
    );
  }

  // İnternet bağlantısını kontrol et
  Future<bool> checkInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result != ConnectivityResult.none;
      return _isConnected;
    } catch (e) {
      print('❌ İnternet bağlantısı kontrol hatası: $e');
      _isConnected = false;
      return false;
    }
  }

  // İnternet bağlantısı uyarısı göster
  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.red,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'İnternet Bağlantısı Yok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uygulama çalışması için internet bağlantısı gereklidir.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Lütfen:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Wi-Fi bağlantınızı kontrol edin'),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Mobil veri bağlantınızı kontrol edin'),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Uygulamayı yeniden başlatın'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Tamam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // İnternet bağlantısını tekrar kontrol et
                final isConnected = await ConnectivityService().checkInternetConnection();
                if (!isConnected) {
                  showNoInternetDialog(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Tekrar Dene',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // İnternet bağlantısı uyarısı (SnackBar)
  static void showNoInternetSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'İnternet bağlantısı yok! Lütfen bağlantınızı kontrol edin.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Tekrar Dene',
          textColor: Colors.white,
          onPressed: () async {
            final isConnected = await ConnectivityService().checkInternetConnection();
            if (!isConnected) {
              showNoInternetSnackBar(context);
            }
          },
        ),
      ),
    );
  }

  // Dinlemeyi durdur
  void dispose() {
    _connectivitySubscription?.cancel();
  }
} 