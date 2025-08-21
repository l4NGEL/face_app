import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../services/face_api_services.dart';
import '../services/connectivity_service.dart';
import '../components.dart';
import 'home_page.dart'; // Doğru home page import'u

// Tarih formatı için özel input formatter
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Sadece rakamları al
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Maksimum 8 rakam (YYYYMMDD)
    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    // Tire ekleme
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddUserPage extends StatefulWidget {
  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  int _currentCameraIndex = 0; // Kamera indeksi eklendi
  List<File> faceImages = [];
  int faceCount = 0;
  final nameController = TextEditingController();
  final idNoController = TextEditingController();
  final birthDateController = TextEditingController();
  bool isDetecting = false;
  bool isCapturing = false;
  bool isSaving = false; // Save button loading state

  // 🎯 İnternet bağlantısı kontrolü
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  // Focus node'ları ekle
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _idNoFocusNode = FocusNode();
  final FocusNode _birthDateFocusNode = FocusNode();

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
    // Web platformunda mobil kamera başlatmayı atla
    if (kIsWeb) {
      print("Web platformunda mobil kamera başlatılmıyor");
      return;
    }

    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      // Ön kamerayı bul
      _currentCameraIndex = cameras!.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0; // Ön kamera yoksa ilk kamerayı kullan
      }

      await _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    // Mevcut controller'ı dispose et
    await _controller?.dispose();

    // Arka kamera için yüksek çözünürlük, ön kamera için orta çözünürlük
    final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;
    final resolution = isBackCamera ? ResolutionPreset.high : ResolutionPreset.medium;

    _controller = CameraController(
      cameras![_currentCameraIndex],
      resolution, // Arka kamera için yüksek, ön kamera için orta çözünürlük
      enableAudio: false, // Ses kapalı
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();

    // Flash'ı kapat
    await _controller!.setFlashMode(FlashMode.off);

    // Kamera yönlendirmesini sabitle
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

    // Zoom seviyesini ayarla (normal görüş için zoom artır)
    try {
      final zoomLevel = isBackCamera ? 1.0 : 0.8; // Normal zoom seviyeleri
      await _controller!.setZoomLevel(zoomLevel);
    } catch (e) {
      print("Zoom ayarlanamadı: $e");
    }

    setState(() {});
  }

  // Kamera değiştirme fonksiyonu
  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    // Mevcut kameranın yönünü al
    final currentDirection = cameras![_currentCameraIndex].lensDirection;

    // Karşı yöndeki kameraları bul
    final oppositeDirection = currentDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    // Karşı yöndeki kameraların indekslerini bul
    int wideAngleIndex = -1;
    int normalIndex = -1;

    for (int i = 0; i < cameras!.length; i++) {
      final camera = cameras![i];
      if (camera.lensDirection == oppositeDirection) {
        // Geniş açılı kamera tespiti
        if (camera.name.toLowerCase().contains('wide') ||
            camera.name.toLowerCase().contains('ultra') ||
            camera.name.toLowerCase().contains('0.6') ||
            camera.name.toLowerCase().contains('0.5') ||
            camera.sensorOrientation == 90) {
          wideAngleIndex = i;
          break; // İlk geniş açılı kamerayı bulduğunda dur
        } else if (normalIndex == -1) {
          normalIndex = i;
        }
      }
    }

    // Geniş açılı kamera bulunduysa onu kullan, yoksa normal kamerayı kullan
    if (wideAngleIndex != -1) {
      _currentCameraIndex = wideAngleIndex;
      await _initializeCamera();
    } else if (normalIndex != -1) {
      _currentCameraIndex = normalIndex;
      await _initializeCamera();
    }

    // Kamera değiştirdikten sonra zoom seviyesini tekrar ayarla
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final isBackCamera = cameras![_currentCameraIndex].lensDirection == CameraLensDirection.back;
        final zoomLevel = isBackCamera ? 1.0 : 0.8; // Normal zoom seviyeleri
        await _controller!.setZoomLevel(zoomLevel);
      } catch (e) {
        print("Zoom ayarlanamadı: $e");
      }
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

  // Fotoğrafı büyütme fonksiyonu
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
                // Büyük fotoğraf
                Center(
                  child: InteractiveViewer(
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Kapatma butonu
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

  // Fotoğraf silme fonksiyonu
  void _removeImage(int index) {
    setState(() {
      faceImages.removeAt(index);
      faceCount--;
    });
  }

  // Web'den gelen fotoğrafı işle
  void _handleWebImageCapture(String imageData) {
    print('Web kamera fotoğrafı alındı');
    // Base64 string'i işle ve faceImages listesine ekle
    // Bu kısım web desteği için geliştirilebilir
    setState(() {
      faceCount++;
    });
  }

  Future<void> _saveUser() async {
    // Set loading state
    setState(() {
      isSaving = true;
    });

    // Kimlik numarası validasyonu
    if (idNoController.text.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kimlik numarası 11 haneli olmalıdır!'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        isSaving = false;
      });
      return;
    }

    // Doğum tarihi validasyonu
    if (birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Doğum tarihi zorunludur!'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        isSaving = false;
      });
      return;
    }

    // Doğum tarihi format kontrolü (YYYY-AA-GG)
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(birthDateController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Doğum tarihi YYYY-AA-GG formatında olmalıdır! (Örnek: 1990-01-15)'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        isSaving = false;
      });
      return;
    }

    // Tarih geçerliliği kontrolü
    try {
      final parts = birthDateController.text.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      if (year < 1900 || year > DateTime.now().year) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Geçerli bir yıl giriniz! (1900-${DateTime.now().year})'),
          backgroundColor: Colors.red,
        ));
        setState(() {
          isSaving = false;
        });
        return;
      }

      if (month < 1 || month > 12) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Geçerli bir ay giriniz! (01-12)'),
          backgroundColor: Colors.red,
        ));
        setState(() {
          isSaving = false;
        });
        return;
      }

      if (day < 1 || day > 31) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Geçerli bir gün giriniz! (01-31)'),
          backgroundColor: Colors.red,
        ));
        setState(() {
          isSaving = false;
        });
        return;
      }

      // DateTime ile geçerlilik kontrolü
      final birthDate = DateTime(year, month, day);
      if (birthDate.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Doğum tarihi gelecekte olamaz!'),
          backgroundColor: Colors.red,
        ));
        setState(() {
          isSaving = false;
        });
        return;
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Geçersiz tarih formatı!'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        isSaving = false;
      });
      return;
    }

    if (nameController.text.isEmpty || idNoController.text.isEmpty || birthDateController.text.isEmpty || faceImages.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tüm alanları doldurun ve en az 1 fotoğraf çekin!')));
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Kayıt tamamlandı')));
      if (result['success'] == true) {
        // Başarılı kayıt sonrası home page'e yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      } else {
        // Reset loading state if not successful
        setState(() {
          isSaving = false;
        });
      }
    } catch (e) {
      // Handle any exceptions
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kayıt sırasında hata oluştu: ${e.toString()}'),
        backgroundColor: Colors.red,
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
        resizeToAvoidBottomInset: false, // Klavye açıldığında layout'ı yeniden boyutlandırma
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Kişi Kaydet'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              // Web platformunda kamera kontrolü
              if (kIsWeb) {
                return _buildWebLayout(constraints);
              }

              return SingleChildScrollView(
                child: isLandscape
                    ? _buildLandscapeLayout(constraints)
                    : _buildPortraitLayout(constraints),
              );
            },
          ),
        ));
  }

  // Web platformunda layout
  Widget _buildWebLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Form alanları
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _idNoFocusNode.requestFocus(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: idNoController,
                  focusNode: _idNoFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Kimlik No',
                    border: OutlineInputBorder(),
                    counterText: '${idNoController.text.length}/11',
                    helperText: '11 haneli kimlik numarası giriniz',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: (_) => _birthDateFocusNode.requestFocus(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: birthDateController,
                  focusNode: _birthDateFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Doğum Tarihi (YYYY-AA-GG)',
                    border: OutlineInputBorder(),
                    counterText: '${birthDateController.text.length}/10',
                    helperText: 'Sadece rakamları girin',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _DateInputFormatter(),
                  ],
                  onChanged: (value) {
                    setState(() {});
                  },
                  onSubmitted: (_) {
                    _birthDateFocusNode.unfocus();
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            ),
          ),
          
          // Web kamera widget'ı
          Container(
            margin: EdgeInsets.all(16),
            child: WebCameraWidget(
              onImageCaptured: (String imageData) {
                _handleWebImageCapture(imageData);
              },
            ),
          ),
          
          // Kaydet butonu
          Container(
            margin: EdgeInsets.all(16),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnected ? _saveUser : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Kaydediliyor...'),
                      ],
                    )
                  : Text(
                      'Kullanıcıyı Kaydet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(BoxConstraints constraints) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16), // Üstten 80 pixel boşluk ekledim
          child: Column(
            children: [
              TextField(
                controller: nameController,
                focusNode: _nameFocusNode,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _idNoFocusNode.requestFocus(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: idNoController,
                focusNode: _idNoFocusNode,
                decoration: InputDecoration(
                  labelText: 'Kimlik No',
                  border: OutlineInputBorder(),
                  counterText: '${idNoController.text.length}/11',
                  helperText: '11 haneli kimlik numarası giriniz',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                maxLength: 11,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (value) {
                  setState(() {}); // Counter'ı güncellemek için
                },
                onSubmitted: (_) => _birthDateFocusNode.requestFocus(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: birthDateController,
                focusNode: _birthDateFocusNode,
                decoration: InputDecoration(
                  labelText: 'Doğum Tarihi (YYYY-AA-GG)',
                  border: OutlineInputBorder(),
                  counterText: '${birthDateController.text.length}/10',
                  helperText: 'Sadece rakamları girin',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _DateInputFormatter(),
                ],
                onChanged: (value) {
                  setState(() {}); // Counter'ı güncellemek için
                },
                onSubmitted: (_) {
                  _birthDateFocusNode.unfocus();
                  // Klavyeyi kapat
                  FocusScope.of(context).unfocus();
                },
              ),
            ],
          ),
        ),
        if (_controller != null && _controller!.value.isInitialized)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            height: constraints.maxHeight * 0.4, // Yüksekliği azalttım
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Transform.scale(
                  scale: _controller!.description.lensDirection == CameraLensDirection.back ? 2.5 : 2.2, // Siyah alanları tamamen kaldırmak için maksimum scale
                  child: Center(
                    child: CameraPreview(_controller!),
                  ),
                ),
                // Kamera değiştirme butonu - sağ üst köşede
                Positioned(
                  top: 16,
                  right: 16,
                  child: ClipOval(
                    child: Material(
                      color: Colors.black.withOpacity(0.6),
                      child: InkWell(
                        onTap: _switchCamera,
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
        SizedBox(height: 8),
        Text('Yüz fotoğrafı çekin (en az 1, en fazla 5): $faceCount / 5'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: (!isCapturing && faceCount < 5) ? _captureMultipleFaces : null,
              style: ButtonStyle(
                elevation: MaterialStateProperty.resolveWith<double>((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return 2.0; // Basıldığında düşük elevation
                  }
                  return 4.0; // Normal elevation
                }),
                shadowColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.transparent; // Basıldığında gölge yok
                  }
                  return Colors.black26; // Normal gölge
                }),
                overlayColor: MaterialStateProperty.all(Colors.transparent), // Tıklama rengini şeffaf yap
                splashFactory: NoSplash.splashFactory, // Tıklama animasyonunu kaldır
              ),
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
              onPressed: isSaving ? null : () {
                print("Kaydet butonuna tıklandı");
                _saveUser();
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.teal),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                elevation: MaterialStateProperty.all(4.0), // Sabit elevation
                shadowColor: MaterialStateProperty.all(Colors.black26), // Sabit gölge
                overlayColor: MaterialStateProperty.all(Colors.transparent), // Tıklama rengini şeffaf yap
                splashFactory: NoSplash.splashFactory, // Tıklama animasyonunu kaldır
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
        SizedBox(height: 8),
        Wrap(
          children: faceImages.asMap().entries.map((entry) {
            final index = entry.key;
            final img = entry.value;
            return Padding(
              padding: EdgeInsets.all(4),
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImageDialog(img),
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
                  // Çarpı işareti - sağ üst köşede
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
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
        SizedBox(height: 20), // Alt boşluk ekle
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
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16), // Üstten 80 pixel boşluk ekledim
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  focusNode: _nameFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _idNoFocusNode.requestFocus(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: idNoController,
                  focusNode: _idNoFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Kimlik No',
                    border: OutlineInputBorder(),
                    counterText: '${idNoController.text.length}/11',
                    helperText: '11 haneli kimlik numarası giriniz',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  onChanged: (value) {
                    setState(() {}); // Counter'ı güncellemek için
                  },
                  onSubmitted: (_) => _birthDateFocusNode.requestFocus(),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: birthDateController,
                  focusNode: _birthDateFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Doğum Tarihi (YYYY-AA-GG)',
                    border: OutlineInputBorder(),
                    counterText: '${birthDateController.text.length}/10',
                    helperText: 'Sadece rakamları girin',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _DateInputFormatter(),
                  ],
                  onChanged: (value) {
                    setState(() {}); // Counter'ı güncellemek için
                  },
                  onSubmitted: (_) {
                    _birthDateFocusNode.unfocus();
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
                        onPressed: (!isCapturing && faceCount < 5) ? _captureMultipleFaces : null,
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.resolveWith<double>((states) {
                            if (states.contains(MaterialState.pressed)) return 2.0;
                            return 4.0;
                          }),
                          shadowColor: MaterialStateProperty.resolveWith<Color>((states) {
                            if (states.contains(MaterialState.pressed)) return Colors.transparent;
                            return Colors.black26;
                          }),
                          overlayColor: MaterialStateProperty.all(Colors.transparent), // Tıklama rengini şeffaf yap
                          splashFactory: NoSplash.splashFactory, // Tıklama animasyonunu kaldır
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
                        onPressed: isSaving ? null : () {
                          print("Kaydet butonuna tıklandı (landscape)");
                          _saveUser();
                        },
                                            style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.teal),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      elevation: MaterialStateProperty.all(4.0), // Sabit elevation
                      shadowColor: MaterialStateProperty.all(Colors.black26), // Sabit gölge
                      overlayColor: MaterialStateProperty.all(Colors.transparent), // Tıklama rengini şeffaf yap
                      splashFactory: NoSplash.splashFactory, // Tıklama animasyonunu kaldır
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
                Wrap(
                  children: faceImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final img = entry.value;
                    return Padding(
                      padding: EdgeInsets.all(4),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showImageDialog(img),
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
                          // Çarpı işareti - sağ üst köşede
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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
              child: Stack(
                children: [
                  Transform.scale(
                    scale: _controller!.description.lensDirection == CameraLensDirection.back ? 2.5 : 2.2, // Siyah alanları tamamen kaldırmak için maksimum scale
                    child: Center(
                      child: CameraPreview(_controller!),
                    ),
                  ),
                  // Kamera değiştirme butonu - sağ üst köşede
                  Positioned(
                    top: 16,
                    right: 16,
                    child: ClipOval(
                      child: Material(
                        color: Colors.black.withOpacity(0.6),
                        child: InkWell(
                          onTap: _switchCamera,
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
