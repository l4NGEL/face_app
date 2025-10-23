import 'dart:io';

class UserValidationService {
  static const int MIN_PHOTOS = 1;
  static const int MAX_PHOTOS = 5;
  static const int ID_NO_LENGTH = 11;
  static const int BIRTH_DATE_LENGTH = 10;

  /// Kullanıcı verilerini doğrula
  static ValidationResult validateUser({
    required String name,
    required String idNo,
    required String birthDate,
    required List<File> faceImages,
  }) {
    // Ad soyad kontrolü
    if (name.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Ad Soyad zorunludur!',
      );
    }

    // Kimlik numarası kontrolü
    if (idNo.length != ID_NO_LENGTH) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Kimlik numarası 11 haneli olmalıdır!',
      );
    }

    // Doğum tarihi kontrolü
    if (birthDate.isEmpty) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Doğum tarihi zorunludur!',
      );
    }

    // Doğum tarihi format kontrolü
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(birthDate)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Doğum tarihi YYYY-AA-GG formatında olmalıdır! (Örnek: 1990-01-15)',
      );
    }

    // Tarih geçerliliği kontrolü
    final dateValidation = _validateDate(birthDate);
    if (!dateValidation.isValid) {
      return dateValidation;
    }

    // Fotoğraf kontrolü
    if (faceImages.length < MIN_PHOTOS) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'En az $MIN_PHOTOS fotoğraf çekmelisiniz!',
      );
    }

    if (faceImages.length > MAX_PHOTOS) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'En fazla $MAX_PHOTOS fotoğraf çekebilirsiniz!',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Tarih geçerliliğini kontrol et
  static ValidationResult _validateDate(String birthDate) {
    try {
      final parts = birthDate.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Yıl kontrolü
      if (year < 1900 || year > DateTime.now().year) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Geçerli bir yıl giriniz! (1900-${DateTime.now().year})',
        );
      }

      // Ay kontrolü
      if (month < 1 || month > 12) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Geçerli bir ay giriniz! (01-12)',
        );
      }

      // Gün kontrolü
      if (day < 1 || day > 31) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Geçerli bir gün giriniz! (01-31)',
        );
      }

      // DateTime ile geçerlilik kontrolü
      final birthDateTime = DateTime(year, month, day);
      if (birthDateTime.isAfter(DateTime.now())) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Doğum tarihi gelecekte olamaz!',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Geçersiz tarih formatı!',
      );
    }
  }

  /// Kimlik numarası formatını kontrol et
  static bool isValidIdNo(String idNo) {
    if (idNo.length != ID_NO_LENGTH) return false;
    return RegExp(r'^\d{11}$').hasMatch(idNo);
  }

  /// Ad soyad formatını kontrol et
  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }
}

/// Doğrulama sonucu sınıfı
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
