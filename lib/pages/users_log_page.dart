import 'package:flutter/material.dart';
import '../services/face_api_services.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> users = [];
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

  void showProfilePhoto(String idNo) {
    final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/1.jpg';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(photoUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void showProfileGallery(String idNo) {
    final List<String> photoUrls = List.generate(
      5,
      (i) => '${FaceApiService.baseUrl}/user_photo/$idNo/${i + 1}.jpg',
    );
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 320,
          height: 400,
          child: PageView.builder(
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return Image.network(
                photoUrls[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Center(child: Text('Fotoğraf yok')),
              );
            },
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
          final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/1.jpg';
          return ListTile(
            leading: GestureDetector(
              onTap: () => showProfileGallery(idNo),
              child: CircleAvatar(
                backgroundImage: NetworkImage(photoUrl),
                radius: 28,
                onBackgroundImageError: (_, __) {},
                child: Icon(Icons.person),
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