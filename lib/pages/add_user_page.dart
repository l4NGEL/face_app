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
  bool isDetecting = false;
  bool isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      // Ön kamerayı tercih et
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
      
      // Kamera oryantasyonunu sabit tut
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
      
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

  Future<void> _captureMultipleFaces() async {
    if (isCapturing) return;
    setState(() { isCapturing = true; });
    for (int i = 0; i < 5; i++) {
      if (_controller == null || !_controller!.value.isInitialized || faceCount >= 5) break;
      await _captureFace();
      await Future.delayed(Duration(milliseconds: 500));
    }
    setState(() { isCapturing = false; });
  }

  Future<void> _saveUser() async {
    if (nameController.text.isEmpty || idNoController.text.isEmpty || birthDateController.text.isEmpty || faceImages.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tüm alanları doldurun ve en az 1 fotoğraf çekin!')));
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          
          return SingleChildScrollView(
            child: isLandscape 
                ? _buildLandscapeLayout(constraints)
                : _buildPortraitLayout(constraints),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BoxConstraints constraints) {
    return Column(
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
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            height: constraints.maxHeight * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            clipBehavior: Clip.hardEdge,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.14159),
              child: CameraPreview(_controller!),
            ),
          ),
        SizedBox(height: 8),
        Text('Yüz fotoğrafı çekin (en az 1, en fazla 5): $faceCount / 5'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (!isCapturing && faceCount < 5) ? _captureMultipleFaces : null,
              child: isCapturing
                  ? Row(children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Çekiliyor...')
              ])
                  : Text('Görüntü Al (5 Fotoğraf)'),
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
    );
  }

  Widget _buildLandscapeLayout(BoxConstraints constraints) {
    return Row(
      children: [
        // Sol taraf - Form alanları
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Ad Soyad'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: idNoController,
                  decoration: InputDecoration(labelText: 'Kimlik No'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: birthDateController,
                  decoration: InputDecoration(labelText: 'Doğum Tarihi (YYYY-AA-GG)'),
                ),
                SizedBox(height: 24),
                Text('Yüz fotoğrafı çekin (en az 1, en fazla 5): $faceCount / 5'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!isCapturing && faceCount < 5) ? _captureMultipleFaces : null,
                        child: isCapturing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('Çekiliyor...')
                                ],
                              )
                            : Text('Görüntü Al (5 Fotoğraf)'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveUser,
                        child: Text('Kaydet'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Wrap(
                  children: faceImages
                      .map((img) => Padding(
                    padding: EdgeInsets.all(4),
                    child: Image.file(img, width: 50, height: 50, fit: BoxFit.cover),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        
        // Sağ taraf - Kamera
        if (_controller != null && _controller!.value.isInitialized)
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              clipBehavior: Clip.hardEdge,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(3.14159),
                child: CameraPreview(_controller!),
              ),
            ),
          ),
      ],
    );
  }
}
