import 'package:flutter/material.dart';
import '../services/face_api_services.dart';

class UsersPage extends StatefulWidget {
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final response = await FaceApiService.listUsers();
      setState(() {
        users = response;
      });
    } catch (e) {
      print("Kullanıcılar yüklenemedi: $e");
    }
  }

  void showFullImage(String userId) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Container(
          padding: EdgeInsets.all(8),
          child: Image.network(
            'http://10.0.2.2:5000/known_faces/$userId/1.jpg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tanınan Kullanıcılar')),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final name = user['name'] ?? '';
          final idNo = user['id_no'] ?? '-';
          final birthDate = user['birth_date'] ?? '-';
          final userId = user['id'];

          return ListTile(
            leading: GestureDetector(
              onTap: () => showFullImage(userId),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  'http://10.0.2.2:5000/known_faces/$userId/1.jpg',
                ),
              ),
            ),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kimlik No: $idNo'),
                Text('Doğum Tarihi: $birthDate'),
              ],
            ),
          );
        },
      ),
    );
  }
}
