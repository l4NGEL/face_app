import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/face_api_services.dart';

class PageAddUser extends StatefulWidget {
  const PageAddUser({super.key});

  @override
  State<PageAddUser> createState() => _PageAddUserState();
}

class _PageAddUserState extends State<PageAddUser> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  List<File> faceImages = [];
  final nameController = TextEditingController();
  final idNoController = TextEditingController();
  final birthDateController = TextEditingController();
  bool _isCapturing = false;

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
      _startAutoCapture();
    }
  }

  // Otomatik 5 fotoğraf çeker (1 saniye arayla)
  Future<void> _startAutoCapture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    _isCapturing = true;
    faceImages.clear();
    setState(() {});

    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_controller!.value.isInitialized) break;

      final XFile file = await _controller!.takePicture();
      faceImages.add(File(file.path));
      setState(() {});
    }

    _isCapturing = false;
  }

  void _removeImage(int index) {
    faceImages.removeAt(index);
    setState(() {});
  }

  Future<void> _saveUser() async {
    if (nameController.text.isEmpty ||
        idNoController.text.isEmpty ||
        birthDateController.text.isEmpty ||
        faceImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm alanları doldurun ve en az 1 fotoğrafı bırakın!')),
      );
      return;
    }

    List<String> imagesBase64 = [];
    for (var file in faceImages) {
      imagesBase64.add(await FaceApiService.compressAndEncodeImage(file));
    }

    final result = await FaceApiService.addUser(
      nameController.text,
      idNoController.text,
      birthDateController.text,
      imagesBase64,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Kayıt tamamlandı')),
    );

    if (result['success'] == true) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    nameController.dispose();
    idNoController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kişi Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kişisel Bilgiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            TextField(
              controller: idNoController,
              decoration: const InputDecoration(labelText: 'Kimlik No'),
            ),
            TextField(
              controller: birthDateController,
              decoration: const InputDecoration(labelText: 'Doğum Tarihi (YYYY-AA-GG)'),
            ),

            const SizedBox(height: 24),

            const Text(
              'Kamera Görüntüsü',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_controller != null && _controller!.value.isInitialized)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 220,
                    child: CameraPreview(_controller!),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _startAutoCapture,
                icon: const Icon(Icons.camera),
                label: const Text('5 Fotoğrafı Otomatik Çek'),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Çekilen Fotoğraflar (Silmek için ×)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: faceImages
                  .asMap()
                  .entries
                  .map(
                    (entry) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        entry.value,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        iconSize: 20,
                        splashRadius: 20,
                        onPressed: () => _removeImage(entry.key),
                      ),
                    ),
                  ],
                ),
              )
                  .toList(),
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveUser,
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
