import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraWidget extends StatefulWidget {
  final CameraController? controller;
  final VoidCallback onSwitchCamera;
  final VoidCallback onCaptureMultipleFaces;
  final bool isCapturing;
  final int faceCount;
  final List<File> faceImages;
  final Function(File) onShowImageDialog;
  final Function(int) onRemoveImage;

  const CameraWidget({
    Key? key,
    required this.controller,
    required this.onSwitchCamera,
    required this.onCaptureMultipleFaces,
    required this.isCapturing,
    required this.faceCount,
    required this.faceImages,
    required this.onShowImageDialog,
    required this.onRemoveImage,
  }) : super(key: key);

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kamera Preview
        if (widget.controller != null && widget.controller!.value.isInitialized)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Transform.scale(
                  scale: widget.controller!.description.lensDirection == CameraLensDirection.back ? 2.5 : 2.2,
                  child: Center(
                    child: CameraPreview(widget.controller!),
                  ),
                ),
                // Kamera değiştirme butonu
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipOval(
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      child: InkWell(
                        onTap: widget.onSwitchCamera,
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

        // Fotoğraf sayısı bilgisi
        Text('Yüz fotoğrafı çekin (en az 1, en fazla 5): ${widget.faceCount} / 5'),
        
        // Fotoğraf çekme butonu
        ElevatedButton(
          onPressed: (!widget.isCapturing && widget.faceCount < 5) ? widget.onCaptureMultipleFaces : null,
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
          child: widget.isCapturing
              ? Row(children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Çekiliyor...')
                ])
              : Text('Görüntü Al (5 Fotoğraf)'),
        ),

        // Çekilen fotoğraflar
        if (widget.faceImages.isNotEmpty) ...[
          SizedBox(height: 8),
          Wrap(
            children: widget.faceImages.asMap().entries.map((entry) {
              final index = entry.key;
              final img = entry.value;
              return Padding(
                padding: EdgeInsets.all(4),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => widget.onShowImageDialog(img),
                      child: Container(
                        width: 60,
                        height: 60,
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
                    // Silme butonu
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => widget.onRemoveImage(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
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
      ],
    );
  }
}
