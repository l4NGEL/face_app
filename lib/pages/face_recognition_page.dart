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
  String? resultMessage;
  String? recognizedName;
  String? idNo;
  String? birthDate;
  Timer? _timer;
  bool _isProcessing = false;

  // Gerçek zamanlı tanıma kayıtları
  List<Map<String, dynamic>> _realtimeLogs = [];
  Timer? _logsTimer;

  // Tanınanlar listesi görünürlük kontrolü
  bool _isRecognizedListVisible = true;

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
    _logsTimer = Timer.periodic(Duration(seconds: 1), (_) => _updateRealtimeLogs());
  }

  Future<void> _updateRealtimeLogs() async {
    try {
      final logs = await FaceApiService.getRealtimeRecognitionLogs();
      setState(() {
        _realtimeLogs = List<Map<String, dynamic>>.from(logs);
      });
    } catch (e) {
      print("Log güncelleme hatası: $e");
    }
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      final frontCamera = cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras![0],
      );
      _controller = CameraController(
        frontCamera, 
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      
      // Kamera yönlendirmesini sabitle
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
      setState(() {});
      _startRecognitionLoop();
    }
  }

  void _startRecognitionLoop() {
    _timer = Timer.periodic(Duration(milliseconds: 1500), (_) => _captureAndRecognize());
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
        } else if (result['success'] == true && result['recognized'] == false) {
          // Bu kişi zaten tanındı durumu
          recognizedName = result['name'];
          idNo = result['id_no'] ?? '';
          birthDate = result['birth_date'] ?? '';
          resultMessage = "Bu kişi zaten tanındı: $recognizedName";
        } else {
          resultMessage = result['message'] ?? "Tanınmayan kişi";
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

              // Gerçek zamanlı tanıma kayıtları - sağ alt köşede (açılır/kapanır)
              if (_realtimeLogs.isNotEmpty)
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
                        Text(
                          resultMessage!,
                          style: TextStyle(
                            fontSize: 20,
                            color: recognizedName != null ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 8,
                              ),
                            ],
                          ),
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