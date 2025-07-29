# My FaceApp

Flutter ile geliştirilmiş yüz tanıma uygulaması. Kullanıcıların yüzlerini kaydedebilir ve gerçek zamanlı tanıma yapabilirsiniz.

## Özellikler

- Kullanıcı kaydı (ad, kimlik no, doğum tarihi)
- Gerçek zamanlı yüz tanıma
- Ön/arka kamera desteği
- Tanıma kayıtları ve logları


## Kurulum

### Gereksinimler
- Flutter 3.0+
- Android Studio / VS Code
- Android SDK (API 21+)

### Adımlar
1. Projeyi klonlayın
```bash
git clone https://github.com/yourusername/my_faceapp.git
cd my_faceapp
```

2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

3. API yapılandırması
- `api.py` dosyasını sunucunuza yükleyin
- API endpoint'lerini `lib/services/face_api_services.dart` dosyasında güncelleyin

4. Uygulamayı çalıştırın
```bash
flutter run
```

## Kullanım

### Kullanıcı Kaydı
1. Ana sayfadan "Kişi Kaydet" butonuna tıklayın
2. Ad soyad, kimlik no (11 haneli) ve doğum tarihi (YYYY-AA-GG) bilgilerini girin
3. Kamera ile yüz fotoğrafları çekin (1-5 adet)
4. "Kaydet" butonuna tıklayın

### Yüz Tanıma
1. Ana sayfadan "Yüz Tanıma" butonuna tıklayın
2. Kamera otomatik olarak yüz tanıma işlemini başlatır
3. Tanınan kişilerin bilgileri ekranda görüntülenir
4. Sağ alt köşedeki panelden tanıma kayıtlarını takip edebilirsiniz

### Kamera Kontrolleri
- **Kamera Değiştirme**: Mavi kamera ikonu ile ön/arka kamera geçişi
- **Oturum Sıfırlama**: Turuncu yenileme ikonu ile tanıma oturumunu sıfırlama

## Proje Yapısı

```
lib/
├── pages/
│   ├── add_user_page.dart      # Kullanıcı ekleme
│   ├── face_recognition_page.dart  # Yüz tanıma
│   ├── home_page.dart          # Ana sayfa
│   └── users_log_page.dart     # Kullanıcı logları
├── services/
│   └── face_api_services.dart  # API servisleri
└── utils/
    └── colors.dart             # Renk tanımları
```

## Teknolojiler

- **Flutter** - Cross-platform framework
- **Dart** - Programlama dili
- **Camera Plugin** - Kamera entegrasyonu
- **HTTP API** - Backend iletişimi
- **TensorFlow Lite** - Yüz tanıma modeli

## API Endpoints

```dart
POST /add_user          // Kullanıcı ekleme
POST /recognize_face    // Yüz tanıma
GET /realtime_logs      // Tanıma logları
```

## Lisans

MIT License

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!
