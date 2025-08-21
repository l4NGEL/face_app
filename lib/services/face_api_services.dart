import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class FaceApiService {
  static const String baseUrl = 'http://10.6.2.63:5000';// API adresini güncelle!
  /*static const String baseUrl = 'http://192.168.1.167:5000';*/
  
  // Web için kamera erişimi
  static Future<html.MediaStream?> getWebCameraStream() async {
    if (kIsWeb) {
      try {
        final stream = await html.window.navigator.mediaDevices?.getUserMedia({
          'video': {
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
            'facingMode': 'user' // Ön kamera
          }
        });
        return stream;
      } catch (e) {
        print('Web kamera erişim hatası: $e');
        return null;
      }
    }
    return null;
  }

  // Web için kamera izinlerini kontrol et
  static Future<bool> checkWebCameraPermissions() async {
    if (kIsWeb) {
      try {
        final stream = await html.window.navigator.mediaDevices?.getUserMedia({'video': true});
        if (stream != null) {
          stream.getTracks().forEach((track) => track.stop());
          return true;
        }
      } catch (e) {
        print('Web kamera izin hatası: $e');
        return false;
      }
    }
    return false;
  }

  // Web için kamera durumunu kontrol et
  static Future<Map<String, dynamic>> getWebCameraStatus() async {
    if (kIsWeb) {
      try {
        final devices = await html.window.navigator.mediaDevices?.enumerateDevices();
        final videoDevices = devices?.where((device) => device.kind == 'videoinput').toList() ?? [];
        
        return {
          'available': videoDevices.isNotEmpty,
          'count': videoDevices.length,
          'devices': videoDevices.map((d) => d.label).toList(),
          'permissions': await checkWebCameraPermissions(),
        };
      } catch (e) {
        return {
          'available': false,
          'error': e.toString(),
        };
      }
    }
    return {'available': false, 'platform': 'not_web'};
  }

  // Web için kamera izinlerini zorla
  static Future<bool> requestWebCameraPermissions() async {
    if (kIsWeb) {
      try {
        final stream = await html.window.navigator.mediaDevices?.getUserMedia({
          'video': {
            'width': {'ideal': 640},
            'height': {'ideal': 480},
            'facingMode': 'user'
          }
        });
        
        if (stream != null) {
          // Stream'i hemen durdur
          stream.getTracks().forEach((track) => track.stop());
          return true;
        }
        return false;
      } catch (e) {
        print('Web kamera izin hatası: $e');
        return false;
      }
    }
    return false;
  }

  // Web için kamera test et
  static Future<Map<String, dynamic>> testWebCamera() async {
    if (kIsWeb) {
      try {
        final status = await getWebCameraStatus();
        final permissions = await requestWebCameraPermissions();
        
        return {
          'success': true,
          'status': status,
          'permissions_granted': permissions,
          'message': permissions ? 'Kamera erişimi başarılı' : 'Kamera izinleri reddedildi',
        };
      } catch (e) {
        return {
          'success': false,
          'error': e.toString(),
          'message': 'Kamera test edilemedi',
        };
      }
    }
    return {
      'success': false,
      'message': 'Web platformu değil',
    };
  }

  static Future<Map<String, dynamic>> recognizeFace(File imageFile) async {
    final imageBase64 = await compressAndEncodeImage(imageFile);
    final response = await http.post(
      Uri.parse('$baseUrl/recognize'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image': imageBase64}),
    );
    return json.decode(response.body);
  }


  static Future<Map<String, dynamic>> addUser(
      String name, String idNo, String birthDate, List<String> imagesBase64) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_user'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'id_no': idNo,
        'birth_date': birthDate,
        'images': imagesBase64,
      }),
    );
    return json.decode(response.body);
  }

  static Future<List<dynamic>> listUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['users'] ?? [];
    } else {
      throw Exception('Kullanıcılar alınamadı');
    }
  }

  static Future<List<dynamic>> getUserLogs(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user_logs/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['logs'] ?? [];
    } else {
      throw Exception('Loglar alınamadı');
    }
  }

  static Future<List<dynamic>> getRecognitionLogs(String userId) async {
    try {
      print('Recognition logs API çağrısı: $baseUrl/recognition_logs/$userId');

      // Önce test endpoint'ini çağır
      final testResponse = await http.get(
        Uri.parse('$baseUrl/test_recognition_logs/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Test endpoint yanıtı: ${testResponse.statusCode} - ${testResponse.body}');

      final response = await http.get(
        Uri.parse('$baseUrl/recognition_logs/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Recognition logs yanıt kodu: ${response.statusCode}');
      print('Recognition logs yanıtı: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logs = data['logs'] ?? [];
        print('Çözümlenen loglar: ${logs.length} adet');
        return logs;
      } else {
        print('Recognition logs API hatası: ${response.statusCode} - ${response.body}');
        throw Exception('Tanıma logları alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('Recognition logs hata yakalandı: $e');
      throw Exception('Tanıma logları alınamadı: $e');
    }
  }

  static Future<Map<String, dynamic>> resetRecognitionSession() async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset_recognition_session'),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getRealtimeRecognitionLogs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/realtime_recognition_logs'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body)['logs'] ?? [];
    } else {
      throw Exception('Gerçek zamanlı loglar alınamadı');
    }
  }



  static Future<Map<String, dynamic>> recalculateUserEmbeddings(String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recalculate_embeddings/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Embeddings yeniden hesaplanamadı');
    }
  }

  static Future<Map<String, dynamic>> recalculateAllEmbeddings() async {
    final response = await http.post(
      Uri.parse('$baseUrl/recalculate_all_embeddings'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Tüm embeddings yeniden hesaplanamadı');
    }
  }

  static Future<Map<String, dynamic>> deleteUserPhoto(String idNo, String filename) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user_photos/$idNo/$filename'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fotoğraf silinemedi');
    }
  }

  static Future<Map<String, dynamic>> clearUserPhotos(String idNo) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/user_photos/$idNo/clear'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Fotoğraflar silinemedi');
    }
  }

  static Future<Map<String, dynamic>> uploadUserPhoto(String idNo, File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user_photos/$idNo'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Fotoğraf yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fotoğraf yüklenemedi: $e');
    }
  }

  static Future<Map<String, dynamic>> fixJsonFile() async {
    final response = await http.post(
      Uri.parse('$baseUrl/fix_json'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('JSON dosyası düzeltilemedi');
    }
  }

  // Threshold bilgilerini al
  static Future<Map<String, dynamic>> getThresholdInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/threshold_info'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Threshold bilgileri alınamadı');
    }
  }

  // Threshold istatistiklerini sıfırla
  static Future<Map<String, dynamic>> resetThresholdStats() async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset_threshold_stats'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Threshold istatistikleri sıfırlanamadı');
    }
  }

  // Manuel threshold ayarı
  static Future<Map<String, dynamic>> adjustThreshold(double threshold) async {
    final response = await http.post(
      Uri.parse('$baseUrl/adjust_threshold'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'threshold': threshold}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Threshold ayarlanamadı');
    }
  }

  // Görüntü kalitesi analizi
  static Future<Map<String, dynamic>> analyzeImageQuality(File imageFile) async {
    final imageBase64 = await compressAndEncodeImage(imageFile);
    final response = await http.post(
      Uri.parse('$baseUrl/analyze_image_quality'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image': imageBase64}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Görüntü kalitesi analiz edilemedi');
    }
  }

  // Dinamik threshold test
  static Future<Map<String, dynamic>> testDynamicThreshold(File imageFile) async {
    final imageBase64 = await compressAndEncodeImage(imageFile);
    final response = await http.post(
      Uri.parse('$baseUrl/test_dynamic_threshold'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image': imageBase64}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Dinamik threshold test edilemedi');
    }
  }

  static Future<Map<String, dynamic>> checkJsonStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/check_json_status'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('JSON durumu kontrol edilemedi');
    }
  }

  static Future<List<String>> getUserPhotos(String idNo) async {
    try {
      print('API çağrısı yapılıyor: $baseUrl/user_photos/$idNo');


      final testResponse = await http.get(
        Uri.parse('$baseUrl/test_user_photos/$idNo'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Test endpoint yanıtı: ${testResponse.statusCode} - ${testResponse.body}');

      final response = await http.get(
        Uri.parse('$baseUrl/user_photos/$idNo'),
        headers: {'Content-Type': 'application/json'},
      );
      print('API yanıt kodu: ${response.statusCode}');
      print('API yanıtı: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = List<String>.from(data['photos'] ?? []);
        print('Çözümlenen fotoğraflar: $photos');
        return photos;
      } else {
        print('API hatası: ${response.statusCode} - ${response.body}');
        throw Exception('Kullanıcı fotoğrafları alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      print('Hata yakalandı: $e');
      throw Exception('Kullanıcı fotoğrafları alınamadı: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteUserPhotos(String idNo, List<String> photoNames) async {
    try {
      print('Fotoğraf silme API çağrısı: $baseUrl/user_photos/$idNo/delete');
      print('Silinecek fotoğraflar: $photoNames');

      final response = await http.post(
        Uri.parse('$baseUrl/user_photos/$idNo/delete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'photo_names': photoNames}),
      );

      print('Silme API yanıt kodu: ${response.statusCode}');
      print('Silme API yanıtı: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Silme başarılı: ${data['deleted_count']} fotoğraf silindi');
        return data;
      } else {
        print('Silme API hatası: ${response.statusCode} - ${response.body}');
        throw Exception('Fotoğraflar silinemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Silme hatası yakalandı: $e');
      throw Exception('Fotoğraflar silinemedi: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> updateUserName(String userId, String newName) async {
    try {
      print('🔄 updateUserName çağrıldı: userId=$userId, newName=$newName');
      print('🔗 API URL: $baseUrl/update_user_name/$userId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/update_user_name/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': newName}),
      );
      
      print('📡 API yanıt kodu: ${response.statusCode}');
      print('📄 API yanıtı: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Başarılı güncelleme: $result');
        return result;
      } else {
        print('❌ API hatası: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'Kullanıcı adı güncellenemedi: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('❌ updateUserName hatası: $e');
      return {
        'success': false,
        'message': 'Kullanıcı adı güncellenemedi: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> optimizeThreshold() async {
    try {
      print('🔧 Threshold optimizasyonu başlatılıyor...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/optimize_threshold'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Threshold optimizasyonu tamamlandı: ${result['optimal_threshold']}');
        return result;
      } else {
        print('❌ Threshold optimizasyonu başarısız: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Threshold optimizasyonu başarısız: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Threshold optimizasyonu hatası: $e');
      return {
        'success': false,
        'message': 'Threshold optimizasyonu hatası: $e',
      };
    }
  }


  static Future<String> compressAndEncodeImage(File imageFile) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    // Yüksek kalite için daha büyük boyut ve daha yüksek kalite
    final resized = img.copyResize(image!, width: 1024, height: 1024);
    final jpg = img.encodeJpg(resized, quality: 90); // Kaliteyi 90'a çıkar
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  }

  static Future<Map<String, dynamic>> testCameraQuality(File imageFile) async {
    final imageBase64 = await compressAndEncodeImage(imageFile);
    final response = await http.post(
      Uri.parse('$baseUrl/test_camera_quality'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image': imageBase64}),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> testThreshold(File imageFile) async {
    final imageBase64 = await compressAndEncodeImage(imageFile);
    final response = await http.post(
      Uri.parse('$baseUrl/test_threshold'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image': imageBase64}),
    );
    return json.decode(response.body);
  }
}