# face_app

Bu proje, Flutter ile yazılmış bir mobil uygulama ve Python (Flask) tabanlı bir yüz tanıma API'sinden oluşur. Kullanıcılar sisteme yüz fotoğrafları ile kaydedilebilir, gerçek zamanlı yüz tanıma yapılabilir ve kullanıcılar listelenip silinebilir.

## Özellikler
- Yüz tanıma (MobilFaceNet + OpenCV)
- Kullanıcı ekleme (fotoğraf ile)
- Kullanıcıları listeleme ve silme
- Flutter ile modern mobil arayüz
- Python Flask ile RESTful API

## Kurulum

### 1. Backend (API) Kurulumu
1. Gerekli Python paketlerini yükleyin:
   ```bash
   pip install flask flask-cors opencv-python numpy pillow tensorflow
   ```
2. `mobilefacenet (1).tflite` model dosyasını proje dizinine ekleyin.
3. API'yi başlatın:
   ```bash
   python api.py
   ```
   (API dosyanızın adı farklıysa ona göre değiştirin.)

### 2. Flutter Uygulaması
1. Gerekli paketleri yükleyin:
   ```bash
   flutter pub get
   ```
2. Uygulamayı başlatın:
   ```bash
   flutter run
   ```
3. Android emülatörü kullanıyorsanız, API adresi olarak `http://10.0.2.2:5000` kullanılır. Gerçek cihazda çalıştıracaksanız, bilgisayarınızın IP adresini ve portunu kullanın.

## API Endpointleri
- `POST   /add_user`      : Kullanıcı ekle
- `POST   /recognize`     : Yüz tanıma
- `GET    /users`         : Kullanıcıları listele
- `DELETE /delete_user/<user_id>` : Kullanıcı sil

## Kullanım
- Ana ekrandan yüz tanıma, kullanıcı ekleme ve kullanıcıları listeleme işlemleri yapılabilir.
- Kullanıcılar sayfasında, kullanıcılar listelenir ve silinebilir.

## Notlar
- API ve uygulama aynı ağda olmalıdır.
- Kullanıcı silme işlemi için API ve Flutter kodları uyumlu olmalıdır.
- Yüz tanıma için MobilFaceNet TFLite modeli gereklidir.


