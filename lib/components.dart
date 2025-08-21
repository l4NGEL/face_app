import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:my_faceapp/pages/home_page.dart';
import 'package:my_faceapp/utils/colors.dart';

// Web için kamera widget'ı
class WebCameraWidget extends StatefulWidget {
  final Function(String) onImageCaptured;
  final bool isEnabled;

  const WebCameraWidget({
    Key? key,
    required this.onImageCaptured,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  _WebCameraWidgetState createState() => _WebCameraWidgetState();
}

class _WebCameraWidgetState extends State<WebCameraWidget> {
  html.VideoElement? _videoElement;
  html.CanvasElement? _canvasElement;
  html.MediaStream? _mediaStream;
  bool _isInitialized = false;
  bool _isStreamActive = false;
  String? _errorMessage;


  @override
  void initState() {
    super.initState();
    _initializeWebCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  Future<void> _initializeWebCamera() async {
    try {
      // Video element oluştur
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.objectFit = 'cover';

      // Canvas element oluştur
      _canvasElement = html.CanvasElement()
        ..width = 640
        ..height = 480;

      // Kamera stream'ini al
      _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'facingMode': 'user'
        }
      });

      if (_mediaStream != null) {
        _videoElement!.srcObject = _mediaStream;
        _isStreamActive = true;
        
        // Video yüklendiğinde
        _videoElement!.onLoadedMetadata.listen((_) {
          setState(() {
            _isInitialized = true;
          });
          

        });

        // Video hata durumunda
        _videoElement!.onError.listen((event) {
          setState(() {
            _errorMessage = 'Video yüklenirken hata oluştu';
          });
        });

      } else {
        setState(() {
          _errorMessage = 'Kamera erişimi sağlanamadı';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Kamera başlatılamadı: $e';
      });
    }
  }

  void _stopCamera() {
    if (_mediaStream != null) {
      _mediaStream!.getTracks().forEach((track) => track.stop());
      _mediaStream = null;
    }
    _isStreamActive = false;
    _isInitialized = false;
  }



  Future<void> _captureImage() async {
    if (_videoElement == null || _canvasElement == null || !_isInitialized) {
      return;
    }

    try {
      final context = _canvasElement!.getContext('2d') as html.CanvasRenderingContext2D?;
      if (context != null && _videoElement != null) {
        // drawImage: (image, dx, dy) - sadece pozisyon
        context.drawImage(_videoElement!, 0, 0);
        
        // Canvas'tan base64 string al
        final dataUrl = _canvasElement!.toDataUrl('image/jpeg', 0.8);
        
        // Base64 string'i callback'e gönder
        widget.onImageCaptured(dataUrl);
        
        print('Fotoğraf çekildi ve gönderildi');
      }
      
    } catch (e) {
      print('Fotoğraf çekme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeWebCamera,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Kamera başlatılıyor...'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Video preview - iframe ile HTML5 video
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isStreamActive && _videoElement != null
                  ? _buildVideoPreview()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Web Kamera Aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kamera izinleri verildi',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Kontrol butonları
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isStreamActive ? _captureImage : null,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Fotoğraf Çek'),
                ),
                ElevatedButton.icon(
                  onPressed: _isStreamActive ? _stopCamera : _initializeWebCamera,
                  icon: Icon(_isStreamActive ? Icons.stop : Icons.play_arrow),
                  label: Text(_isStreamActive ? 'Durdur' : 'Başlat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Video preview widget'ı
  Widget _buildVideoPreview() {
    if (kIsWeb && _videoElement != null) {
      // Web'de gerçek HTML5 video element'ini göster
      return _buildRealVideoStream();
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam,
                color: Colors.green,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Kamera Aktif',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Video Stream Aktif',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'Fotoğraf çekmek için butona tıklayın',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // Gerçek video stream widget'ı
  Widget _buildRealVideoStream() {
    // Video element'i DOM'a ekle ve görünür yap
    if (_videoElement != null && _mediaStream != null) {
      // Video element'i DOM'a ekle
      _videoElement!.style.position = 'fixed';
      _videoElement!.style.top = '50%';
      _videoElement!.style.left = '50%';
      _videoElement!.style.transform = 'translate(-50%, -50%)';
      _videoElement!.style.width = '640px';
      _videoElement!.style.height = '480px';
      _videoElement!.style.objectFit = 'cover';
      _videoElement!.style.borderRadius = '8px';
      _videoElement!.style.zIndex = '9999';
      _videoElement!.style.border = '2px solid #00ff00';
      
      // Video element'i DOM'a ekle
      html.document.body?.append(_videoElement!);
      
      // Video stream'i başlat
      _videoElement!.srcObject = _mediaStream;
      _videoElement!.play();
      
      print('Video element DOM\'a eklendi ve stream başlatıldı');
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Video element'i doğrudan göster
          Positioned.fill(
            child: _buildVideoContainer(),
          ),
          // LIVE göstergesi
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Video container widget'ı
  Widget _buildVideoContainer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: _buildVideoFrame(),
    );
  }

  // Video frame widget'ı
  Widget _buildVideoFrame() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildVideoOverlay(),
    );
  }

  // Video overlay widget'ı
  Widget _buildVideoOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: _videoElement != null && _isStreamActive
          ? _buildActiveVideo()
          : _buildVideoPlaceholder(),
    );
  }

  // Aktif video widget'ı
  Widget _buildActiveVideo() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              color: Colors.white,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Video Stream Aktif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kamera görüntüsü alınıyor',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                'Video aktif - Fotoğraf çekebilirsiniz',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Video placeholder widget'ı
  Widget _buildVideoPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              color: Colors.grey.shade400,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Video yükleniyor...',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Web kamera için platform view factory
void registerWebCameraViewFactory() {
  if (kIsWeb) {
    print('Web kamera view factory kaydedildi - basit video çözümü kullanılıyor');
  }
}

class GetStartBtn extends StatefulWidget {
  const GetStartBtn({
    Key? key,
    required this.size,
    required this.textTheme,
  }) : super(key: key);

  final Size size;
  final TextTheme textTheme;

  @override
  State<GetStartBtn> createState() => _GetStartBtnState();
}

class _GetStartBtnState extends State<GetStartBtn> {
  bool isLoading = false;

  loadingHandler() {
    setState(() {
      isLoading = true;
      Future.delayed(const Duration(seconds: 2)).then((value) {
        isLoading = false;
        Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (_) => HomePage()));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loadingHandler,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        width: widget.size.width / 1.5,
        height: widget.size.height / 13,
        decoration: BoxDecoration(
            color: MyColors.btnColor, borderRadius: BorderRadius.circular(15)),
        child: Center(
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                )
              : Text("Yüz Tanıma Sistemine Giriş", style: widget.textTheme.headlineMedium),
        ),
      ),
    );
  }
}

class SkipBtn extends StatelessWidget {
  const SkipBtn({
    Key? key,
    required this.size,
    required this.textTheme,
    required this.onTap,
  }) : super(key: key);

  final Size size;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      width: size.width / 1.5,
      height: size.height / 13,
      decoration: BoxDecoration(
          border: Border.all(
            color: MyColors.btnBorderColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: onTap,
        splashColor: MyColors.btnBorderColor,
        child: Center(
          child: Text("İleri", style: textTheme.displaySmall),
        ),
      ),
    );
  }
}
