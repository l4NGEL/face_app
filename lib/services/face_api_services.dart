import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class FaceApiService {
  static const String baseUrl = '...';// API adresini güncelle!

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

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }


  static Future<String> compressAndEncodeImage(File imageFile) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    final resized = img.copyResize(image!, width: 800, height: 800);
    final jpg = img.encodeJpg(resized, quality: 85);
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  }
}
