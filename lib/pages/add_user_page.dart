import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/face_api_services.dart';

class AddUserPage extends StatefulWidget {
  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  List<File> faceImages = [];
  int faceCount = 0;
  final nameController = TextEditingController();
  final idNoController = TextEditingController();
  final birthDateController = TextEditingController();

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
    }
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized || faceCount >= 5) return;
    final XFile file = await _controller!.takePicture();
    final File imageFile = File(file.path);
    faceImages.add(imageFile);
    faceCount++;
    setState(() {});
  }

  Future<void> _saveUser() async {
    if (nameController.text.isEmpty || idNoController.text.isEmpty || birthDateController.text.isEmpty || faceImages.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tüm alanları doldurun ve en az 1 fotoğraf çekin!')));
      return;
    }
    // Fotoğrafları base64 string listesine çevir
    List<String> imagesBase64 = [];
    for (var file in faceImages) {
      imagesBase64.add(await FaceApiService.compressAndEncodeImage(file));
    }
    final result = await FaceApiService.addUser(
      nameController.text,
      idNoController.text,
      birthDateController.text,
      imagesBase64, // Artık List<String>
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Kayıt tamamlandı')));
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
      appBar: AppBar(title: Text('Kişi Kaydet')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Ad Soyad'),
                  ),
                  TextField(
                    controller: idNoController,
                    decoration: InputDecoration(labelText: 'Kimlik No'),
                  ),
                  TextField(
                    controller: birthDateController,
                    decoration: InputDecoration(labelText: 'Doğum Tarihi (YYYY-AA-GG)'),
                  ),
                ],
              ),
            ),
            if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            SizedBox(height: 8),
            Text('Yüz fotoğrafı çekin (en az 1, en fazla 5): $faceCount / 5'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: faceCount < 5 ? _captureFace : null,
                  child: Text('Fotoğraf Çek'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveUser,
                  child: Text('Kaydet'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              children: faceImages
                  .map((img) => Padding(
                padding: EdgeInsets.all(4),
                child: Image.file(img, width: 60, height: 60, fit: BoxFit.cover),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}