# 🌟 My FaceApp - Akıllı Yüz Tanıma Uygulaması

Flutter ile geliştirilmiş gelişmiş yüz tanıma uygulaması. Kullanıcıların yüzlerini kaydedebilir, gerçek zamanlı tanıma yapabilir ve ışık durumunu otomatik olarak analiz edebilirsiniz.

## ✨ Özellikler

### 🎯 Temel Özellikler
- 👤 **Kullanıcı Kaydı**: Ad, kimlik no, doğum tarihi ile kullanıcı kaydı
- 🔍 **Gerçek Zamanlı Yüz Tanıma**: Anlık yüz tanıma ve kimlik doğrulama
- 📷 **Çoklu Kamera Desteği**: Ön/arka kamera geçişi
- 📊 **Detaylı Loglar**: Tanıma kayıtları ve istatistikler
- 📱 **Responsive Tasarım**: Dikey/yatay ekran desteği
- 🎯 **Akıllı Kamera Seçimi**: Fisheye kamera atlama

### 🌟 Yeni Özellikler (v2.0)
- 💡 **Işık Durumu Analizi**: Otomatik ışık koşulları tespiti
- 🎨 **Görsel Rehberlik**: Işık durumuna göre kullanıcı yönlendirmesi
- ⚡ **Performans Optimizasyonu**: Gelişmiş frame işleme
- 🔄 **Otomatik Threshold**: Akıllı eşik değeri optimizasyonu
- 📈 **Gerçek Zamanlı İstatistikler**: Tanıma performans metrikleri

### 💡 Işık Detection Özellikleri
- **Çok Fazla Işık Tespiti**: Overexposure durumunda uyarı
- **Çok Karanlık Tespiti**: Düşük ışık durumunda uyarı
- **Dengesiz Işık Tespiti**: Eşit olmayan aydınlatma uyarısı
- **Otomatik Rehberlik**: Işık durumuna göre kullanıcı önerileri

## 🚀 Kurulum

### Gereksinimler
- Flutter 3.0+ (Dart 3.0+)
- Android Studio / VS Code
- Android SDK (API 21+)
- Python 3.8+ (Backend için)
- OpenCV, TensorFlow, MTCNN (Backend için)

### Adımlar

#### 1. Projeyi Klonlayın
```bash
git clone https://github.com/yourusername/my_faceapp.git
cd my_faceapp
```

#### 2. Flutter Bağımlılıklarını Yükleyin
```bash
flutter pub get
```

#### 3. Backend Kurulumu
```bash
# Python bağımlılıklarını yükleyin
pip install -r requirements.txt

# API'yi başlatın
python api.py
```

#### 4. API Yapılandırması
`lib/services/face_api_services.dart` dosyasında API endpoint'lerini güncelleyin:
```dart
static const String baseUrl = 'http://your-server-ip:5000';
```

#### 5. Uygulamayı Çalıştırın
```bash
flutter run
```

## 📱 Kullanım

### 🏠 Ana Sayfa (HomePage)
**Dosya**: `lib/pages/home_page.dart`

Ana sayfa, uygulamanın giriş noktasıdır ve tüm temel işlevlere erişim sağlar.

#### ✨ Özellikler:
- **Responsive Tasarım**: Dikey ve yatay ekran desteği
- **İnternet Bağlantısı Kontrolü**: Otomatik bağlantı durumu kontrolü
- **Görsel Arayüz**: Face ID logosu ve modern buton tasarımı
- **Navigasyon**: Tüm sayfalara kolay erişim

#### 🎯 Ana Butonlar:
1. **Yüz Tanıma Yap** (`face_recognition_page.dart`)
   - Gerçek zamanlı yüz tanıma
   - Işık durumu analizi
   - Kamera kontrolleri

2. **Kişi Kaydet** (`add_user_page.dart`)
   - Yeni kullanıcı kaydı
   - Fotoğraf çekme
   - Form validasyonu

3. **Tanıma Sorgula** (`recognition_query_page.dart`)
   - Tanıma geçmişi sorgulama
   - Tarih aralığı filtreleme
   - Detaylı raporlar

4. **Kullanıcı Logları** (`users_log_page.dart`)
   - Kayıtlı kullanıcılar listesi
   - Kullanıcı fotoğrafları
   - Kullanıcı yönetimi

### 👤 Kullanıcı Kaydı (AddUserPage)
**Dosya**: `lib/pages/add_user_page.dart`

Yeni kullanıcıların sisteme kaydedildiği sayfa.

#### ✨ Özellikler:
- **Form Validasyonu**: Ad, kimlik no, doğum tarihi kontrolü
- **Kamera Entegrasyonu**: Ön/arka kamera desteği
- **Fotoğraf Çekme**: 1-5 adet yüz fotoğrafı
- **Otomatik Yüz Tespiti**: Çekilen fotoğraflarda yüz kontrolü
- **İnternet Bağlantısı**: Bağlantı durumu kontrolü

#### 📋 Form Alanları:
- **Ad Soyad**: Zorunlu alan, minimum 2 karakter
- **Kimlik No**: 11 haneli TC kimlik numarası
- **Doğum Tarihi**: YYYY-AA-GG formatında otomatik formatlama

#### 📷 Fotoğraf Çekme:
- **Otomatik Yüz Tespiti**: Çekilen fotoğraflarda yüz kontrolü
- **Çoklu Fotoğraf**: 1-5 adet fotoğraf çekme
- **Önizleme**: Çekilen fotoğrafların önizlemesi
- **Silme**: İstenmeyen fotoğrafları silme

#### 🎯 Kullanım Adımları:
1. Form alanlarını doldurun
2. "Fotoğraf Çek" butonuna tıklayın
3. Yüzünüzü kameraya tutun
4. "Çek" butonuna basın
5. 1-5 adet fotoğraf çekin
6. "Kaydet" butonuna tıklayın

### 🔍 Yüz Tanıma (FaceRecognitionPage)
**Dosya**: `lib/pages/face_recognition_page.dart`

Uygulamanın ana özelliği olan gerçek zamanlı yüz tanıma sayfası.

#### ✨ Özellikler:
- **Gerçek Zamanlı Tanıma**: Sürekli yüz tanıma işlemi
- **Işık Detection**: Otomatik ışık durumu analizi
- **Kamera Kontrolleri**: Ön/arka kamera, zoom kontrolü
- **Performans Optimizasyonu**: Frame debouncing, memory management
- **Görsel Rehberlik**: Işık durumuna göre kullanıcı yönlendirmesi

#### 💡 Işık Detection Sistemi:
- **Otomatik Analiz**: Her 2 saniyede bir ışık kontrolü
- **Görsel Uyarılar**: Renk kodlu durum göstergeleri
- **Rehberlik Mesajları**: Işık durumuna göre öneriler
- **Renk Kodları**:
  - 🟢 **Yeşil**: Işık durumu uygun
  - 🟠 **Turuncu**: Çok fazla ışık
  - 🔵 **Mavi**: Çok karanlık
  - 🟡 **Sarı**: Dengesiz ışık

#### 🎮 Kamera Kontrolleri:
- **Kamera Değiştirme**: Sol alt köşedeki kamera ikonu
- **Zoom Kontrolü**: Arka kamera için dikey slider
- **Oturum Sıfırlama**: Sağ üst köşedeki yenileme ikonu
- **Odaklanma Alanı**: Ekranda görsel odaklanma alanı

#### 📊 Tanıma Özellikleri:
- **Gerçek Zamanlı Loglar**: Sağ alt köşede tanıma kayıtları
- **Threshold Optimizasyonu**: Otomatik eşik değeri ayarlama
- **Performans Metrikleri**: Tanıma hızı ve doğruluk oranı
- **Hata Yönetimi**: İnternet bağlantısı ve API hataları

#### 🎯 Kullanım Adımları:
1. Sayfayı açın
2. Yüzünüzü odaklanma alanına yerleştirin
3. Işık durumunu kontrol edin
4. Tanıma sonuçlarını takip edin
5. Gerekirse kamera ayarlarını değiştirin

### 🔍 Tanıma Sorgula (RecognitionQueryPage)
**Dosya**: `lib/pages/recognition_query_page.dart`

Tanıma geçmişini sorgulama ve raporlama sayfası.

#### ✨ Özellikler:
- **Tarih Aralığı Filtreleme**: Başlangıç ve bitiş tarihi seçimi
- **Kullanıcı Bazlı Filtreleme**: Belirli kullanıcıların logları
- **Detaylı Raporlar**: Tanıma istatistikleri ve metrikleri
- **Grafik Görünümü**: Tanıma performansı grafikleri
- **Export Özelliği**: Raporları dışa aktarma

#### 📊 Rapor Türleri:
- **Genel Tanıma İstatistikleri**: Toplam tanıma sayısı, başarı oranı
- **Kullanıcı Bazlı Raporlar**: Her kullanıcının tanıma geçmişi
- **Tarih Bazlı Analizler**: Günlük, haftalık, aylık raporlar
- **Performans Metrikleri**: Threshold değerleri, doğruluk oranları

#### 🎯 Filtreleme Seçenekleri:
- **Tarih Aralığı**: Başlangıç ve bitiş tarihi
- **Kullanıcı Seçimi**: Belirli kullanıcıların logları
- **Tanıma Durumu**: Başarılı/başarısız tanımalar
- **Threshold Değerleri**: Belirli eşik değerleri

#### 📈 Görselleştirme:
- **Çizgi Grafikleri**: Tanıma performansı trendleri
- **Pasta Grafikleri**: Kullanıcı dağılımları
- **Bar Grafikleri**: Tarih bazlı tanıma sayıları
- **Tablo Görünümü**: Detaylı log listesi

### 👥 Kullanıcı Logları (UsersLogPage)
**Dosya**: `lib/pages/users_log_page.dart`

Kayıtlı kullanıcıları görüntüleme ve yönetme sayfası.

#### ✨ Özellikler:
- **Kullanıcı Listesi**: Tüm kayıtlı kullanıcıların listesi
- **Fotoğraf Görüntüleme**: Kullanıcı fotoğraflarının önizlemesi
- **Kullanıcı Yönetimi**: Silme, düzenleme işlemleri
- **Arama ve Filtreleme**: Kullanıcı arama özelliği
- **Detaylı Bilgiler**: Kullanıcı bilgileri ve istatistikleri

#### 📋 Kullanıcı Bilgileri:
- **Ad Soyad**: Kullanıcının tam adı
- **Kimlik No**: TC kimlik numarası
- **Doğum Tarihi**: Doğum tarihi
- **Kayıt Tarihi**: Sisteme kayıt tarihi
- **Fotoğraf Sayısı**: Kayıtlı fotoğraf sayısı

#### 🖼️ Fotoğraf Yönetimi:
- **Fotoğraf Önizleme**: Kullanıcı fotoğraflarının küçük resimleri
- **Büyük Görüntüleme**: Fotoğrafları tam boyutta görüntüleme
- **Fotoğraf Silme**: İstenmeyen fotoğrafları silme
- **Fotoğraf Ekleme**: Yeni fotoğraf ekleme

#### 🎯 Yönetim İşlemleri:
- **Kullanıcı Silme**: Kullanıcıyı sistemden kaldırma
- **Bilgi Güncelleme**: Kullanıcı bilgilerini düzenleme
- **Fotoğraf Yönetimi**: Fotoğraf ekleme/silme
- **İstatistik Görüntüleme**: Kullanıcı tanıma istatistikleri

#### 🔍 Arama ve Filtreleme:
- **Ad Soyad Arama**: Kullanıcı adına göre arama
- **Kimlik No Arama**: TC kimlik numarasına göre arama
- **Tarih Filtreleme**: Kayıt tarihine göre filtreleme
- **Durum Filtreleme**: Aktif/pasif kullanıcı filtreleme

## 🎯 Sayfa Geçişleri ve Navigasyon

### 📱 Ana Sayfa → Diğer Sayfalar
```
Ana Sayfa
├── Yüz Tanıma Yap → FaceRecognitionPage
├── Kişi Kaydet → AddUserPage  
├── Tanıma Sorgula → RecognitionQueryPage
└── Kullanıcı Logları → UsersLogPage
```

### 🔄 Sayfa İçi Navigasyon
- **Geri Butonu**: Her sayfada sol üst köşede
- **Ana Sayfa**: Geri butonu ile ana sayfaya dönüş
- **Sayfa İçi Geçişler**: Tab bar, drawer menu (varsa)

### 🎨 UI/UX Özellikleri
- **Responsive Tasarım**: Tüm ekran boyutlarına uyum
- **Material Design**: Modern Flutter tasarım dili
- **Animasyonlar**: Sayfa geçişlerinde smooth animasyonlar
- **Loading States**: Yükleme durumları için göstergeler
- **Error Handling**: Hata durumları için kullanıcı dostu mesajlar

## 📡 API Endpoints

### Temel Endpoints
```http
POST /add_user              # Kullanıcı ekleme
POST /recognize             # Yüz tanıma
GET /users                  # Kullanıcı listesi
DELETE /delete_user/{id}    # Kullanıcı silme
```

### Yeni Endpoints (v2.0)
```http
POST /analyze_lighting      # Işık durumu analizi
POST /optimize_threshold    # Threshold optimizasyonu
GET /realtime_logs          # Gerçek zamanlı loglar
POST /reset_recognition_session  # Oturum sıfırlama
```

## 🎯 Özellik Detayları

### Işık Detection Algoritması
1. **Histogram Analizi**: Görüntü parlaklık dağılımı
2. **Ortalama Parlaklık**: Genel ışık seviyesi
3. **Standart Sapma**: Kontrast analizi
4. **Piksel Oranları**: Karanlık/parlak piksel oranları

### Performans Optimizasyonları
- **Frame Debouncing**: Gereksiz frame işlemeyi önleme
- **Memory Management**: Otomatik bellek temizleme
- **Async Processing**: Asenkron görüntü işleme
- **Caching**: API yanıtlarını önbellekleme

## 🐛 Sorun Giderme

### Yaygın Sorunlar

#### Kamera Açılmıyor
```bash
# Android izinlerini kontrol edin
flutter clean
flutter pub get
```

#### API Bağlantı Hatası
```bash
# API'nin çalıştığından emin olun
python api.py

# Endpoint URL'lerini kontrol edin
lib/services/face_api_services.dart
```

#### Işık Detection Çalışmıyor
- Kamera izinlerinin verildiğinden emin olun
- API'nin `/analyze_lighting` endpoint'ini desteklediğini kontrol edin
- İnternet bağlantısını kontrol edin

## 📊 Performans Metrikleri

- **Tanıma Hızı**: ~1.5 saniye/frame
- **Işık Analizi**: ~2 saniye/analiz
- **Bellek Kullanımı**: ~50MB
- **CPU Kullanımı**: ~15-20%



## 🙏 Teşekkürler

- Tüm katkıda bulunanlar


---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!

**Not**: Bu uygulama eğitim amaçlı geliştirilmiştir. Ticari kullanım için gerekli lisansları almayı unutmayın.

## ��️ Proje Yapısı

```
my_faceapp/
├── lib/
│   ├── pages/                           # Uygulama sayfaları
│   │   ├── home_page.dart               # Ana sayfa - Uygulama giriş noktası
│   │   ├── face_recognition_page.dart   # Yüz tanıma - Ana özellik (ışık detection dahil)
│   │   ├── add_user_page.dart           # Kullanıcı ekleme - Form ve kamera entegrasyonu
│   │   ├── recognition_query_page.dart  # Tanıma sorgulama - Raporlar ve istatistikler
│   │   └── users_log_page.dart          # Kullanıcı logları - Kullanıcı yönetimi
│   ├── services/                        # Servis katmanı
│   │   ├── face_api_services.dart       # API servisleri - Backend iletişimi
│   │   └── connectivity_service.dart    # İnternet bağlantısı kontrolü
│   ├── utils/                           # Yardımcı sınıflar
│   │   └── colors.dart                  # Renk tanımları - UI renk paleti
│   ├── components/                      # Yeniden kullanılabilir bileşenler
│   │   └── components.dart              # Ortak UI bileşenleri
│   ├── model/                           # Veri modelleri
│   │   └── items_model.dart             # Veri modelleri
│   └── main.dart                        # Ana uygulama - Uygulama başlangıç noktası
├── assets/                              # Statik dosyalar
│   ├── face_detection_front.tflite      # TensorFlow Lite modeli
│   ├── face1.png, face2.png, ...        # Örnek yüz görselleri
│   └── icon.png                         # Uygulama ikonu
├── android/                             # Android platformu
│   ├── app/                             # Android uygulama
│   │   ├── src/                         # Kaynak kodlar
│   │   ├── build.gradle                 # Build konfigürasyonu
│   │   └── google-services.json         # Firebase konfigürasyonu
│   └── build.gradle                     # Proje build konfigürasyonu
├── ios/                                 # iOS platformu (varsa)
├── web/                                 # Web platformu
├── windows/                             # Windows platformu
├── api.py                               # Backend API - Python Flask uygulaması
├── requirements.txt                     # Python bağımlılıkları
├── pubspec.yaml                         # Flutter bağımlılıkları
├── pubspec.lock                         # Flutter bağımlılık kilidi
└── README.md                           # Bu dosya - Proje dokümantasyonu
```

### 📁 Dosya Açıklamaları

#### 🎯 Ana Sayfalar (`lib/pages/`)
- **`home_page.dart`**: Uygulamanın ana giriş sayfası, tüm özelliklere erişim sağlar
- **`face_recognition_page.dart`**: Gerçek zamanlı yüz tanıma, ışık detection, kamera kontrolleri
- **`add_user_page.dart`**: Yeni kullanıcı kaydı, form validasyonu, fotoğraf çekme
- **`recognition_query_page.dart`**: Tanıma geçmişi sorgulama, raporlar, istatistikler
- **`users_log_page.dart`**: Kullanıcı yönetimi, fotoğraf görüntüleme, kullanıcı listesi

#### 🔧 Servisler (`lib/services/`)
- **`face_api_services.dart`**: Backend API ile iletişim, HTTP istekleri, veri işleme
- **`connectivity_service.dart`**: İnternet bağlantısı kontrolü, bağlantı durumu yönetimi

#### 🎨 Yardımcı Sınıflar (`lib/utils/`, `lib/components/`)
- **`colors.dart`**: Uygulama renk paleti, tema renkleri
- **`components.dart`**: Yeniden kullanılabilir UI bileşenleri

#### 📊 Veri Modelleri (`lib/model/`)
- **`items_model.dart`**: Veri sınıfları, model tanımları

#### 🖼️ Statik Dosyalar (`assets/`)
- **`face_detection_front.tflite`**: TensorFlow Lite yüz tanıma modeli
- **`face*.png`**: Örnek yüz görselleri ve uygulama ikonları

#### 🔧 Konfigürasyon Dosyaları
- **`pubspec.yaml`**: Flutter bağımlılıkları ve proje konfigürasyonu
- **`requirements.txt`**: Python backend bağımlılıkları
- **`api.py`**: Python Flask backend API uygulaması

### 🏗️ Mimari Yapı

#### 📱 Frontend (Flutter)
```
lib/
├── main.dart                    # Uygulama başlangıç noktası
├── pages/                       # Sayfa bileşenleri
├── services/                    # İş mantığı servisleri
├── utils/                       # Yardımcı sınıflar
├── components/                  # UI bileşenleri
└── model/                       # Veri modelleri
```

#### 🐍 Backend (Python Flask)
```
api.py                          # Ana API uygulaması
├── FaceRecognitionAPI          # Yüz tanıma sınıfı
├── Endpoint handlers           # API endpoint'leri
├── Image processing            # Görüntü işleme
└── Database operations         # Veritabanı işlemleri
```

### 🔄 Veri Akışı

1. **Kullanıcı Etkileşimi** → Flutter UI
2. **İş Mantığı** → Service katmanı
3. **API İletişimi** → HTTP istekleri
4. **Backend İşleme** → Python Flask
5. **Veri Tabanı** → JSON dosyaları
6. **Yanıt** → Flutter UI'ya geri dönüş
