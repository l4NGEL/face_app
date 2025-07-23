import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import '../services/face_api_services.dart';

class PageRecognize extends StatefulWidget {
  const PageRecognize({super.key});

  @override
  State<PageRecognize> createState() => _PageRecognizeState();
}

class _PageRecognizeState extends State<PageRecognize> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  String? resultMessage;
  String? recognizedName;
  String? idNo;
  String? birthDate;
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {});
      _startRecognitionLoop();
    }
  }

  void _startRecognitionLoop() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _captureAndRecognize());
  }

  Future<void> _captureAndRecognize() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;
    _isProcessing = true;
    try {
      final XFile file = await _controller!.takePicture();
      final File imageFile = File(file.path);

      final result = await FaceApiService.recognizeFace(imageFile);

      setState(() {
        if (result['recognized'] == true) {
          recognizedName = result['name'];
          idNo = result['id_no'] ?? '';
          birthDate = result['birth_date'] ?? '';
          resultMessage = "Tanınan kişi: $recognizedName";
        } else {
          recognizedName = null;
          resultMessage = "Tanınmayan kişi";
        }
      });

      if (result['recognized'] != true) {
        _showNotRecognizedDialog();
      }
    } catch (e) {
      setState(() {
        resultMessage = "Hata: $e";
        recognizedName = null;
      });
    }
    _isProcessing = false;
  }

  void _showNotRecognizedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tanınmayan Kişi'),
        content: const Text('Bu kişi sistemde kayıtlı değil. Sisteme kaydetmelisiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller == null || !_controller!.value.isInitialized
        ? const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    )
        : Scaffold(
      body: Stack(
        children: [
          // 🔴 Kamera tüm ekranı kaplasın
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          // 🟡 Alt bilgi kutusu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resultMessage != null)
                    Text(
                      resultMessage!,
                      style: TextStyle(
                        fontSize: 20,
                        color: recognizedName != null ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (recognizedName != null)
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        Text("Adı: $recognizedName", style: const TextStyle(fontSize: 16, color: Colors.white)),
                        if (idNo != null)
                          Text("Kimlik No: $idNo", style: const TextStyle(color: Colors.white)),
                        if (birthDate != null)
                          Text("Doğum Tarihi: $birthDate", style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
