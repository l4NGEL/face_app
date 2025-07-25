import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      final frontCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras![0],
      );
      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {});
      _startRecognitionLoop();
    }
  }

  void _startRecognitionLoop() {
    _timer = Timer.periodic(Duration(seconds: 2), (_) => _captureAndRecognize());
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
        title: Text('Tanınmayan Kişi'),
        content: Text('Bu kişi sistemde kayıtlı değil. Sisteme kaydetmelisiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
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
    return Scaffold(
      appBar: AppBar(title: Text("Gerçek Zamanlı Yüz Tanıma")),
      body: _controller == null || !_controller!.value.isInitialized
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resultMessage != null)
                    Text(
                      resultMessage!,
                      style: TextStyle(
                        fontSize: 20,
                        color: recognizedName != null ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (recognizedName != null)
                    Column(
                      children: [
                        Text("Adı: $recognizedName", style: TextStyle(fontSize: 18, color: Colors.white)),
                        if (idNo != null) Text("Kimlik No: $idNo", style: TextStyle(color: Colors.white)),
                        if (birthDate != null) Text("Doğum Tarihi: $birthDate", style: TextStyle(color: Colors.white)),
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