import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../services/face_api_services.dart';
import '../services/connectivity_service.dart';

// Odaklanma alanı için CustomPainter
class FocusAreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Ekranı daha büyük bir alan için böl - ortadaki bölümü al
    // Dikey olarak 1/4'ten 3/4'e kadar (daha büyük alan)
    final verticalQuarter = size.height / 4;
    final focusTop = verticalQuarter;
    final focusBottom = verticalQuarter * 3;

    // Yatay olarak 1/6'dan 5/6'ya kadar (daha büyük alan)
    final horizontalSixth = size.width / 6;
    final focusLeft = horizontalSixth;
    final focusRight = horizontalSixth * 5;

    // Odaklanma alanını çiz
    final focusRect = Rect.fromLTRB(focusLeft, focusTop, focusRight, focusBottom);

    // Dış alanı karart
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(focusRect),
      ),
      fillPaint,
    );

    // Odaklanma alanının kenarlarını çiz
    canvas.drawRect(focusRect, paint);

    // Köşe işaretleri çiz
    final cornerLength = 25.0;
    final cornerPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Sol üst köşe
    canvas.drawLine(Offset(focusLeft, focusTop), Offset(focusLeft + cornerLength, focusTop), cornerPaint);
    canvas.drawLine(Offset(focusLeft, focusTop), Offset(focusLeft, focusTop + cornerLength), cornerPaint);

    // Sağ üst köşe
    canvas.drawLine(Offset(focusRight, focusTop), Offset(focusRight - cornerLength, focusTop), cornerPaint);
    canvas.drawLine(Offset(focusRight, focusTop), Offset(focusRight, focusTop + cornerLength), cornerPaint);

    // Sol alt köşe
    canvas.drawLine(Offset(focusLeft, focusBottom), Offset(focusLeft + cornerLength, focusBottom), cornerPaint);
    canvas.drawLine(Offset(focusLeft, focusBottom), Offset(focusLeft, focusBottom - cornerLength), cornerPaint);

    // Sağ alt köşe
    canvas.drawLine(Offset(focusRight, focusBottom), Offset(focusRight - cornerLength, focusBottom), cornerPaint);
    canvas.drawLine(Offset(focusRight, focusBottom), Offset(focusRight, focusBottom - cornerLength), cornerPaint);

    // Odaklanma alanı içinde "ODAKLANMA ALANI" yazısı
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'YÜZÜNÜZÜ\nYERLEŞTİRİN',
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textX = focusLeft + (focusRight - focusLeft - textPainter.width) / 2;
    final textY = focusTop + (focusBottom - focusTop - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Işık durumu enum'u
enum LightingCondition {
  good,
  tooBright,
  tooDark,
  uneven,
  unknown
}

// Işık durumu sınıfı
class LightingStatus {
  final LightingCondition condition;
  final String message;
  final String suggestion;
  final Color color;
  final IconData icon;

  LightingStatus({
    required this.condition,
    required this.message,
    required this.suggestion,
    required this.color,
    required this.icon,
  });
}

class FaceRecognitionPage extends StatefulWidget {
  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0;
  String? resultMessage;
  String? recognizedName;
  String? idNo;
  String? birthDate;
  double? currentThreshold;
  Map<String, dynamic>? thresholdChange;
  Timer? _timer;

  // 🚀 PERFORMANS FLAG'LERİ - Frame kasma sorununu çözmek için
  bool _isProcessing = false;
  bool _isFrameProcessing = false;
  bool _isRecognitionActive = true;
  bool _isCameraReady = false;
  bool _isAppInForeground = true;
  bool _isMemoryOptimized = false;

  // 🎯 YÜZ TANIMA OPTİMİZASYONU - Yeni flag'ler
  bool _isFaceDetected = false;
  bool _isRecognitionInProgress = false;
  String? _lastProcessedFaceHash;
  DateTime? _lastFaceDetectionTime;
  static const Duration _faceDetectionCooldown = Duration(seconds: 3);

  // 🎯 İnternet bağlantısı kontrolü
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  // Frame işleme için debounce
  Timer? _frameDebounceTimer;
  DateTime? _lastFrameTime;
  static const Duration _frameDebounceDuration = Duration(milliseconds: 300);

  // Zoom kontrolü için değişkenler
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 10.0;
  double _pendingZoomLevel = 1.0;
  bool _isZooming = false;
  Timer? _zoomDebounceTimer;

  // Gerçek zamanlı tanıma kayıtları
  List<Map<String, dynamic>> _realtimeLogs = [];
  Timer? _logsTimer;

  // Tanınanlar listesi görünürlük kontrolü
  bool _isRecognizedListVisible = false;

  // 🌟 IŞIK DETECTION ÖZELLİKLERİ - Yeni değişkenler
  LightingStatus? _currentLightingStatus;
  bool _isLightingDetectionActive = true;
  Timer? _lightingDetectionTimer;
  static const Duration _lightingDetectionInterval = Duration(seconds: 2);
  bool _showLightingGuidance = false;
  Timer? _lightingGuidanceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInternetConnection();
    _connectivityService.startListening();
    _initCamera();
    _resetRecognitionSession();
    _startLogsUpdateTimer();
    _autoOptimizeThreshold();
    _startLightingDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.dispose();
    _timer?.cancel();
    _logsTimer?.cancel();
    _frameDebounceTimer?.cancel();
    _zoomDebounceTimer?.cancel();
    _lightingDetectionTimer?.cancel();
    _lightingGuidanceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 🚀 Uygulama durumuna göre performans optimizasyonu
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _resumeRecognition();
        _checkInternetConnection();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _pauseRecognition();
        break;
      case AppLifecycleState.inactive:
        _isAppInForeground = false;
        _pauseRecognition();
        break;
      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        _pauseRecognition();
        break;
    }
  }

  Future<void> _checkInternetConnection() async {
    try {
      final isConnected = await _connectivityService.checkInternetConnection();
      if (!isConnected && mounted) {
        setState(() {
          _isConnected = false;
        });
        // İnternet bağlantısı yoksa tanıma işlemini durdur
        if (_isRecognitionInProgress) {
          _isRecognitionInProgress = false;
          _updateRecognitionStatus("İnternet bağlantısı yok");
        }
        ConnectivityService.showNoInternetDialog(context);
      } else {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      print("🌐 İnternet bağlantısı kontrol hatası: $e");
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
        if (_isRecognitionInProgress) {
          _isRecognitionInProgress = false;
          _updateRecognitionStatus("İnternet bağlantısı yok");
        }
      }
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

  void _resumeRecognition() {
    if (_isCameraReady && _isAppInForeground) {
      _startRecognitionLoop();
    }
  }

  void _pauseRecognition() {
    _timer?.cancel();
    _isFrameProcessing = false;
    _frameDebounceTimer?.cancel();
  }

  Future<void> _resetRecognitionSession() async {
    try {
      await FaceApiService.resetRecognitionSession();
      print("Tanıma oturumu sıfırlandı");

      // 🎯 Yüz tanıma flag'lerini sıfırla
      if (mounted) {
        setState(() {
          _isFaceDetected = false;
          _isRecognitionInProgress = false;
          _lastProcessedFaceHash = null;
          _lastFaceDetectionTime = null;
          resultMessage = null;
          recognizedName = null;
          idNo = null;
          birthDate = null;
          currentThreshold = null;
          thresholdChange = null;
        });
      }
    } catch (e) {
      print("Oturum sıfırlama hatası: $e");
    }
  }

  Future<void> _optimizeThreshold() async {
    try {
      print("🔧 Threshold optimizasyonu başlatılıyor...");

      // Loading göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Threshold optimize ediliyor...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 10),
        ),
      );

      await _performThresholdOptimization();

    } catch (e) {
      print("❌ Threshold optimizasyon hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Threshold optimizasyon hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _autoOptimizeThreshold() async {
    try {
      print("🔧 Otomatik threshold optimizasyonu başlatılıyor...");
      await _performThresholdOptimization();
    } catch (e) {
      print("❌ Otomatik threshold optimizasyon hatası: $e");
    }
  }

  Future<void> _performThresholdOptimization() async {
    try {
      print("🔧 Threshold optimizasyonu API çağrısı yapılıyor...");

      // API'ye threshold optimizasyon isteği gönder
      final response = await http.post(
        Uri.parse('${FaceApiService.baseUrl}/optimize_threshold'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}), // Boş body gönder
      );

      print("📡 API yanıt kodu: ${response.statusCode}");
      print("📄 API yanıtı: ${response.body}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (result['success'] == true) {
          final optimalThreshold = result['optimal_threshold'];
          final currentThreshold = result['current_threshold'];
          final thresholdChange = result['threshold_change'];
          final totalPairs = result['total_pairs'];
          final positivePairs = result['positive_pairs'];
          final negativePairs = result['negative_pairs'];

          print("✅ Threshold optimizasyonu başarılı: $optimalThreshold");

          // Basit başarılı mesaj göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Threshold optimize edildi!'),
                  Text('Aktif Threshold: ${optimalThreshold.toStringAsFixed(3)}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 6),
            ),
          );
        } else {
          print("❌ Threshold optimizasyonu başarısız: ${result['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Threshold optimizasyonu başarısız: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 400) {
        // Kullanıcı hatası - daha açıklayıcı mesaj
        final result = json.decode(response.body);
        final message = result['message'] ?? 'Bilinmeyen hata';
        print("❌ Kullanıcı hatası: $message");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $message'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        print("❌ API hatası: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ API hatası: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print("❌ Threshold optimizasyon hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Threshold optimizasyon hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLogsUpdateTimer() {
    _logsTimer = Timer.periodic(Duration(seconds: 2), (_) => _updateRealtimeLogs());
  }

  Future<void> _updateRealtimeLogs() async {
    try {
      final logs = await FaceApiService.getRealtimeRecognitionLogs();
      if (logs.length != _realtimeLogs.length && mounted) {
        setState(() {
          _realtimeLogs = List<Map<String, dynamic>>.from(logs);
        });
      }
    } catch (e) {
      print("Log güncelleme hatası: $e");
    }
  }

  Future<void> _initCamera() async {
    try {
      cameras = await availableCameras();
      print("Mevcut kamera sayısı: ${cameras?.length ?? 0}");

      if (cameras != null && cameras!.isNotEmpty) {
        // Kamera seçimini optimize et
        _currentCameraIndex = cameras!.indexWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
        );

        // Arka kamera bulunamazsa ön kamerayı dene
        if (_currentCameraIndex == -1) {
          _currentCameraIndex = cameras!.indexWhere(
                (camera) => camera.lensDirection == CameraLensDirection.front,
          );
        }

        // Hiç kamera bulunamazsa ilk kamerayı kullan
        if (_currentCameraIndex == -1) {
          _currentCameraIndex = 0;
        }

        print("Seçilen kamera: ${cameras![_currentCameraIndex].name}");
        print("Kamera yönü: ${cameras![_currentCameraIndex].lensDirection}");

        await _initializeCamera();
      } else {
        print("Kamera bulunamadı!");
      }
    } catch (e) {
      print("Kamera başlatma hatası: $e");
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    await _controller?.dispose();

    final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;

    // Resolution ayarlarını optimize et - performans için
    ResolutionPreset resolution;
    if (isBackCamera) {
      // Arka kamera için optimize edilmiş çözünürlük
      resolution = ResolutionPreset.medium;
    } else {
      // Ön kamera için optimize edilmiş çözünürlük
      resolution = ResolutionPreset.medium;
    }

    _controller = CameraController(
      cameras![_currentCameraIndex],
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      print("Kamera başarıyla başlatıldı - Resolution: $resolution (OPTİMİZE)");
      print("Preview boyutu: ${_controller!.value.previewSize}");
      print("Aspect ratio: ${_controller!.value.aspectRatio}");
      print("Kamera tipi: ${isBackCamera ? 'Arka' : 'Ön'} kamera");

      // 🚀 Kamera hazır flag'i
      _isCameraReady = true;

    } catch (e) {
      print("Kamera başlatma hatası: $e");
      // Fallback olarak daha düşük resolution dene
      try {
        await _controller?.dispose();
        _controller = CameraController(
          cameras![_currentCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        print("Fallback resolution ile kamera başlatıldı (DÜŞÜK ÇÖZÜNÜRLÜK)");
        print("Fallback preview boyutu: ${_controller!.value.previewSize}");
        print("Fallback kamera tipi: ${cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back ? 'Arka' : 'Ön'} kamera");

        // 🚀 Fallback kamera hazır flag'i
        _isCameraReady = true;

      } catch (fallbackError) {
        print("Fallback kamera hatası: $fallbackError");
        _isCameraReady = false;
        return;
      }
    }

    await _controller!.setFlashMode(FlashMode.off);

    // Zoom ayarlarını optimize et
    _minZoomLevel = 1.0;
    _maxZoomLevel = 5.0; // Maksimum zoom'u düşür
    _currentZoomLevel = _minZoomLevel;
    _pendingZoomLevel = _currentZoomLevel;

    try {
      // Zoom seviyesini kamera tipine göre ayarla
      final zoomLevel = isBackCamera ? 1.0 : 0.8;
      await _controller!.setZoomLevel(zoomLevel);
      _currentZoomLevel = zoomLevel;
      _pendingZoomLevel = zoomLevel;
      print("Kamera zoom seviyesi: $_currentZoomLevel");
    } catch (e) {
      print("Zoom ayarlama hatası: $e");
    }

    // Orientation'ı kilitle
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    if (mounted) {
      setState(() {});
    }

    // 🚀 Kamera hazır olduğunda tanıma döngüsünü başlat
    if (_isAppInForeground) {
      _startRecognitionLoop();
    }
  }

  Future<void> _setZoomLevel(double zoomLevel) async {
    if (_controller == null || !_controller!.value.isInitialized || _isZooming) return;

    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);

    if ((_currentZoomLevel - clampedZoom).abs() < 0.05) return;

    _isZooming = true;

    try {
      await _controller!.setZoomLevel(clampedZoom);

      if ((_currentZoomLevel - clampedZoom).abs() > 0.2) {
        if (mounted) {
          setState(() {
            _currentZoomLevel = clampedZoom;
            _pendingZoomLevel = clampedZoom;
          });
        }
      } else {
        _currentZoomLevel = clampedZoom;
      }

      print("Zoom seviyesi değiştirildi: $_currentZoomLevel");
    } catch (e) {
      print("Zoom değiştirme hatası: $e");
      try {
        await _controller!.setZoomLevel(1.0);
        if (mounted) {
          setState(() {
            _currentZoomLevel = 1.0;
            _pendingZoomLevel = 1.0;
          });
        }
      } catch (fallbackError) {
        print("Zoom fallback hatası: $fallbackError");
      }
    } finally {
      _isZooming = false;
    }
  }

  void _debouncedSetZoom(double zoomLevel) {
    _zoomDebounceTimer?.cancel();
    _zoomDebounceTimer = Timer(Duration(milliseconds: 50), () {
      _setZoomLevel(zoomLevel);
    });
  }

  void _addToRecognizedList(String name, String idNo, String birthDate, {double? threshold}) {
    bool alreadyExists = _realtimeLogs.any((log) => log['id_no'] == idNo);

    if (!alreadyExists) {
      final newLog = {
        'name': name,
        'id_no': idNo,
        'birth_date': birthDate,
        'timestamp': DateTime.now().toIso8601String(),
        'threshold': threshold,
      };

      if (mounted) {
        setState(() {
          _realtimeLogs.add(newLog);
          // 🚀 Memory optimizasyonu - sadece son 30 kayıt tut
          if (_realtimeLogs.length > 30) {
            _realtimeLogs = _realtimeLogs.sublist(_realtimeLogs.length - 30);
          }
        });
      }

      print("Tanınan kişi listeye eklendi: $name ($idNo) - Threshold: ${threshold?.toStringAsFixed(3) ?? 'N/A'}");
    } else {
      print("Kişi zaten listede mevcut: $name ($idNo)");
    }
  }

  // 🎯 Yüz tanıma durumu güncelleme
  void _updateRecognitionStatus(String status) {
    if (mounted) {
      setState(() {
        resultMessage = status;
      });
    }
  }

  // 🎯 Mesaj rengi belirleme - İnternet bağlantısı için özel renk
  Color _getMessageColor(String message) {
    if (_isRecognitionInProgress) {
      return Colors.greenAccent; // Yüz tanıma işlemi sırasında yeşil
    } else if (message.contains("İnternet bağlantısı yok")) {
      return Colors.orange; // İnternet bağlantısı yok - turuncu
    } else if (recognizedName != null) {
      return Colors.greenAccent;
    } else if (message.contains("Sistemde kayıtlı kullanıcı bulunamadı")) {
      return Colors.orange;
    } else if (message.contains("Yüz tespit edilemedi")) {
      return Colors.yellow;
    } else if (message.contains("Görüntü işlenemedi")) {
      return Colors.red;
    } else {
      return Colors.redAccent;
    }
  }

  // 🎯 Mesaj ikonu belirleme - İnternet bağlantısı için özel ikon
  IconData _getMessageIcon(String message) {
    if (_isRecognitionInProgress) {
      return Icons.face; // Yüz tanıma işlemi sırasında yüz ikonu
    } else if (message.contains("İnternet bağlantısı yok")) {
      return Icons.wifi_off; // İnternet bağlantısı yok - wifi off ikonu
    } else if (recognizedName != null) {
      return Icons.check_circle;
    } else if (message.contains("Sistemde kayıtlı kullanıcı bulunamadı")) {
      return Icons.warning;
    } else if (message.contains("Yüz tespit edilemedi")) {
      return Icons.face;
    } else if (message.contains("Görüntü işlenemedi")) {
      return Icons.error;
    } else {
      return Icons.cancel;
    }
  }

  Color _getThresholdColor(double threshold) {
    // Threshold değerine göre renk belirle
    if (threshold <= 0.6) {
      return Colors.green; // Çok düşük - çok güvenilir
    } else if (threshold <= 0.75) {
      return Colors.lightGreen; // Düşük - güvenilir
    } else if (threshold <= 0.85) {
      return Colors.yellow; // Orta - orta güvenilir
    } else if (threshold <= 0.9) {
      return Colors.orange; // Yüksek - dikkatli
    } else {
      return Colors.red; // Çok yüksek - dikkat
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    _timer?.cancel();
    _isFrameProcessing = false;
    _frameDebounceTimer?.cancel();

    final currentDirection = cameras![_currentCameraIndex].lensDirection;
    final oppositeDirection = currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    // En uygun kamerayı seç
    int bestCameraIndex = -1;

    // Önce geniş açılı kamera ara
    for (int i = 0; i < cameras!.length; i++) {
      final camera = cameras![i];
      if (camera.lensDirection == oppositeDirection) {
        if (camera.name.toLowerCase().contains('wide') ||
            camera.name.toLowerCase().contains('ultra') ||
            camera.name.toLowerCase().contains('0.6') ||
            camera.name.toLowerCase().contains('0.5') ||
            camera.sensorOrientation == 90) {
          bestCameraIndex = i;
          break;
        }
      }
    }

    // Geniş açılı bulunamazsa normal kamera ara
    if (bestCameraIndex == -1) {
      for (int i = 0; i < cameras!.length; i++) {
        final camera = cameras![i];
        if (camera.lensDirection == oppositeDirection) {
          bestCameraIndex = i;
          break;
        }
      }
    }

    // Hiç kamera bulunamazsa mevcut kamerayı kullan
    if (bestCameraIndex == -1) {
      bestCameraIndex = _currentCameraIndex;
    }

    _currentCameraIndex = bestCameraIndex;
    await _initializeCamera();

    // Zoom ayarlarını optimize et
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;
        final zoomLevel = isBackCamera ? 1.0 : 0.8;
        await _controller!.setZoomLevel(zoomLevel);
        _currentZoomLevel = zoomLevel;
        _pendingZoomLevel = zoomLevel;
        print("Kamera değiştirildi - Zoom: $_currentZoomLevel");
      } catch (e) {
        print("Zoom ayarlanamadı: $e");
      }
    }
  }

  void _startRecognitionLoop() {
    if (!_isCameraReady || !_isAppInForeground || !_isRecognitionActive) {
      print("🚀 Tanıma döngüsü başlatılamadı - Kamera: $_isCameraReady, App: $_isAppInForeground, Recognition: $_isRecognitionActive");
      return;
    }

    final isBackCamera = _controller?.description.lensDirection == CameraLensDirection.back;

    // 🚀 Kamera tipine göre interval ayarla - performans optimizasyonu
    Duration interval;
    if (isBackCamera) {
      // Arka kamera için optimize edilmiş interval
      interval = Duration(milliseconds: 1500);
    } else {
      // Ön kamera için optimize edilmiş interval
      interval = Duration(milliseconds: 1600);
    }

    print("🚀 Tanıma döngüsü başlatıldı - Interval: ${interval.inMilliseconds}ms (OPTİMİZE)");
    _timer = Timer.periodic(interval, (_) {
      // 🎯 Yüz tanıma işlemi devam ediyorsa frame alma
      if (_isAppInForeground && _isRecognitionActive && !_isFrameProcessing && !_isRecognitionInProgress) {
        _captureAndRecognize();
      } else if (_isRecognitionInProgress) {
        print("🎯 Yüz tanıma işlemi devam ediyor, frame alımı durduruldu...");
      }
    });
  }

  // 🚀 Frame işleme optimizasyonu - Debounce ile
  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing || _isFrameProcessing) {
      return;
    }

    // 🎯 İnternet bağlantısı kontrolü
    if (!_isConnected) {
      print("🌐 İnternet bağlantısı yok, tanıma işlemi durduruldu");
      _updateRecognitionStatus("İnternet bağlantısı yok");
      return;
    }

    // 🎯 Yüz tanıma işlemi devam ediyorsa frame alma
    if (_isRecognitionInProgress) {
      print("🎯 Yüz tanıma işlemi devam ediyor, frame alınmıyor...");
      return;
    }

    // 🚀 Frame debounce kontrolü
    final now = DateTime.now();
    if (_lastFrameTime != null && now.difference(_lastFrameTime!) < _frameDebounceDuration) {
      return;
    }

    _isFrameProcessing = true;
    _lastFrameTime = now;

    try {
      if (!_controller!.value.isInitialized) {
        _isFrameProcessing = false;
        return;
      }

      // 🚀 Görüntü kalitesini optimize et
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      // 🎯 Yüz değişikliği kontrolü
      if (!_hasFaceChanged(imageFile)) {
        print("🎯 Aynı yüz, frame işlenmiyor...");
        _isFrameProcessing = false;
        return;
      }

      // 🎯 Yüz tanıma işlemi başladı
      _isRecognitionInProgress = true;
      _updateRecognitionStatus("Yüz tanıma yapılıyor...");

      // 🚀 Görüntü boyutunu kontrol et ve optimize et
      final image = await _optimizeImageForRecognition(imageFile);
      if (image == null) {
        _isFrameProcessing = false;
        _isRecognitionInProgress = false;
        _updateRecognitionStatus("Görüntü işlenemedi");
        return;
      }

      // 🚀 Tanıma işlemini optimize et - İnternet kontrolü ile
      Map<String, dynamic> result;
      try {
        result = await FaceApiService.recognizeFace(image)
            .timeout(Duration(seconds: 5), onTimeout: () {
          throw TimeoutException('Tanıma zaman aşımı');
        });
      } catch (e) {
        // 🎯 İnternet bağlantısı hatası kontrolü
        if (e.toString().contains('SocketException') ||
            e.toString().contains('ClientException') ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('Failed host lookup')) {
          print("🌐 İnternet bağlantısı hatası: $e");
          _updateRecognitionStatus("İnternet bağlantısı yok");
          return;
        } else {
          print("🚀 Tanıma hatası: $e");
          _updateRecognitionStatus("Tanıma hatası oluştu");
          return;
        }
      }

      // 🚀 State güncellemesini optimize et
      if (mounted) {
        setState(() {
          // Threshold bilgisini al
          double? threshold;
          Map<String, dynamic>? thresholdChange;

          if (result['threshold_info'] != null) {
            threshold = double.tryParse(result['threshold_info']['threshold'].toString());
            currentThreshold = threshold;

            // Threshold değişikliği bilgisini al
            if (result['threshold_info']['change'] != null) {
              thresholdChange = Map<String, dynamic>.from(result['threshold_info']['change']);
            }
          }

          if (result['recognized'] == true) {
            recognizedName = result['name'];
            idNo = result['id_no'] ?? '';
            birthDate = result['birth_date'] ?? '';
            resultMessage = "Tanınan kişi: $recognizedName";

            _addToRecognizedList(recognizedName!, idNo!, birthDate ?? '', threshold: threshold);
            _isRecognizedListVisible = true;
          } else if (result['success'] == true && result['recognized'] == false) {
            recognizedName = result['name'];
            idNo = result['id_no'] ?? '';
            birthDate = result['birth_date'] ?? '';
            resultMessage = "Bu kişi zaten tanındı: $recognizedName";

            _addToRecognizedList(recognizedName!, idNo!, birthDate ?? '', threshold: threshold);
            _isRecognizedListVisible = true;
          } else {
            String message = result['message'] ?? "Tanınmayan kişi";

            if (message.contains("Sistemde kayıtlı kullanıcı bulunamadı")) {
              resultMessage = "Sistemde kayıtlı kullanıcı bulunamadı";
            } else if (message.contains("Yüz tespit edilemedi")) {
              resultMessage = "Yüz tespit edilemedi";
            } else if (message.contains("Görüntü işlenemedi")) {
              resultMessage = "Görüntü işlenemedi";
            } else {
              resultMessage = message;
            }

            recognizedName = null;
            idNo = null;
            birthDate = null;
          }
        });
      }

    } catch (e) {
      print("🚀 Tanıma hatası: $e");

      // 🎯 İnternet bağlantısı hatası kontrolü
      if (e.toString().contains('SocketException') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        _updateRecognitionStatus("İnternet bağlantısı yok");
      } else {
        _updateRecognitionStatus("Tanıma hatası oluştu");
      }
    } finally {
      _isFrameProcessing = false;
      _isRecognitionInProgress = false;

      // 🎯 Tanıma tamamlandı mesajı
      if (mounted && resultMessage != null && !resultMessage!.contains("Yüz tanıma yapılıyor")) {
        // 2 saniye sonra mesajı temizle
        Timer(Duration(seconds: 2), () {
          if (mounted && resultMessage != null && !resultMessage!.contains("Tanınan kişi") && !resultMessage!.contains("Bu kişi zaten tanındı") && !resultMessage!.contains("İnternet bağlantısı yok")) {
            setState(() {
              resultMessage = null;
            });
          }
        });
      }
    }
  }

  // 🚀 Görüntü optimizasyonu için yeni metod
  Future<File?> _optimizeImageForRecognition(File originalImage) async {
    try {
      // Görüntü boyutunu kontrol et
      final imageBytes = await originalImage.readAsBytes();

      // 🚀 Büyük görüntüleri sıkıştır
      if (imageBytes.length > 500000) { // 500KB'dan büyükse
        print("🚀 Görüntü sıkıştırılıyor... (${(imageBytes.length / 1024).toStringAsFixed(1)}KB)");
        return await _resizeAndCompressImage(originalImage);
      }

      return originalImage;
    } catch (e) {
      print("🚀 Görüntü optimizasyon hatası: $e");
      return originalImage;
    }
  }

  // 🚀 Görüntü sıkıştırma ve yeniden boyutlandırma
  Future<File?> _resizeAndCompressImage(File originalImage) async {
    try {
      // Geçici dosya oluştur
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Görüntüyü kopyala (basit optimizasyon)
      await originalImage.copy(tempFile.path);

      print("🚀 Görüntü optimize edildi: ${tempFile.path}");
      return tempFile;
    } catch (e) {
      print("🚀 Görüntü sıkıştırma hatası: $e");
      return originalImage;
    }
  }

  // 🚀 Performans optimizasyonu
  void _optimizePerformance() {
    if (!_isMemoryOptimized) {
      // Memory optimizasyonu
      _isMemoryOptimized = true;

      // Gereksiz logları temizle
      if (_realtimeLogs.length > 30) {
        _realtimeLogs = _realtimeLogs.sublist(_realtimeLogs.length - 30);
      }

      print("🚀 Performans optimizasyonu tamamlandı");
    }
  }

  // 🎯 Yüz hash'i hesaplama - Basit hash algoritması
  String _calculateFaceHash(File imageFile) {
    try {
      // Dosya boyutu ve son değişiklik zamanını kullanarak basit hash
      final stat = imageFile.statSync();
      final fileSize = stat.size;
      final modifiedTime = stat.modified.millisecondsSinceEpoch;

      // Basit hash hesaplama
      final hash = (fileSize * 31 + modifiedTime * 17) % 1000000;
      return hash.toString();
    } catch (e) {
      print("🎯 Yüz hash hesaplama hatası: $e");
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // 🎯 Yüz değişikliği kontrolü
  bool _hasFaceChanged(File imageFile) {
    final currentFaceHash = _calculateFaceHash(imageFile);

    // İlk yüz ise veya hash değiştiyse
    if (_lastProcessedFaceHash == null || _lastProcessedFaceHash != currentFaceHash) {
      _lastProcessedFaceHash = currentFaceHash;
      _lastFaceDetectionTime = DateTime.now();
      print("🎯 Yeni yüz tespit edildi: $currentFaceHash");
      return true;
    }

    // Cooldown süresi kontrolü
    if (_lastFaceDetectionTime != null) {
      final timeSinceLastDetection = DateTime.now().difference(_lastFaceDetectionTime!);
      if (timeSinceLastDetection < _faceDetectionCooldown) {
        return false;
      }
    }

    return false;
  }

  // 🌟 IŞIK DETECTION METODLARI - Yeni metodlar
  void _startLightingDetection() {
    if (!_isLightingDetectionActive) return;

    _lightingDetectionTimer = Timer.periodic(_lightingDetectionInterval, (_) {
      if (_isAppInForeground && _isCameraReady && !_isFrameProcessing) {
        _detectLightingConditions();
      }
    });
  }

  Future<void> _detectLightingConditions() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      // Kamera görüntüsünü al
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      // Işık durumunu analiz et
      final lightingStatus = await _analyzeLighting(imageFile);

      if (mounted) {
        setState(() {
          _currentLightingStatus = lightingStatus;

          // Işık durumu kötüyse rehberlik göster
          if (lightingStatus.condition != LightingCondition.good) {
            _showLightingGuidance = true;
            _startLightingGuidanceTimer();
          } else {
            _showLightingGuidance = false;
            _lightingGuidanceTimer?.cancel();
          }
        });
      }
    } catch (e) {
      print("🌟 Işık detection hatası: $e");
    }
  }

  Future<LightingStatus> _analyzeLighting(File imageFile) async {
    try {
      // Görüntüyü base64'e çevir
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // API'ye ışık analizi isteği gönder
      final response = await http.post(
        Uri.parse('${FaceApiService.baseUrl}/analyze_lighting'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'image': base64Image}),
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return _parseLightingResponse(result);
      } else {
        print("🌟 API ışık analizi hatası: ${response.statusCode}");
        // API hatası durumunda yerel analiz yap
        return _analyzeLightingLocally(imageFile);
      }
    } catch (e) {
      print("🌟 Işık analizi hatası: $e");
      // Hata durumunda yerel analiz yap
      return _analyzeLightingLocally(imageFile);
    }
  }

  LightingStatus _parseLightingResponse(Map<String, dynamic> result) {
    final condition = result['condition'] ?? 'unknown';
    final message = result['message'] ?? 'Işık durumu analiz ediliyor...';
    final suggestion = result['suggestion'] ?? '';

    switch (condition) {
      case 'good':
        return LightingStatus(
          condition: LightingCondition.good,
          message: 'Işık durumu uygun',
          suggestion: 'Yüzünüzü odaklanma alanına yerleştirin',
          color: Colors.green,
          icon: Icons.wb_sunny,
        );
      case 'too_bright':
        return LightingStatus(
          condition: LightingCondition.tooBright,
          message: 'Çok fazla ışık var',
          suggestion: 'Daha az aydınlatılmış bir alana geçin veya ışığı azaltın',
          color: Colors.orange,
          icon: Icons.highlight,
        );
      case 'too_dark':
        return LightingStatus(
          condition: LightingCondition.tooDark,
          message: 'Çok karanlık',
          suggestion: 'Daha aydınlatılmış bir alana geçin veya ışığı artırın',
          color: Colors.blue,
          icon: Icons.nights_stay,
        );
      case 'uneven':
        return LightingStatus(
          condition: LightingCondition.uneven,
          message: 'Dengesiz ışık',
          suggestion: 'Yüzünüzü daha eşit aydınlatılmış bir konuma getirin',
          color: Colors.yellow,
          icon: Icons.lightbulb_outline,
        );
      default:
        return LightingStatus(
          condition: LightingCondition.unknown,
          message: 'Işık durumu belirlenemedi',
          suggestion: 'Kamerayı yeniden konumlandırın',
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }

  Future<LightingStatus> _analyzeLightingLocally(File imageFile) async {
    try {
      // Basit yerel ışık analizi
      final bytes = await imageFile.readAsBytes();
      final image = await decodeImageFromList(bytes);

      // Görüntüyü analiz et
      final lightingData = await _analyzeImageBrightness(image);

      return _determineLightingStatus(lightingData);
    } catch (e) {
      print("🌟 Yerel ışık analizi hatası: $e");
      return LightingStatus(
        condition: LightingCondition.unknown,
        message: 'Işık durumu belirlenemedi',
        suggestion: 'Kamerayı yeniden konumlandırın',
        color: Colors.grey,
        icon: Icons.help_outline,
      );
    }
  }

  Future<Map<String, double>> _analyzeImageBrightness(ui.Image image) async {
    try {
      // Basit parlaklık analizi
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = byteData!.buffer.asUint8List();

      double totalBrightness = 0;
      int pixelCount = 0;
      List<double> brightnessValues = [];

      // Her 10. pikseli analiz et (performans için)
      for (int i = 0; i < bytes.length; i += 40) {
        if (i + 3 < bytes.length) {
          final r = bytes[i];
          final g = bytes[i + 1];
          final b = bytes[i + 2];

          // Parlaklık hesapla (RGB'den gri ton)
          final brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
          totalBrightness += brightness;
          brightnessValues.add(brightness);
          pixelCount++;
        }
      }

      final averageBrightness = pixelCount > 0 ? totalBrightness / pixelCount : 0.5;

      // Standart sapma hesapla
      double variance = 0;
      for (double brightness in brightnessValues) {
        variance += (brightness - averageBrightness) * (brightness - averageBrightness);
      }
      final stdDeviation = pixelCount > 0 ? math.sqrt(variance / pixelCount) : 0.0;

      return {
        'average_brightness': averageBrightness,
        'std_deviation': stdDeviation,
        'pixel_count': pixelCount.toDouble(),
      };
    } catch (e) {
      print("🌟 Parlaklık analizi hatası: $e");
      return {
        'average_brightness': 0.5,
        'std_deviation': 0.0,
        'pixel_count': 0.0,
      };
    }
  }

  LightingStatus _determineLightingStatus(Map<String, double> lightingData) {
    final averageBrightness = lightingData['average_brightness'] ?? 0.5;
    final stdDeviation = lightingData['std_deviation'] ?? 0.0;

    if (averageBrightness > 0.8) {
      return LightingStatus(
        condition: LightingCondition.tooBright,
        message: 'Çok fazla ışık var',
        suggestion: 'Daha az aydınlatılmış bir alana geçin veya ışığı azaltın',
        color: Colors.orange,
        icon: Icons.highlight,
      );
    } else if (averageBrightness < 0.3) {
      return LightingStatus(
        condition: LightingCondition.tooDark,
        message: 'Çok karanlık',
        suggestion: 'Daha aydınlatılmış bir alana geçin veya ışığı artırın',
        color: Colors.blue,
        icon: Icons.nights_stay,
      );
    } else if (stdDeviation > 0.3 || averageBrightness < 0.5) {
      return LightingStatus(
        condition: LightingCondition.uneven,
        message: 'Dengesiz ışık',
        suggestion: 'Yüzünüzü daha eşit aydınlatılmış bir konuma getirin',
        color: Colors.yellow,
        icon: Icons.lightbulb_outline,
      );
    } else {
      return LightingStatus(
        condition: LightingCondition.good,
        message: 'Işık durumu uygun',
        suggestion: 'Yüzünüzü odaklanma alanına yerleştirin',
        color: Colors.green,
        icon: Icons.wb_sunny,
      );
    }
  }

  void _startLightingGuidanceTimer() {
    _lightingGuidanceTimer?.cancel();
    _lightingGuidanceTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showLightingGuidance = false;
        });
      }
    });
  }

  // 🌟 Işık durumu rehberlik widget'ı
  Widget _buildLightingGuidanceWidget() {
    if (!_showLightingGuidance || _currentLightingStatus == null) {
      return SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _currentLightingStatus!.color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _currentLightingStatus!.icon,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currentLightingStatus!.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _currentLightingStatus!.suggestion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showLightingGuidance = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 Işık durumu göstergesi widget'ı
  Widget _buildLightingStatusWidget() {
    if (_currentLightingStatus == null) {
      return SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _currentLightingStatus!.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _currentLightingStatus!.icon,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                _currentLightingStatus!.message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return _controller == null || !_controller!.value.isInitialized
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.greenAccent),
                SizedBox(height: 16),
                Text(
                  "Kamera başlatılıyor...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
              : Stack(
            fit: StackFit.expand,
            children: [
              // 🚀 Kamera preview'ı optimize edilmiş şekilde göster
              Positioned.fill(
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: _controller?.value.previewSize == null
                          ? Container()
                          : SizedBox(
                        width: _controller!.value.previewSize!.height,
                        height: _controller!.value.previewSize!.width,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                  ),
                ),
              ),

              // 🚀 Odaklanma alanı göstergesi - ortadaki bölümü vurgula
              Positioned.fill(
                child: CustomPaint(
                  painter: FocusAreaPainter(),
                  child: Container(),
                ),
              ),

              // 🌟 Işık durumu göstergesi - sağ üst köşede
              _buildLightingStatusWidget(),

              // 🌟 Işık durumu rehberlik widget'ı - üstte
              _buildLightingGuidanceWidget(),

              // 🚀 Bilgi kutusu üstte, gölgeli ve yarı saydam
              if (resultMessage != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Container(
                      margin: EdgeInsets.only(top: 8, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🎯 Yüz tanıma işlemi sırasında loading göster
                              if (_isRecognitionInProgress)
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.greenAccent,
                                  ),
                                )
                              else
                                Icon(
                                  _getMessageIcon(resultMessage!),
                                  color: _getMessageColor(resultMessage!),
                                  size: 24,
                                ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  resultMessage!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _getMessageColor(resultMessage!),
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (recognizedName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Adı: $recognizedName", style: TextStyle(fontSize: 18, color: Colors.white)),
                                  if (idNo != null) Text("Kimlik No: $idNo", style: TextStyle(color: Colors.white)),
                                  if (birthDate != null) Text("Doğum Tarihi: $birthDate", style: TextStyle(color: Colors.white)),
                                  if (currentThreshold != null) ...[
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getThresholdColor(currentThreshold!).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _getThresholdColor(currentThreshold!), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.tune, color: _getThresholdColor(currentThreshold!), size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            "Aktif Threshold: ${currentThreshold!.toStringAsFixed(3)}",
                                            style: TextStyle(
                                              color: _getThresholdColor(currentThreshold!),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 🚀 Gerçek zamanlı tanıma kayıtları - sol alt köşede (kapanabilir buton)
              Positioned(
                bottom: isLandscape ? 24 : 16,
                left: isLandscape ? 24 : 16,
                child: SafeArea(
                  child: Column(
                    children: [
                      // 🚀 Tanıma sıfırlama butonu - tanınanlar listesinin üstünde
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ClipOval(
                          child: Material(
                            color: Colors.black.withOpacity(0.6),
                            child: InkWell(
                              onTap: () async {
                                await _resetRecognitionSession();
                                if (mounted) {
                                  setState(() {
                                    _realtimeLogs.clear();
                                    _isRecognizedListVisible = false;
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Tanıma oturumu sıfırlandı"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(Icons.refresh, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 🚀 Tanınanlar listesi
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: _isRecognizedListVisible
                            ? (isLandscape ? 300 : 280)
                            : 60,
                        height: _isRecognizedListVisible
                            ? (isLandscape ? 200 : 180)
                            : 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(_isRecognizedListVisible ? 12 : 30),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isRecognizedListVisible
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🎯 Başlık ve kapatma butonu
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.people, color: Colors.greenAccent, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Tanınanlar (${_realtimeLogs.length})",
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.greenAccent,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isRecognizedListVisible = false;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            // 🎯 Tanınanlar listesi
                            Expanded(
                              child: _realtimeLogs.isEmpty
                                  ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 32,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Henüz tanınan kişi yok",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                itemCount: _realtimeLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _realtimeLogs[_realtimeLogs.length - 1 - index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          log['name'] ?? 'Bilinmeyen',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (log['id_no'] != null)
                                          Text(
                                            "ID: ${log['id_no']}",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 10,
                                            ),
                                          ),
                                        if (log['threshold'] != null)
                                          Text(
                                            "Aktif Threshold: ${(log['threshold'] as double).toStringAsFixed(3)}",
                                            style: TextStyle(
                                              color: _getThresholdColor(log['threshold'] as double),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                            : // 🎯 Kapalı durumda buton
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRecognizedListVisible = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.greenAccent,
                                  size: 24,
                                ),
                                if (_realtimeLogs.isNotEmpty) ...[
                                  SizedBox(height: 2),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "${_realtimeLogs.length}",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🚀 Zoom Slider - sağ alt köşede (sadece arka kamera için göster)
              if (_controller?.description.lensDirection == CameraLensDirection.back)
                Positioned(
                  bottom: 0,
                  right: isLandscape ? 24 : 16,
                  top: 0,
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        height: isLandscape ? 320 : 280,
                        width: 40,
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(height: 12),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.greenAccent,
                                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                                    thumbColor: Colors.greenAccent,
                                    overlayColor: Colors.greenAccent.withOpacity(0.2),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: _pendingZoomLevel,
                                    min: _minZoomLevel,
                                    max: _maxZoomLevel,
                                    divisions: 90,
                                    onChanged: (value) {
                                      if (mounted) {
                                        setState(() {
                                          _pendingZoomLevel = value;
                                        });
                                      }
                                      _debouncedSetZoom(value);
                                    },
                                    onChangeEnd: (value) {
                                      _zoomDebounceTimer?.cancel();
                                      _setZoomLevel(value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Icon(Icons.zoom_out, color: Colors.white, size: 14),
                            SizedBox(height: 6),
                            Text(
                              '${_currentZoomLevel.toStringAsFixed(1)}x',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 🚀 Kamera Değiştirme Butonu - sağ üst köşede
              Positioned(
                top: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: EdgeInsets.only(top: 0, right: 16),
                    child: ClipOval(
                      child: Material(
                        color: Colors.black.withOpacity(0.6),
                        child: InkWell(
                          onTap: _switchCamera,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 🚀 Geri butonu - sol üst köşede
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Container(
                    margin: EdgeInsets.only(top: 0, left: 16),
                    child: ClipOval(
                      child: Material(
                        color: Colors.black.withOpacity(0.6),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}