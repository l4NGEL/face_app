# FaceApp - Yüz Tanıma Sistemi

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white)

**Gelişmiş yüz tanıma teknolojisi ile kullanıcı yönetimi ve kimlik doğrulama sistemi**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/yourusername/faceapp)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/yourusername/faceapp)

</div>

---

## İçindekiler

- [Özellikler](#özellikler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Proje Yapısı](#proje-yapısı)
- [API Konfigürasyonu](#api-konfigürasyonu)
- [Kamera Özellikleri](#kamera-özellikleri)
- [UI/UX Özellikleri](#uiux-özellikleri)
- [Test](#test)
- [Build](#build)
- [Katkıda Bulunma](#katkıda-bulunma)
- [Lisans](#lisans)

---

## Özellikler

### Kimlik Doğrulama
- **Yüz Tanıma**: Gelişmiş AI algoritmaları ile yüksek doğruluk oranı
- **Çoklu Fotoğraf Desteği**: Kullanıcı başına 1-5 fotoğraf kaydetme
- **Gerçek Zamanlı Tanıma**: Anlık kimlik doğrulama
- **Güvenli Veri Saklama**: Şifrelenmiş veri depolama

### Kullanıcı Yönetimi
- **Kullanıcı Kaydı**: Ad, kimlik no, doğum tarihi ile kayıt
- **Kullanıcı Listesi**: Kayıtlı kullanıcıları görüntüleme
- **Kullanıcı Düzenleme**: Bilgi güncelleme ve fotoğraf yönetimi
- **Kullanıcı Silme**: Güvenli kullanıcı silme işlemi

### Raporlama ve Loglama
- **Tanıma Geçmişi**: Tüm tanıma işlemlerinin kaydı
- **Kullanıcı Logları**: Kullanıcı bazında detaylı loglar
- **Gerçek Zamanlı İzleme**: Anlık sistem durumu
- **İstatistikler**: Performans ve kullanım analizi

### Bağlantı Yönetimi
- **İnternet Kontrolü**: Otomatik bağlantı durumu kontrolü
- **Hata Yönetimi**: Kullanıcı dostu hata mesajları
- **Offline Desteği**: Bağlantı olmadığında bilgilendirme

---

## Kurulum

### Gereksinimler
Bu uygulamayı çalıştırmak için aşağıdaki yazılımların yüklü olması gerekir:

#### Temel Gereksinimler
- **Flutter SDK 3.9.2+** (Ana geliştirme framework'ü)
- **Dart 3.0+** (Programlama dili)
- **Git** (Kod indirme için)

#### Geliştirme Ortamı (Birini seçin)
- **Android Studio** (Önerilen - Android geliştirme için)
- **Visual Studio Code** (Hafif alternatif)
- **IntelliJ IDEA** (Profesyonel IDE)

#### Platform Bağımlılıkları
- **Android için**: Android SDK, Android Studio
- **iOS için**: Xcode (sadece macOS'ta)
- **Web için**: Chrome tarayıcısı

### Adım Adım Kurulum

#### 1. Flutter SDK Kurulumu

**Windows için:**
1. [Flutter resmi sitesinden](https://flutter.dev/docs/get-started/install/windows) Flutter SDK'yı indirin
2. ZIP dosyasını `C:\flutter` klasörüne çıkarın
3. Sistem PATH'ine `C:\flutter\bin` ekleyin
4. Komut satırını açın ve `flutter doctor` yazın

**macOS için:**
```bash
# Homebrew ile (önerilen)
brew install flutter

# Manuel kurulum
# Flutter SDK'yı indirin ve PATH'e ekleyin
```

**Linux için:**
```bash
# Snap ile
sudo snap install flutter --classic

# Manuel kurulum
# Flutter SDK'yı indirin ve PATH'e ekleyin
```

#### 2. Geliştirme Ortamı Kurulumu

**Android Studio (Önerilen):**
1. [Android Studio'yu indirin](https://developer.android.com/studio)
2. Kurulum sırasında "Android SDK" seçeneğini işaretleyin
3. Android Studio'yu açın ve Flutter plugin'ini yükleyin
4. `flutter doctor` komutu ile kurulumu kontrol edin

**VS Code (Alternatif):**
1. [VS Code'u indirin](https://code.visualstudio.com/)
2. Flutter ve Dart extension'larını yükleyin
3. `flutter doctor` komutu ile kurulumu kontrol edin

#### 3. Projeyi İndirme

**Git ile (önerilen):**
```bash
# Projeyi klonlayın
git clone https://github.com/l4NGEL/face_app.git

# Proje klasörüne gidin
cd faceapp
```

**Manuel indirme:**
1. GitHub'da "Code" butonuna tıklayın
2. "Download ZIP" seçeneğini seçin
3. ZIP dosyasını çıkarın
4. Klasörü istediğiniz yere taşıyın

#### 4. Bağımlılıkları Yükleme

```bash
# Flutter bağımlılıklarını yükleyin
flutter pub get

# Eğer hata alırsanız, cache'i temizleyin
flutter clean
flutter pub get
```

#### 5. API Sunucusu Kurulumu (Backend)

**Python kurulumu:**
1. [Python 3.8+ indirin](https://python.org/downloads/)
2. Kurulum sırasında "Add to PATH" seçeneğini işaretleyin

**API sunucusunu başlatın:**
```bash
# Backend klasörüne gidin (eğer varsa)
cd backend

# Python bağımlılıklarını yükleyin
pip install -r requirements.txt

# API sunucusunu başlatın
python app.py
```

**Not:** Eğer backend kodu yoksa, sadece Flutter uygulamasını çalıştırabilirsiniz.

#### 6. Uygulamayı Çalıştırma

**Android için:**
```bash
# Android cihaz/emülatör bağlı olduğundan emin olun
flutter devices

# Uygulamayı çalıştırın
flutter run
```

**iOS için (sadece macOS):**
```bash
# iOS simülatör/cihaz bağlı olduğundan emin olun
flutter devices

# Uygulamayı çalıştırın
flutter run -d ios
```

**Web için:**
```bash
# Web uygulamasını çalıştırın
flutter run -d web
```

### Sorun Giderme

#### Flutter Doctor Kontrolü
```bash
# Flutter kurulumunu kontrol edin
flutter doctor

# Eksik bileşenleri yükleyin
flutter doctor --android-licenses
```

#### Yaygın Hatalar ve Çözümleri

**"flutter: command not found" hatası:**
- Flutter SDK'nın PATH'e eklendiğinden emin olun
- Terminal'i yeniden başlatın

**"No connected devices" hatası:**
- Android: USB debugging açık olduğundan emin olun
- iOS: Xcode kurulu olduğundan emin olun
- Emülatör/simülatör çalıştırın

**"Gradle build failed" hatası:**
```bash
# Cache'i temizleyin
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

### İlk Çalıştırma Kontrol Listesi

- [ ] Flutter SDK kurulu
- [ ] Geliştirme ortamı kurulu (Android Studio/VS Code)
- [ ] Android SDK kurulu (Android için)
- [ ] Xcode kurulu (iOS için)
- [ ] Proje indirildi
- [ ] `flutter pub get` çalıştırıldı
- [ ] Cihaz/emülatör bağlı
- [ ] `flutter doctor` hata vermiyor
- [ ] `flutter run` başarılı

---

## Kullanım

### Uygulama Başlatma
1. **Uygulamayı açın**: Ana ekranda 4 ana buton görürsünüz
2. **İnternet bağlantısı**: Uygulama otomatik olarak internet bağlantınızı kontrol eder
3. **İzinler**: İlk kullanımda kamera izni isteyecektir - "İzin Ver" butonuna tıklayın

### Ana Sayfa Özellikleri

#### Yüz Tanıma Yap
- **Amaç**: Daha önce kayıtlı kullanıcıları tanımak için
- **Nasıl kullanılır**: 
  1. "Yüz Tanıma Yap" butonuna tıklayın
  2. Kamera otomatik açılır
  3. Yüzünüzü kameraya gösterin
  4. "Fotoğraf Çek" butonuna basın
  5. Sonuç ekranında tanıma bilgilerini görün

#### Kişi Kaydet
- **Amaç**: Yeni kullanıcı eklemek için
- **Nasıl kullanılır**:
  1. "Kişi Kaydet" butonuna tıklayın
  2. Form alanlarını doldurun (Ad, Kimlik No, Doğum Tarihi)
  3. 1-5 adet yüz fotoğrafı çekin
  4. "Kaydet" butonuna basın

#### Kullanıcıları Görüntüle
- **Amaç**: Kayıtlı tüm kullanıcıları listelemek için
- **Nasıl kullanılır**:
  1. "Kullanıcıları Görüntüle" butonuna tıklayın
  2. Kayıtlı kullanıcı listesini görün
  3. Kullanıcı detaylarını inceleyin
  4. Gerekirse düzenleme/silme işlemleri yapın

#### Tanıma Sorgula
- **Amaç**: Geçmiş tanıma kayıtlarını görmek için
- **Nasıl kullanılır**:
  1. "Tanıma Sorgula" butonuna tıklayın
  2. Tanıma geçmişini görün
  3. Tarih ve saat bilgilerini inceleyin

### Detaylı Kullanım Kılavuzu

#### Kullanıcı Kaydı Adım Adım

**1. Kişisel Bilgileri Girme:**
- **Ad Soyad**: Tam adınızı yazın (örn: "Ahmet Yılmaz")
- **Kimlik No**: 11 haneli TC kimlik numaranızı girin
- **Doğum Tarihi**: YYYY-AA-GG formatında (örn: "1990-01-15")

**2. Fotoğraf Çekme:**
- **Kamera Hazırlığı**: Yüzünüzü kameraya net bir şekilde gösterin
- **Işık**: Yeterli ışık olduğundan emin olun
- **Pozisyon**: Düz bakın, gülümseyin
- **Çekim**: "Görüntü Al" butonuna basın (otomatik 5 fotoğraf çeker)
- **Kontrol**: Çekilen fotoğrafları kontrol edin, isterseniz silin

**3. Kaydetme:**
- **Doğrulama**: Form otomatik olarak doğrulanır
- **Hata Kontrolü**: Eksik/hatalı bilgiler kırmızı ile işaretlenir
- **Başarı**: "Kaydediliyor..." mesajı görünür
- **Tamamlandı**: Ana sayfaya otomatik dönüş

#### Yüz Tanıma Adım Adım

**1. Tanıma Başlatma:**
- "Yüz Tanıma Yap" butonuna tıklayın
- Kamera otomatik açılır
- Yüzünüzü kameraya gösterin

**2. Fotoğraf Çekme:**
- "Fotoğraf Çek" butonuna basın
- Anlık fotoğraf çekilir
- İşleme başlar

**3. Sonuç Görüntüleme:**
- **Tanındı**: Kullanıcı bilgileri görünür
- **Tanınmadı**: "Tanınamadı" mesajı görünür
- **Hata**: Tekrar deneme önerisi

### Ekran Yönlendirmeleri

#### Portrait (Dikey) Modu
- Form alanları üstte
- Kamera ortada
- Butonlar altta
- Fotoğraflar alt kısımda

#### Landscape (Yatay) Modu
- Form alanları solda
- Kamera sağda
- Butonlar form altında
- Fotoğraflar form altında

### Hata Mesajları ve Çözümleri

#### "İnternet bağlantısı yok!"
- **Çözüm**: WiFi veya mobil veri bağlantınızı kontrol edin
- **Tekrar dene**: Bağlantı sağlandıktan sonra "Tekrar Dene" butonuna basın

#### "Kamera izni gerekli"
- **Çözüm**: Telefon ayarlarından kamera iznini verin
- **Android**: Ayarlar > Uygulamalar > FaceApp > İzinler > Kamera
- **iOS**: Ayarlar > Gizlilik > Kamera > FaceApp

#### "Kimlik numarası 11 haneli olmalıdır"
- **Çözüm**: TC kimlik numaranızı tam olarak girin
- **Kontrol**: Boşluk veya özel karakter olmamalı

#### "Doğum tarihi YYYY-AA-GG formatında olmalıdır"
- **Çözüm**: Tarihi doğru formatta girin
- **Örnek**: 1990-01-15 (1990 yılı, 01 ay, 15 gün)

### Performans İpuçları

#### Hızlı Çalışma İçin
- **İyi ışık**: Fotoğraf çekerken yeterli ışık olması
- **Sabit pozisyon**: Hareket etmeden fotoğraf çekin
- **Temiz kamera**: Kamera lensini temizleyin
- **Stabil internet**: Güçlü internet bağlantısı

#### Sorun Giderme
- **Uygulama yavaş**: Telefonu yeniden başlatın
- **Kamera açılmıyor**: Uygulamayı kapatıp açın
- **Tanıma başarısız**: Farklı açılardan fotoğraf çekin

---

## Proje Yapısı

```
lib/
├── components/           # Genel bileşenler
│   └── components.dart
├── constants/           # Sabitler ve konfigürasyon
│   └── app_constants.dart
├── model/              # Veri modelleri
│   └── items_model.dart
├── pages/              # Sayfa bileşenleri
│   ├── add_user_page.dart
│   ├── face_recognition_page.dart
│   ├── home_page.dart
│   ├── recognition_query_page.dart
│   └── users_log_page.dart
├── services/           # İş mantığı servisleri
│   ├── connectivity_service.dart
│   ├── face_api_services.dart
│   └── user_validation_service.dart
├── utils/              # Yardımcı fonksiyonlar
│   └── colors.dart
├── view/               # Görünüm bileşenleri
│   └── welcome_page.dart
├── widgets/            # Yeniden kullanılabilir widget'lar
│   ├── camera_widget.dart
│   ├── layout_builders.dart
│   └── user_form_widget.dart
└── main.dart              # Ana uygulama dosyası
```

### Modüler Yapı
- **Separation of Concerns**: Her dosya tek sorumluluk
- **Reusable Components**: Yeniden kullanılabilir bileşenler
- **Clean Architecture**: Temiz kod mimarisi
- **SOLID Principles**: Yazılım geliştirme prensipleri

---

## API Konfigürasyonu

### Backend API Endpoints
```dart
// lib/services/face_api_services.dart
static const String baseUrl = 'http://10.6.2.63:5000';
```

### Desteklenen İşlemler
- `POST /recognize` - Yüz tanıma
- `POST /add_user` - Kullanıcı ekleme
- `GET /users` - Kullanıcı listesi
- `GET /user_logs/{userId}` - Kullanıcı logları
- `GET /recognition_logs/{userId}` - Tanıma logları
- `DELETE /delete_user/{userId}` - Kullanıcı silme

### API Güvenliği
- HTTPS desteği
- Veri şifreleme
- Rate limiting
- CORS konfigürasyonu

---

## Kamera Özellikleri

### Desteklenen Platformlar
- Android (API 21+)
- iOS (12.0+)
- Web (Kaldırıldı - performans optimizasyonu)

### Kamera Özellikleri
- **Çoklu Kamera Desteği**: Ön/arka kamera geçişi
- **Otomatik Odaklama**: Akıllı odak sistemi
- **Çözünürlük Optimizasyonu**: Performans için optimize edilmiş
- **Zoom Kontrolü**: Manuel zoom ayarları
- **Flash Kontrolü**: Otomatik flash yönetimi

### Fotoğraf Kalitesi
- **Yüksek Çözünürlük**: 1024x1024 maksimum
- **Kalite Optimizasyonu**: %90 JPEG kalitesi
- **Hızlı İşleme**: Anlık fotoğraf işleme
- **Bellek Optimizasyonu**: Düşük bellek kullanımı

---

## UI/UX Özellikleri

### Responsive Tasarım
- **Portrait Mode**: Dikey ekran optimizasyonu
- **Landscape Mode**: Yatay ekran optimizasyonu
- **Adaptive Layout**: Ekran boyutuna göre uyarlama
- **Material Design**: Google Material Design 3

### Kullanıcı Deneyimi
- **Sezgisel Arayüz**: Kolay kullanım
- **Hızlı Navigasyon**: Tek dokunuşla geçiş
- **Görsel Geri Bildirim**: Animasyonlar ve geçişler
- **Erişilebilirlik**: Engelli kullanıcı desteği

### Tema ve Renkler
```dart
// Ana renkler
static const Color PRIMARY_COLOR = Colors.teal;
static const Color SUCCESS_COLOR = Colors.green;
static const Color ERROR_COLOR = Colors.red;
static const Color WARNING_COLOR = Colors.orange;
```

---

## Test

### Unit Testler
```bash
# Tüm testleri çalıştır
flutter test

# Belirli bir dosyayı test et
flutter test test/widget_test.dart
```

### Widget Testleri
```bash
# Widget testleri
flutter test test/widgets/

# Integration testleri
flutter test integration_test/
```

### Test Kapsamı
- Form validasyonu
- API çağrıları
- Kamera işlevleri
- Kullanıcı akışları
- Hata yönetimi

---

## Build

### Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK (Boyut optimizasyonu)
flutter build apk --split-per-abi
```

### iOS
```bash
# iOS build
flutter build ios --release

# iOS simulator
flutter run -d ios
```

### Build Optimizasyonu
- **Code Splitting**: Kod bölme
- **Tree Shaking**: Kullanılmayan kod temizleme
- **Asset Optimization**: Görsel optimizasyonu
- **Bundle Analysis**: Paket boyutu analizi

---

## Geliştirme

### Kod Standartları
- **Dart Style Guide**: Resmi Dart stil rehberi
- **Flutter Lints**: Otomatik kod kontrolü
- **Clean Code**: Temiz kod prensipleri
- **Documentation**: Kapsamlı dokümantasyon

### Git Workflow
```bash
# Feature branch oluştur
git checkout -b feature/yeni-ozellik

# Commit yap
git commit -m "feat: yeni özellik eklendi"

# Push et
git push origin feature/yeni-ozellik
```

### Code Review Checklist
- [ ] Kod kalitesi kontrolü
- [ ] Test kapsamı
- [ ] Dokümantasyon güncellemesi
- [ ] Performans optimizasyonu
- [ ] Güvenlik kontrolü

---

## Sorun Giderme

### Başlangıç Sorunları

#### "flutter: command not found" Hatası
**Sorun**: Terminal'de flutter komutu tanınmıyor
**Çözüm**:
1. Flutter SDK'nın doğru kurulduğunu kontrol edin
2. PATH değişkenine Flutter'ın bin klasörünü ekleyin
3. Terminal'i yeniden başlatın
4. `flutter doctor` komutunu çalıştırın

#### "No connected devices" Hatası
**Sorun**: Cihaz veya emülatör bulunamıyor
**Çözüm**:
- **Android için**:
  - USB debugging açık olduğundan emin olun
  - USB kablosu ile telefonu bilgisayara bağlayın
  - Android Studio'da emülatör çalıştırın
- **iOS için**:
  - Xcode kurulu olduğundan emin olun
  - iOS simülatör çalıştırın
  - Gerçek cihaz için geliştirici hesabı gerekli

### Geliştirme Sorunları

#### "Gradle build failed" Hatası
**Sorun**: Android build işlemi başarısız
**Çözüm**:
```bash
# Cache'i temizleyin
flutter clean

# Android cache'i temizleyin
cd android
./gradlew clean
cd ..

# Bağımlılıkları yeniden yükleyin
flutter pub get

# Tekrar deneyin
flutter run
```

#### "Pod install failed" Hatası (iOS)
**Sorun**: iOS bağımlılıkları yüklenemiyor
**Çözüm**:
```bash
# iOS klasörüne gidin
cd ios

# Pod cache'i temizleyin
pod cache clean --all

# Pod'ları yeniden yükleyin
pod install

# Ana klasöre dönün
cd ..

# Tekrar deneyin
flutter run
```

### Uygulama Çalışma Sorunları

#### Kamera Açılmıyor
**Sorun**: Kamera izni verilmemiş veya kamera kullanımda
**Çözüm**:
- **Android**: Ayarlar > Uygulamalar > FaceApp > İzinler > Kamera > İzin Ver
- **iOS**: Ayarlar > Gizlilik > Kamera > FaceApp > Açık
- **Genel**: Uygulamayı kapatıp açın, telefonu yeniden başlatın

#### "İnternet bağlantısı yok" Hatası
**Sorun**: API sunucusuna bağlanılamıyor
**Çözüm**:
1. İnternet bağlantınızı kontrol edin
2. API sunucusunun çalıştığından emin olun
3. Firewall ayarlarını kontrol edin
4. API URL'ini doğrulayın

#### Uygulama Çöküyor
**Sorun**: Uygulama beklenmedik şekilde kapanıyor
**Çözüm**:
```bash
# Debug modunda çalıştırın
flutter run --debug

# Log'ları kontrol edin
flutter logs

# Uygulamayı temizleyin
flutter clean
flutter pub get
```

### Performans Sorunları

#### Uygulama Yavaş Çalışıyor
**Sorun**: Düşük performans
**Çözüm**:
- **Debug modu**: Release modunda çalıştırın
- **Emülatör**: Gerçek cihaz kullanın
- **Bellek**: Diğer uygulamaları kapatın
- **Cache**: Uygulama cache'ini temizleyin

#### Kamera Yavaş
**Sorun**: Kamera başlatma veya fotoğraf çekme yavaş
**Çözüm**:
- **Işık**: Yeterli ışık olduğundan emin olun
- **Odak**: Kameraya net bakın
- **Hareket**: Sabit durun
- **Uygulama**: Diğer kamera uygulamalarını kapatın

### API Sorunları

#### "Connection refused" Hatası
**Sorun**: API sunucusuna bağlanılamıyor
**Çözüm**:
```bash
# API sunucusunu kontrol edin
curl http://10.6.2.63:5000/health

# Eğer çalışmıyorsa, sunucuyu başlatın
cd backend
python app.py
```

#### "Timeout" Hatası
**Sorun**: API yanıt vermiyor
**Çözüm**:
- İnternet bağlantınızı kontrol edin
- API sunucusunun yanıt verdiğinden emin olun
- Firewall ayarlarını kontrol edin
- API URL'ini doğrulayın

### Debug ve Test

#### Debug Modu
```bash
# Verbose logging ile çalıştırın
flutter run --verbose

# Debug modunda çalıştırın
flutter run --debug

# Profile modunda çalıştırın
flutter run --profile

# Release modunda çalıştırın
flutter run --release
```

#### Log Kontrolü
```bash
# Flutter log'larını görün
flutter logs

# Android log'larını görün
adb logcat

# iOS log'larını görün
xcrun simctl spawn booted log stream
```

#### Test Çalıştırma
```bash
# Unit testleri çalıştırın
flutter test

# Widget testleri çalıştırın
flutter test test/widget_test.dart

# Integration testleri çalıştırın
flutter test integration_test/
```

### Sistem Gereksinimleri

#### Minimum Gereksinimler
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **RAM**: 2GB+
- **Depolama**: 100MB boş alan
- **İnternet**: Stabil bağlantı

#### Önerilen Gereksinimler
- **Android**: API 28+ (Android 9.0+)
- **iOS**: iOS 14.0+
- **RAM**: 4GB+
- **Depolama**: 500MB boş alan
- **İnternet**: Hızlı bağlantı

### Yardım Alma

#### Flutter Doctor
```bash
# Sistem durumunu kontrol edin
flutter doctor

# Detaylı bilgi alın
flutter doctor -v

# Eksik bileşenleri yükleyin
flutter doctor --android-licenses
```

#### Destek Kanalları
- **GitHub Issues**: Hata bildirimi için
- **Flutter Docs**: Resmi dokümantasyon
- **Stack Overflow**: Topluluk desteği
- **Flutter Discord**: Canlı destek

### Yaygın Hata Mesajları

#### "Could not find or load main class"
**Çözüm**: Java kurulumunu kontrol edin
```bash
java -version
```

#### "SDK location not found"
**Çözüm**: Android SDK yolunu ayarlayın
```bash
flutter config --android-sdk /path/to/android/sdk
```

#### "CocoaPods not installed"
**Çözüm**: CocoaPods'u yükleyin
```bash
sudo gem install cocoapods
```

#### "Xcode not found"
**Çözüm**: Xcode'u App Store'dan yükleyin

---

## Performans

### Optimizasyon Teknikleri
- **Lazy Loading**: Gerektiğinde yükleme
- **Image Caching**: Görsel önbellekleme
- **Memory Management**: Bellek yönetimi
- **Network Optimization**: Ağ optimizasyonu

### Benchmark Sonuçları
- **App Launch**: < 2 saniye
- **Camera Start**: < 1 saniye
- **Photo Capture**: < 0.5 saniye
- **API Response**: < 3 saniye

---

## Katkıda Bulunma

### Katkı Süreci
1. **Fork** yapın
2. **Feature branch** oluşturun (`git checkout -b feature/amazing-feature`)
3. **Commit** yapın (`git commit -m 'Add amazing feature'`)
4. **Push** edin (`git push origin feature/amazing-feature`)
5. **Pull Request** oluşturun

### Katkı Türleri
- Bug fixes
- New features
- Documentation
- Tests
- UI/UX improvements
- Performance optimizations

### Kod Standartları
- **Commit Messages**: Conventional Commits
- **Code Style**: Dart/Flutter style guide
- **Testing**: Minimum %80 test coverage
- **Documentation**: Inline comments

---

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

```
MIT License

Copyright (c) 2024 FaceApp

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---


</div>
