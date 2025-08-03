import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../services/face_api_services.dart';

class FaceRecognitionPage extends StatefulWidget {
  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0; // Kamera indeksi eklendi
  String? resultMessage;
  String? recognizedName;
  String? idNo;
  String? birthDate;
  Timer? _timer;
  bool _isProcessing = false;

  // Zoom kontrolü için değişkenler
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 10.0;
  double _pendingZoomLevel = 1.0; // Slider UI için geçici değer
  bool _isZooming = false; // Zoom işlemi devam ediyor mu kontrolü
  Timer? _zoomDebounceTimer; // Zoom debounce için timer

  // Gerçek zamanlı tanıma kayıtları
  List<Map<String, dynamic>> _realtimeLogs = [];
  Timer? _logsTimer;

  // Tanınanlar listesi görünürlük kontrolü
  bool _isRecognizedListVisible = false; // Başlangıçta kapalı

  @override
  void initState() {
    super.initState();
    _initCamera();
    _resetRecognitionSession();
    _startLogsUpdateTimer();
  }

  Future<void> _resetRecognitionSession() async {
    try {
      await FaceApiService.resetRecognitionSession();
      print("Tanıma oturumu sıfırlandı");
    } catch (e) {
      print("Oturum sıfırlama hatası: $e");
    }
  }

  void _startLogsUpdateTimer() {
    _logsTimer = Timer.periodic(Duration(seconds: 2), (_) => _updateRealtimeLogs());
  }

  Future<void> _updateRealtimeLogs() async {
    try {
      final logs = await FaceApiService.getRealtimeRecognitionLogs();
      // Sadece yeni kayıtlar varsa güncelle
      if (logs.length != _realtimeLogs.length) {
        setState(() {
          _realtimeLogs = List<Map<String, dynamic>>.from(logs);
        });
      }
    } catch (e) {
      print("Log güncelleme hatası: $e");
    }
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      // Ön kamerayı bul
      _currentCameraIndex = cameras!.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0; // Ön kamera yoksa ilk kamerayı kullan
      }

      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    // Mevcut controller'ı dispose et
    await _controller?.dispose();

    // Arka kamera için maksimum kalite, ön kamera için yüksek kalite
    final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;
    final resolution = isBackCamera ? ResolutionPreset.max : ResolutionPreset.high;

    _controller = CameraController(
      cameras![_currentCameraIndex],
      resolution, // Arka kamera için maksimum, ön kamera için yüksek kalite
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
    
    // Flash'ı kapat
    await _controller!.setFlashMode(FlashMode.off);

    // Zoom seviyelerini ayarla (varsayılan değerler)
    _minZoomLevel = 1.0;
    _maxZoomLevel = 10.0;
    _currentZoomLevel = _minZoomLevel;
    _pendingZoomLevel = _currentZoomLevel;

    // Arka kamera için başlangıç zoom ayarı
    if (isBackCamera) {
      try {
        await _controller!.setZoomLevel(_currentZoomLevel);
        print("Arka kamera zoom seviyesi: $_currentZoomLevel");
      } catch (e) {
        print("Zoom ayarlama hatası: $e");
      }
    }

    // Kamera yönlendirmesini sabitle
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    setState(() {});
    _startRecognitionLoop();
  }

  // Zoom değiştirme fonksiyonu - daha agresif optimizasyon
  Future<void> _setZoomLevel(double zoomLevel) async {
    if (_controller == null || !_controller!.value.isInitialized || _isZooming) return;

    // Zoom seviyesini sınırla
    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);

    // Eğer zoom seviyesi çok yakınsa işlem yapma (daha hassas kontrol)
    if ((_currentZoomLevel - clampedZoom).abs() < 0.05) return;

    _isZooming = true;

    try {
      // Zoom seviyesini ayarla
      await _controller!.setZoomLevel(clampedZoom);

      // setState'i daha az sıklıkta çağır
      if ((_currentZoomLevel - clampedZoom).abs() > 0.2) {
        setState(() {
          _currentZoomLevel = clampedZoom;
          _pendingZoomLevel = clampedZoom;
        });
      } else {
        // Sadece current zoom'u güncelle, UI'ı güncelleme
        _currentZoomLevel = clampedZoom;
      }

      print("Zoom seviyesi değiştirildi: $_currentZoomLevel");
    } catch (e) {
      print("Zoom değiştirme hatası: $e");
      // Hata durumunda varsayılan zoom seviyesine dön
      try {
        await _controller!.setZoomLevel(1.0);
        setState(() {
          _currentZoomLevel = 1.0;
          _pendingZoomLevel = 1.0;
        });
      } catch (fallbackError) {
        print("Zoom fallback hatası: $fallbackError");
      }
    } finally {
      _isZooming = false;
    }
  }

  // Debounced zoom fonksiyonu - daha agresif optimizasyon
  void _debouncedSetZoom(double zoomLevel) {
    _zoomDebounceTimer?.cancel();
    _zoomDebounceTimer = Timer(Duration(milliseconds: 50), () {
      _setZoomLevel(zoomLevel);
    });
  }

  // Tanınan kişiyi listeye ekle
  void _addToRecognizedList(String name, String idNo, String birthDate) {
    // Aynı kişinin zaten listede olup olmadığını kontrol et
    bool alreadyExists = _realtimeLogs.any((log) => log['id_no'] == idNo);
    
    if (!alreadyExists) {
      final newLog = {
        'name': name,
        'id_no': idNo,
        'birth_date': birthDate,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      setState(() {
        _realtimeLogs.add(newLog);
      });
      
      print("Tanınan kişi listeye eklendi: $name ($idNo)");
    } else {
      print("Kişi zaten listede mevcut: $name ($idNo)");
    }
  }

  Color _getMessageColor(String message) {
    if (recognizedName != null) {
      return Colors.greenAccent; // Tanınan kişi
    } else if (message.contains("Sistemde kayıtlı kullanıcı bulunamadı")) {
      return Colors.orange; // Uyarı rengi - sistemde kullanıcı yok
    } else if (message.contains("Yüz tespit edilemedi")) {
      return Colors.yellow; // Sarı - yüz tespit sorunu
    } else if (message.contains("Görüntü işlenemedi")) {
      return Colors.red; // Kırmızı - görüntü işleme hatası
    } else {
      return Colors.redAccent; // Diğer hatalar
    }
  }

  IconData _getMessageIcon(String message) {
    if (recognizedName != null) {
      return Icons.check_circle; // Tanınan kişi
    } else if (message.contains("Sistemde kayıtlı kullanıcı bulunamadı")) {
      return Icons.warning; // Uyarı ikonu - sistemde kullanıcı yok
    } else if (message.contains("Yüz tespit edilemedi")) {
      return Icons.face; // Yüz ikonu - yüz tespit sorunu
    } else if (message.contains("Görüntü işlenemedi")) {
      return Icons.error; // Hata ikonu - görüntü işleme hatası
    } else {
      return Icons.cancel; // Diğer hatalar
    }
  }

  // Kamera değiştirme fonksiyonu
  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    // Timer'ı durdur
    _timer?.cancel();

    // Mevcut kameranın yönünü al
    final currentDirection = cameras![_currentCameraIndex].lensDirection;

    // Karşı yöndeki kameraları bul
    final oppositeDirection = currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    // Karşı yöndeki kameraların indekslerini bul
    List<int> oppositeIndices = [];
    for (int i = 0; i < cameras!.length; i++) {
      if (cameras![i].lensDirection == oppositeDirection) {
        oppositeIndices.add(i);
      }
    }

    // Karşı yönde kamera varsa ilkine geç
    if (oppositeIndices.isNotEmpty) {
      _currentCameraIndex = oppositeIndices[0];
      print("Kamera değiştiriliyor: ${cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back ? 'Arka Kamera' : 'Ön Kamera'}");
      await _initializeCamera();
    }
  }

  void _startRecognitionLoop() {
    // Arka kamera için daha hızlı tanıma, ön kamera için normal hız
    final isBackCamera = _controller?.description.lensDirection == CameraLensDirection.back;
    final interval = isBackCamera ? Duration(milliseconds: 1000) : Duration(milliseconds: 1500);

    _timer = Timer.periodic(interval, (_) => _captureAndRecognize());
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;
    _isProcessing = true;

    try {
      // Kamera durumunu kontrol et
      if (!_controller!.value.isInitialized) {
        _isProcessing = false;
        return;
      }

      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      // API çağrısını timeout ile sınırla
      final result = await FaceApiService.recognizeFace(imageFile)
          .timeout(Duration(seconds: 3), onTimeout: () {
        throw TimeoutException('Tanıma zaman aşımı');
      });

      setState(() {
        if (result['recognized'] == true) {
          recognizedName = result['name'];
          idNo = result['id_no'] ?? '';
          birthDate = result['birth_date'] ?? '';
          resultMessage = "Tanınan kişi: $recognizedName";
          
          // Tanınan kişiyi listeye ekle ve listeyi görünür yap
          _addToRecognizedList(recognizedName!, idNo!, birthDate ?? '');
          _isRecognizedListVisible = true;
        } else if (result['success'] == true && result['recognized'] == false) {
          // Bu kişi zaten tanındı durumu
          recognizedName = result['name'];
          idNo = result['id_no'] ?? '';
          birthDate = result['birth_date'] ?? '';
          resultMessage = "Bu kişi zaten tanındı: $recognizedName";
          
          // Tanınan kişiyi listeye ekle ve listeyi görünür yap
          _addToRecognizedList(recognizedName!, idNo!, birthDate ?? '');
          _isRecognizedListVisible = true;
        } else {
          // API'den gelen mesajı kontrol et
          String message = result['message'] ?? "Tanınmayan kişi";
          
          // Özel mesajları kontrol et
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

    } catch (e) {
      // Hata durumunda sadece debug log yaz, UI'ı bozma
      print("Tanıma hatası: $e");
      // setState(() {
      //   resultMessage = "Hata: $e";
      //   recognizedName = null;
      // });
    } finally {
      _isProcessing = false;
    }
  }

  // AlertDialog fonksiyonu kaldırıldı
  // void _showNotRecognizedDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Tanınmayan Kişi'),
  //       content: Text('Bu kişi sistemde kayıtlı değil. Sisteme kaydetmelisiniz.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text('Tamam'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _timer?.cancel();
    _logsTimer?.cancel();
    _zoomDebounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
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
              ? Center(child: CircularProgressIndicator())
              : Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),

              // Kamera değiştirme butonu - sol alt köşede
              Positioned(
                bottom: isLandscape ? 24 : 16,
                left: isLandscape ? 24 : 16,
                child: Column(
                  children: [
                    // Zoom Slider - sadece arka kamera için göster (dikey)
                    if (_controller?.description.lensDirection == CameraLensDirection.back)
                      Container(
                        height: isLandscape ? 280 : 220,
                        width: 70,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(height: 8),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3, // 270 derece döndür (dikey yap)
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.greenAccent,
                                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                                    thumbColor: Colors.greenAccent,
                                    overlayColor: Colors.greenAccent.withOpacity(0.2),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: _pendingZoomLevel,
                                    min: _minZoomLevel,
                                    max: _maxZoomLevel,
                                    divisions: 90, // Daha smooth hareket için
                                    onChanged: (value) {
                                      // UI'ı hemen güncelle ama zoom'u debounce et
                                      setState(() {
                                        _pendingZoomLevel = value;
                                      });
                                      // Debounced zoom uygula
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
                            SizedBox(height: 8),
                            Icon(Icons.zoom_out, color: Colors.white, size: 16),
                            SizedBox(height: 4),
                            Text(
                              '${_currentZoomLevel.toStringAsFixed(1)}x',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_controller?.description.lensDirection == CameraLensDirection.back)
                      SizedBox(height: 8),
                    // Kamera Değiştirme Butonu
                    ClipOval(
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
                  ],
                ),
              ),

              // Gerçek zamanlı tanıma kayıtları - sağ alt köşede (açılır/kapanır)
              Positioned(
                bottom: isLandscape ? 24 : 16,
                right: isLandscape ? 24 : 16,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: _isRecognizedListVisible
                      ? (isLandscape ? 320 : 280)
                      : (isLandscape ? 100 : 80),
                  height: _isRecognizedListVisible
                      ? (isLandscape ? 250 : 300)
                      : (isLandscape ? 100 : 90),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent, width: 2),
                  ),
                    child: _isRecognizedListVisible
                        ? Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people, color: Colors.greenAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Tanınan Kişiler (${_realtimeLogs.length})",
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isRecognizedListVisible = false;
                                  });
                                },
                                child: Icon(
                                  Icons.keyboard_arrow_right,
                                  color: Colors.greenAccent,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.all(8),
                            itemCount: _realtimeLogs.length,
                            itemBuilder: (context, index) {
                              final log = _realtimeLogs[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log['name'] ?? 'Bilinmeyen',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Kimlik: ${log['id_no'] ?? 'N/A'}",
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      "Tarih: ${_formatDateTime(log['timestamp'])}",
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                        : GestureDetector(
                      onTap: () {
                        setState(() {
                          _isRecognizedListVisible = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_left,
                              color: Colors.greenAccent,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${_realtimeLogs.length}",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Bilgi kutusu üstte, gölgeli ve yarı saydam
              if (resultMessage != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: EdgeInsets.only(top: 24, left: 16, right: 16),
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
                              ],
                            ),
                          ),
                        if (resultMessage!.contains("Sistemde kayıtlı kullanıcı bulunamadı"))
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Kişi sistemde yok, lütfen ekleyiniz",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Sol üstte geri butonu
              Positioned(
                top: 24,
                left: 16,
                child: SafeArea(
                  child: ClipOval(
                    child: Material(
                      color: Colors.black.withOpacity(0.4),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Sağ üstte oturum sıfırlama butonu
              Positioned(
                top: 24,
                right: 16,
                child: SafeArea(
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange.withOpacity(0.8),
                      child: InkWell(
                        onTap: () async {
                          await _resetRecognitionSession();
                          setState(() {
                            _realtimeLogs.clear();
                            resultMessage = null;
                            recognizedName = null;
                            _isRecognizedListVisible = false; // Listeyi kapat
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tanıma oturumu sıfırlandı'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.refresh, color: Colors.white, size: 28),
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