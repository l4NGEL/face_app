import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/face_api_services.dart';
import '../services/connectivity_service.dart';
import '../services/user_validation_service.dart';
import '../widgets/user_form_widget.dart';
import '../widgets/camera_widget.dart';
import '../widgets/layout_builders.dart';
import '../constants/app_constants.dart';
import 'home_page.dart';

class AddUserPage extends StatefulWidget {
  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> with WidgetsBindingObserver {
  // Controllers
  CameraController? _controller;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0;
  
  // Form controllers
  final nameController = TextEditingController();
  final idNoController = TextEditingController();
  final birthDateController = TextEditingController();
  
  // Focus nodes
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _idNoFocusNode = FocusNode();
  final FocusNode _birthDateFocusNode = FocusNode();
  
  // State variables
  List<File> faceImages = [];
  int faceCount = 0;
  bool isDetecting = false;
  bool isCapturing = false;
  bool isSaving = false;
  
  // Connectivity
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInternetConnection();
    _connectivityService.startListening();
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.dispose();
    _controller?.dispose();
    _nameFocusNode.dispose();
    _idNoFocusNode.dispose();
    _birthDateFocusNode.dispose();
    nameController.dispose();
    idNoController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkInternetConnection();
    }
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

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _currentCameraIndex = cameras!.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0;
      }
      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    await _controller?.dispose();

    final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;
    final resolution = isBackCamera ? ResolutionPreset.high : ResolutionPreset.medium;

    _controller = CameraController(
      cameras![_currentCameraIndex],
      resolution,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    await _controller!.initialize();
    await _controller!.setFlashMode(FlashMode.off);
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    try {
      final zoomLevel = isBackCamera ? 1.0 : 0.8;
      await _controller!.setZoomLevel(zoomLevel);
    } catch (e) {
      print("Zoom ayarlanamadı: $e");
    }

    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    final currentDirection = cameras![_currentCameraIndex].lensDirection;
    final oppositeDirection = currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    int wideAngleIndex = -1;
    int normalIndex = -1;

    for (int i = 0; i < cameras!.length; i++) {
      final camera = cameras![i];
      if (camera.lensDirection == oppositeDirection) {
        if (camera.name.toLowerCase().contains('wide') ||
            camera.name.toLowerCase().contains('ultra') ||
            camera.name.toLowerCase().contains('0.6') ||
            camera.name.toLowerCase().contains('0.5') ||
            camera.sensorOrientation == 90) {
          wideAngleIndex = i;
          break;
        } else if (normalIndex == -1) {
          normalIndex = i;
        }
      }
    }

    if (wideAngleIndex != -1) {
      _currentCameraIndex = wideAngleIndex;
      await _initializeCamera();
    } else if (normalIndex != -1) {
      _currentCameraIndex = normalIndex;
      await _initializeCamera();
    }

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;
        final zoomLevel = isBackCamera ? 1.0 : 0.8;
        await _controller!.setZoomLevel(zoomLevel);
      } catch (e) {
        print("Zoom ayarlanamadı: $e");
      }
    }
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized || faceCount >= AppConstants.MAX_PHOTOS) return;
    final XFile file = await _controller!.takePicture();
    final File imageFile = File(file.path);
    faceImages.add(imageFile);
    faceCount++;
    setState(() {});
  }

  Future<void> _captureMultipleFaces() async {
    if (isCapturing) return;
    setState(() { isCapturing = true; });
    for (int i = 0; i < AppConstants.MAX_PHOTOS; i++) {
      if (_controller == null || !_controller!.value.isInitialized || faceCount >= AppConstants.MAX_PHOTOS) break;
      await _captureFace();
      await Future.delayed(AppConstants.PHOTO_CAPTURE_DELAY);
    }
    setState(() { isCapturing = false; });
  }

  void _showImageDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
            ),
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      faceImages.removeAt(index);
      faceCount--;
    });
  }

  Future<void> _saveUser() async {
    setState(() {
      isSaving = true;
    });

    // Validation
    final validation = UserValidationService.validateUser(
      name: nameController.text,
      idNo: idNoController.text,
      birthDate: birthDateController.text,
      faceImages: faceImages,
    );

    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(validation.errorMessage!),
        backgroundColor: AppConstants.ERROR_COLOR,
      ));
      setState(() {
        isSaving = false;
      });
      return;
    }

    try {
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? AppConstants.USER_SAVED_SUCCESS),
      ));
      
      if (result['success'] == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
          (route) => false,
        );
      } else {
        setState(() {
          isSaving = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppConstants.SAVE_ERROR}: ${e.toString()}'),
        backgroundColor: AppConstants.ERROR_COLOR,
      ));
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Kişi Kaydet'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return SingleChildScrollView(
              child: isLandscape
                  ? LandscapeLayoutBuilder(
                      nameController: nameController,
                      idNoController: idNoController,
                      birthDateController: birthDateController,
                      nameFocusNode: _nameFocusNode,
                      idNoFocusNode: _idNoFocusNode,
                      birthDateFocusNode: _birthDateFocusNode,
                      controller: _controller,
                      onSwitchCamera: _switchCamera,
                      onCaptureMultipleFaces: _captureMultipleFaces,
                      isCapturing: isCapturing,
                      faceCount: faceCount,
                      faceImages: faceImages,
                      onShowImageDialog: _showImageDialog,
                      onRemoveImage: _removeImage,
                      onSaveUser: _saveUser,
                      isSaving: isSaving,
                      isConnected: _isConnected,
                    )
                  : PortraitLayoutBuilder(
                      nameController: nameController,
                      idNoController: idNoController,
                      birthDateController: birthDateController,
                      nameFocusNode: _nameFocusNode,
                      idNoFocusNode: _idNoFocusNode,
                      birthDateFocusNode: _birthDateFocusNode,
                      controller: _controller,
                      onSwitchCamera: _switchCamera,
                      onCaptureMultipleFaces: _captureMultipleFaces,
                      isCapturing: isCapturing,
                      faceCount: faceCount,
                      faceImages: faceImages,
                      onShowImageDialog: _showImageDialog,
                      onRemoveImage: _removeImage,
                      onSaveUser: _saveUser,
                      isSaving: isSaving,
                      isConnected: _isConnected,
                    ),
            );
          },
        ),
      ),
    );
  }
}
