import 'package:flutter/material.dart';
import '../services/face_api_services.dart';
import '../services/connectivity_service.dart';

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with WidgetsBindingObserver {
  List<dynamic> users = [];
  Map<String, List<String>> userPhotos = {};
  bool isLoading = true;

  // 🎯 İnternet bağlantısı kontrolü
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInternetConnection();
    _connectivityService.startListening();
    fetchUsers();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkInternetConnection();
    }
  }

  Future<void> _checkInternetConnection() async {
    final isConnected = await _connectivityService.checkInternetConnection();
    if (!isConnected && mounted) {
      setState(() {
        _isConnected = false;
      });
      ConnectivityService.showNoInternetDialog(context);
    } else {
      setState(() {
        _isConnected = true;
      });
    }
  }

  void _navigateWithInternetCheck(VoidCallback navigation) async {
    final isConnected = await _connectivityService.checkInternetConnection();
    if (!isConnected) {
      ConnectivityService.showNoInternetSnackBar(context);
      return;
    }
    navigation();
  }

  Future<void> fetchUsers() async {
    setState(() { isLoading = true; });
    try {
      users = await FaceApiService.listUsers();


      for (var user in users) {
        final idNo = user['id_no'] ?? user['id'];
        try {
          print('🔄 Kullanıcı fotoğrafları isteniyor: $idNo');
          final photos = await FaceApiService.getUserPhotos(idNo);
          print('📸 Alınan fotoğraflar: $photos');
          userPhotos[idNo] = photos;
        } catch (e) {
          print('❌ Fotoğraf çekme hatası ($idNo): $e');
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

  Future<void> editUserName(String idNo, String currentName) async {
    final TextEditingController nameController = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kullanıcı Adını Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kimlik No: $idNo'),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
                hintText: 'Yeni adı giriniz',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context, newName);
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // API'ye kullanıcı adını güncelleme isteği gönder
        final updateResult = await FaceApiService.updateUserName(idNo, result);

        if (updateResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kullanıcı adı başarıyla güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          await fetchUsers(); // Listeyi yenile
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(updateResult['message'] ?? 'Güncelleme başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showUserPhotos(String idNo, String userName) async {
    try {
      // Kullanıcının tüm fotoğraflarını al
      final photos = await FaceApiService.getUserPhotos(idNo);

      // Orijinal fotoğrafları filtrele
      final originalPhotos = photos.where((photo) =>
      photo.contains('_original') ||
          (photo.contains('.jpg') && !photo.contains('_aug'))
      ).toList();

      if (originalPhotos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Orijinal fotoğraf bulunamadı')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$userName - Orijinal Fotoğraflar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                height: 400,
                child: PageView.builder(
                  itemCount: originalPhotos.length,
                  itemBuilder: (context, index) {
                    final photoName = originalPhotos[index];
                    final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/$photoName';

                    return Column(
                      children: [
                        Expanded(
                          child: InteractiveViewer(
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(child: Text('Fotoğraf yüklenemedi')),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Fotoğraf ${index + 1}/${originalPhotos.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePhoto(idNo, photoName, originalPhotos),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraflar yüklenemedi: $e')),
      );
    }
  }

  Future<void> _deletePhoto(String idNo, String photoName, List<String> allPhotos) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Fotoğrafı Sil'),
        content: Text('Bu orijinal fotoğrafı ve tüm augmented versiyonlarını silmek istediğinize emin misiniz?'),
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
      try {
        // Orijinal fotoğrafın numarasını bul (örn: 1_original.jpg -> 1)
        final photoNumber = photoName.split('_')[0];

        // Bu orijinal fotoğrafa ait tüm augmented fotoğrafları bul
        final relatedPhotos = allPhotos.where((photo) =>
        photo.startsWith('${photoNumber}_') ||
            photo == photoName
        ).toList();

        // API'ye silme isteği gönder
        final result = await FaceApiService.deleteUserPhotos(idNo, relatedPhotos);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fotoğraf ve augmented versiyonları silindi'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Dialog'u kapat
          await fetchUsers(); // Listeyi yenile
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Silme başarısız'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kullanıcılar')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (users.isEmpty) {
            return Center(child: Text('Kayıtlı kullanıcı yok.'));
          }

          return isLandscape
              ? _buildLandscapeLayout(constraints)
              : _buildPortraitLayout(constraints);
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BoxConstraints constraints) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final idNo = user['id_no'] ?? user['id'];
        final photos = userPhotos[idNo] ?? [];
        // Orijinal fotoğrafı bul (1_original.jpg varsa onu kullan, yoksa ilk fotoğrafı)
        final originalPhoto = photos.firstWhere(
                (photo) => photo.contains('_original'),
            orElse: () => photos.isNotEmpty ? photos.first : '1.jpg'
        );
        final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/$originalPhoto';

        print('👤 Kullanıcı: ${user['name']}');
        print('🆔 ID: $idNo');
        print('📸 Fotoğraflar: $photos');
        print('🎯 Orijinal fotoğraf: $originalPhoto');
        print('🔗 URL: $photoUrl');

        return ListTile(
          leading: GestureDetector(
            onTap: () => showUserPhotos(idNo, user['name'] ?? ''),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () => editUserName(idNo, user['name'] ?? ''),
              ),
              IconButton(
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout(BoxConstraints constraints) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (constraints.maxWidth / 300).floor().clamp(2, 4),
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final idNo = user['id_no'] ?? user['id'];
        final photos = userPhotos[idNo] ?? [];
        // Orijinal fotoğrafı bul (1_original.jpg varsa onu kullan, yoksa ilk fotoğrafı)
        final originalPhoto = photos.firstWhere(
                (photo) => photo.contains('_original'),
            orElse: () => photos.isNotEmpty ? photos.first : '1.jpg'
        );
        final photoUrl = '${FaceApiService.baseUrl}/user_photo/$idNo/$originalPhoto';

        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => showUserPhotos(idNo, user['name'] ?? ''),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(photoUrl),
                    radius: 30,
                    onBackgroundImageError: (_, __) {},
                    child: photos.isEmpty ? Icon(Icons.person, size: 30) : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user['name'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kimlik No: ${user['id_no'] ?? ''}',
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Doğum: ${user['birth_date'] ?? ''}',
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => editUserName(idNo, user['name'] ?? ''),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}