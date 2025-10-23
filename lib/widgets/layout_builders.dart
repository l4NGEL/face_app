import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'user_form_widget.dart';
import 'camera_widget.dart';
import '../services/user_validation_service.dart';

class PortraitLayoutBuilder extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController idNoController;
  final TextEditingController birthDateController;
  final FocusNode nameFocusNode;
  final FocusNode idNoFocusNode;
  final FocusNode birthDateFocusNode;
  final CameraController? controller;
  final VoidCallback onSwitchCamera;
  final VoidCallback onCaptureMultipleFaces;
  final bool isCapturing;
  final int faceCount;
  final List<File> faceImages;
  final Function(File) onShowImageDialog;
  final Function(int) onRemoveImage;
  final VoidCallback onSaveUser;
  final bool isSaving;
  final bool isConnected;

  const PortraitLayoutBuilder({
    Key? key,
    required this.nameController,
    required this.idNoController,
    required this.birthDateController,
    required this.nameFocusNode,
    required this.idNoFocusNode,
    required this.birthDateFocusNode,
    required this.controller,
    required this.onSwitchCamera,
    required this.onCaptureMultipleFaces,
    required this.isCapturing,
    required this.faceCount,
    required this.faceImages,
    required this.onShowImageDialog,
    required this.onRemoveImage,
    required this.onSaveUser,
    required this.isSaving,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Form alanları
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: UserFormWidget(
            nameController: nameController,
            idNoController: idNoController,
            birthDateController: birthDateController,
            nameFocusNode: nameFocusNode,
            idNoFocusNode: idNoFocusNode,
            birthDateFocusNode: birthDateFocusNode,
            onNameSubmitted: () => idNoFocusNode.requestFocus(),
            onIdNoSubmitted: () => birthDateFocusNode.requestFocus(),
            onBirthDateSubmitted: () {
              birthDateFocusNode.unfocus();
              FocusScope.of(context).unfocus();
            },
          ),
        ),

        // Kamera widget'ı
        CameraWidget(
          controller: controller,
          onSwitchCamera: onSwitchCamera,
          onCaptureMultipleFaces: onCaptureMultipleFaces,
          isCapturing: isCapturing,
          faceCount: faceCount,
          faceImages: faceImages,
          onShowImageDialog: onShowImageDialog,
          onRemoveImage: onRemoveImage,
        ),

        SizedBox(height: 8),

        // Kaydet butonu
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isSaving ? null : onSaveUser,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.teal),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                elevation: MaterialStateProperty.all(4.0),
                shadowColor: MaterialStateProperty.all(Colors.black26),
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
              ),
              child: isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('')
                      ],
                    )
                  : Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        SizedBox(height: 20),
      ],
    );
  }
}

class LandscapeLayoutBuilder extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController idNoController;
  final TextEditingController birthDateController;
  final FocusNode nameFocusNode;
  final FocusNode idNoFocusNode;
  final FocusNode birthDateFocusNode;
  final CameraController? controller;
  final VoidCallback onSwitchCamera;
  final VoidCallback onCaptureMultipleFaces;
  final bool isCapturing;
  final int faceCount;
  final List<File> faceImages;
  final Function(File) onShowImageDialog;
  final Function(int) onRemoveImage;
  final VoidCallback onSaveUser;
  final bool isSaving;
  final bool isConnected;

  const LandscapeLayoutBuilder({
    Key? key,
    required this.nameController,
    required this.idNoController,
    required this.birthDateController,
    required this.nameFocusNode,
    required this.idNoFocusNode,
    required this.birthDateFocusNode,
    required this.controller,
    required this.onSwitchCamera,
    required this.onCaptureMultipleFaces,
    required this.isCapturing,
    required this.faceCount,
    required this.faceImages,
    required this.onShowImageDialog,
    required this.onRemoveImage,
    required this.onSaveUser,
    required this.isSaving,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sol taraf - Form alanları
        Expanded(
          flex: 1,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserFormWidget(
                  nameController: nameController,
                  idNoController: idNoController,
                  birthDateController: birthDateController,
                  nameFocusNode: nameFocusNode,
                  idNoFocusNode: idNoFocusNode,
                  birthDateFocusNode: birthDateFocusNode,
                  onNameSubmitted: () => idNoFocusNode.requestFocus(),
                  onIdNoSubmitted: () => birthDateFocusNode.requestFocus(),
                  onBirthDateSubmitted: () {
                    birthDateFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                  },
                ),
                SizedBox(height: 24),
                Text('Yüz fotoğrafı çekin (en az 1, en fazla 5): $faceCount / 5'),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!isCapturing && faceCount < 5) ? onCaptureMultipleFaces : null,
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.resolveWith<double>((states) {
                            if (states.contains(MaterialState.pressed)) return 2.0;
                            return 4.0;
                          }),
                          shadowColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.pressed)) return Colors.transparent;
                            return Colors.black26;
                          }),
                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: isCapturing
                            ? Row(children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Çekiliyor...')
                              ])
                            : Text('Görüntü Al (5 Fotoğraf)'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving ? null : onSaveUser,
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.teal),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                          elevation: MaterialStateProperty.all(4.0),
                          shadowColor: MaterialStateProperty.all(Colors.black26),
                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                          splashFactory: NoSplash.splashFactory,
                        ),
                        child: isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  SizedBox(width: 8),
                                  Text('')
                                ],
                              )
                            : Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Çekilen fotoğraflar
                if (faceImages.isNotEmpty)
                  Wrap(
                    children: faceImages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final img = entry.value;
                      return Padding(
                        padding: EdgeInsets.all(4),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => onShowImageDialog(img),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(img, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => onRemoveImage(index),
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),

        // Sağ taraf - Kamera
        if (controller != null && controller!.value.isInitialized)
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Transform.scale(
                    scale: controller!.description.lensDirection == CameraLensDirection.back ? 2.5 : 2.2,
                    child: Center(
                      child: CameraPreview(controller!),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ClipOval(
                      child: Material(
                        color: Colors.black.withOpacity(0.6),
                        child: InkWell(
                          onTap: onSwitchCamera,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.flip_camera_ios, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
