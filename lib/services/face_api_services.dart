import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class FaceApiService {
  static const String baseUrl = 'http://10.6.2.63:5000';// API adresini güncelle!

  static Future<Map<String, dynamic>> recognizeFace(File imageFile) async {
    final imageBase64 = await compressAndEncodeImage(imageFile);
    final response = await http.post(
      Uri.parse('$baseUrl/recognize'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image': imageBase64}),
    );
    return json.decode(response.body);
  }

  // DİKKAT: images parametresi artık List<String> (base64)!
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

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete_user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    return json.decode(response.body);
  }

  // Artık public!
  static Future<String> compressAndEncodeImage(File imageFile) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    final resized = img.copyResize(image!, width: 800, height: 800);
    final jpg = img.encodeJpg(resized, quality: 85);
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  }
}