import 'package:flutter/material.dart';

class AppConstants {
  // Form sabitleri
  static const int ID_NO_LENGTH = 11;
  static const int BIRTH_DATE_LENGTH = 10;
  static const int MIN_PHOTOS = 1;
  static const int MAX_PHOTOS = 5;
  
  // UI Sabitleri
  static const double DEFAULT_PADDING = 16.0;
  static const double SMALL_PADDING = 8.0;
  static const double LARGE_PADDING = 24.0;
  
  // Kamera sabitleri
  static const double CAMERA_PREVIEW_HEIGHT = 300.0;
  static const double CAMERA_BUTTON_SIZE = 44.0;
  static const double PHOTO_THUMBNAIL_SIZE = 60.0;
  static const double PHOTO_THUMBNAIL_SIZE_LANDSCAPE = 50.0;
  
  // Renkler
  static const Color PRIMARY_COLOR = Colors.teal;
  static const Color SUCCESS_COLOR = Colors.green;
  static const Color ERROR_COLOR = Colors.red;
  static const Color WARNING_COLOR = Colors.orange;
  
  // Animasyon süreleri
  static const Duration SHORT_ANIMATION = Duration(milliseconds: 200);
  static const Duration MEDIUM_ANIMATION = Duration(milliseconds: 500);
  static const Duration LONG_ANIMATION = Duration(milliseconds: 1000);
  
  // Fotoğraf çekme gecikmesi
  static const Duration PHOTO_CAPTURE_DELAY = Duration(milliseconds: 500);
  
  // Form validasyon mesajları
  static const String NAME_REQUIRED = 'Ad Soyad zorunludur!';
  static const String ID_NO_INVALID = 'Kimlik numarası 11 haneli olmalıdır!';
  static const String BIRTH_DATE_REQUIRED = 'Doğum tarihi zorunludur!';
  static const String BIRTH_DATE_FORMAT = 'Doğum tarihi YYYY-AA-GG formatında olmalıdır! (Örnek: 1990-01-15)';
  static const String PHOTOS_MIN_REQUIRED = 'En az 1 fotoğraf çekmelisiniz!';
  static const String PHOTOS_MAX_EXCEEDED = 'En fazla 5 fotoğraf çekebilirsiniz!';
  
  // Başarı mesajları
  static const String USER_SAVED_SUCCESS = 'Kullanıcı başarıyla kaydedildi!';
  static const String PHOTOS_CAPTURED = 'Fotoğraflar başarıyla çekildi!';
  
  // Hata mesajları
  static const String SAVE_ERROR = 'Kayıt sırasında hata oluştu';
  static const String CAMERA_ERROR = 'Kamera başlatılamadı';
  static const String NETWORK_ERROR = 'İnternet bağlantısı yok!';
  
  // Buton metinleri
  static const String SAVE_BUTTON = 'Kaydet';
  static const String CAPTURE_BUTTON = 'Görüntü Al (5 Fotoğraf)';
  static const String SWITCH_CAMERA_BUTTON = 'Kamera Değiştir';
  static const String CANCEL_BUTTON = 'İptal';
  static const String CONFIRM_BUTTON = 'Onayla';
  
  // Loading metinleri
  static const String SAVING = 'Kaydediliyor...';
  static const String CAPTURING = 'Çekiliyor...';
  static const String LOADING = 'Yükleniyor...';
  
  // Form etiketleri
  static const String NAME_LABEL = 'Ad Soyad';
  static const String ID_NO_LABEL = 'Kimlik No';
  static const String BIRTH_DATE_LABEL = 'Doğum Tarihi (YYYY-AA-GG)';
  
  // Helper metinleri
  static const String ID_NO_HELPER = '11 haneli kimlik numarası giriniz';
  static const String BIRTH_DATE_HELPER = 'Sadece rakamları girin';
  static const String PHOTO_COUNT_TEXT = 'Yüz fotoğrafı çekin (en az 1, en fazla 5)';
  
  // Dialog başlıkları
  static const String IMAGE_PREVIEW_TITLE = 'Fotoğraf Önizleme';
  static const String DELETE_CONFIRM_TITLE = 'Fotoğrafı Sil';
  static const String DELETE_CONFIRM_MESSAGE = 'Bu fotoğrafı silmek istediğinize emin misiniz?';
  
  // API sabitleri
  static const String API_BASE_URL = 'http://10.6.2.63:5000';
  static const Duration API_TIMEOUT = Duration(seconds: 30);
  
  // Kamera çözünürlük ayarları
  static const Map<String, dynamic> CAMERA_RESOLUTION = {
    'width': 640,
    'height': 480,
  };
  
  // Fotoğraf kalite ayarları
  static const int PHOTO_QUALITY = 90;
  static const int PHOTO_MAX_WIDTH = 1024;
  static const int PHOTO_MAX_HEIGHT = 1024;
}
