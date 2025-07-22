import 'package:flutter/material.dart';
import '../services/face_api_services.dart';

class UsersPage extends StatefulWidget {
  @override
  State<UsersPage> createState() => _UsersPageState();
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
                    return ListTile(
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
                            await deleteUser(user['id']);
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 