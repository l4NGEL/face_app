import 'package:flutter/material.dart';
import '../services/face_api_services.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> users = [];
  Map<String, List<String>> userPhotos = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() { isLoading = true; });
    try {
      users = await FaceApiService.listUsers();
      
      // Her kullanıcının fotoğraflarını çek
      for (var user in users) {
        final idNo = user['id_no'] ?? user['id'];
        try {
          print('Kullanıcı fotoğrafları isteniyor: $idNo');
          final photos = await FaceApiService.getUserPhotos(idNo);
          print('Alınan fotoğraflar: $photos');
          userPhotos[idNo] = photos;
        } catch (e) {
          print('Fotoğraf çekme hatası ($idNo): $e');
          userPhotos[idNo] = [];
        }
      }
    } catch (e) {
      users = [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar alınamadı: $e')),
      );
    }
    setState(() { isLoading = false; });
  }

  Future<void> deleteUser(String idNo) async {
    final result = await FaceApiService.deleteUser(idNo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Kullanıcı silindi')),
    );
    await fetchUsers();
  }

  void showProfilePhoto(String idNo, String photoName) {
    final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/$photoName';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            photoUrl, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => 
                Center(child: Text('Fotoğraf yüklenemedi')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kullanıcılar')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? Center(child: Text('Kayıtlı kullanıcı yok.'))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final idNo = user['id_no'] ?? user['id'];
          final photos = userPhotos[idNo] ?? [];
          final firstPhoto = photos.isNotEmpty ? photos.first : '1.jpg';
          final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/$firstPhoto';
          
          return ListTile(
            leading: GestureDetector(
              onTap: () => showProfilePhoto(idNo, firstPhoto),
              child: CircleAvatar(
                backgroundImage: NetworkImage(photoUrl),
                radius: 28,
                onBackgroundImageError: (_, __) {},
                child: photos.isEmpty ? Icon(Icons.person) : null,
              ),
            ),
            title: Text(user['name'] ?? ''),
            subtitle: Text('Kimlik No: ${user['id_no'] ?? ''}\nDoğum Tarihi: ${user['birth_date'] ?? ''}'),
            isThreeLine: true,
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Kullanıcıyı Sil'),
                    content: Text('Bu kullanıcıyı silmek istediğinize emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Sil'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await deleteUser(idNo);
                }
              },
            ),
          );
        },
      ),
    );
  }
}