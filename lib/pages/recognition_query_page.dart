import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/face_api_services.dart';
import '../services/connectivity_service.dart';

class RecognitionQueryPage extends StatefulWidget {
  @override
  _RecognitionQueryPageState createState() => _RecognitionQueryPageState();
}

class _RecognitionQueryPageState extends State<RecognitionQueryPage> with WidgetsBindingObserver {
  List<dynamic> users = [];
  Map<String, List<dynamic>> recognitionLogs = {};
  bool isLoading = true;
  String? selectedUserId;
  DateTime? startDate;
  DateTime? endDate;

  // 🎯 İnternet bağlantısı kontrolü
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInternetConnection();
    _connectivityService.startListening();
    _initializeData();
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

  Future<void> _initializeData() async {
    await fetchUsers();
    // Kullanıcılar yüklendikten sonra tüm logları çek
    if (users.isNotEmpty) {
      await fetchRecognitionLogs(null);
    }
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

  Future<void> fetchRecognitionLogs(String? userId) async {
    try {
      print('🔍 fetchRecognitionLogs çağrıldı: userId = $userId');

      if (userId == null) {
        // Tüm kullanıcıların loglarını çek
        print('📊 Tüm kullanıcıların recognition logs çekiliyor');
        Map<String, List<dynamic>> allLogs = {};

        for (var user in users) {
          final idNo = user['id_no'] ?? user['id'];
          print('👤 Kullanıcı işleniyor: $idNo');
          try {
            final logs = await FaceApiService.getRecognitionLogs(idNo);
            print('📝 Kullanıcı $idNo için ${logs.length} log bulundu');
            if (logs.isNotEmpty) {
              allLogs[idNo] = logs;
            }
          } catch (e) {
            print('❌ Kullanıcı $idNo için log çekme hatası: $e');
          }
        }

        setState(() {
          recognitionLogs = allLogs;
        });
        print('✅ Toplam ${allLogs.length} kullanıcıdan log çekildi');
      } else {
        // Tek kullanıcının loglarını çek
        print('🎯 Tek kullanıcı recognition logs çekiliyor: $userId');
        final logs = await FaceApiService.getRecognitionLogs(userId);
        print('📝 Çekilen loglar: ${logs.length} adet');
        setState(() {
          recognitionLogs[userId] = logs;
        });
        print('✅ Tek kullanıcı logları güncellendi');
      }
    } catch (e) {
      print('💥 Recognition logs çekme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tanıma kayıtları alınamadı: $e')),
      );
    }
  }

  Future<void> deleteRecognitionLog(String userId, String timestamp) async {
    try {
      // API'den silme işlemi yapılacak (henüz API endpoint'i yok)
      // Şimdilik sadece local state'den kaldırıyoruz
      setState(() {
        final logs = recognitionLogs[userId] ?? [];
        recognitionLogs[userId] = logs.where((log) => log['timestamp'] != timestamp).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tanıma kaydı silindi'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Geri Al',
            textColor: Colors.white,
            onPressed: () {
              // Geri alma işlemi için logları yeniden yükle
              fetchRecognitionLogs(userId);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (startDate ?? DateTime.now().subtract(Duration(days: 7)))
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'), // 🎯 Türkçe tarih formatı - artık destekleniyor
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          // 🎯 Başlangıç tarihi seçildiğinde, bitiş tarihi başlangıçtan küçükse temizle
          if (endDate != null && endDate!.isBefore(picked)) {
            endDate = null;
          }
        } else {
          endDate = picked;
          // 🎯 Bitiş tarihi seçildiğinde, başlangıç tarihi bitişten büyükse temizle
          if (startDate != null && startDate!.isAfter(picked)) {
            startDate = null;
          }
        }
      });

      print('📅 ${isStartDate ? "Başlangıç" : "Bitiş"} tarihi seçildi: ${picked.day}/${picked.month}/${picked.year}');
    }
  }

  List<dynamic> getFilteredLogs(String? userId) {
    List<dynamic> allLogs = [];

    if (userId == null) {
      // Tüm kullanıcıların loglarını birleştir
      recognitionLogs.forEach((userId, logs) {
        for (var log in logs) {
          allLogs.add({
            ...log,
            'user_id': userId, // Hangi kullanıcıya ait olduğunu belirt
          });
        }
      });
      print('📊 Tüm kullanıcılar için toplam ${allLogs.length} log');
    } else {
      // Tek kullanıcının logları
      allLogs = recognitionLogs[userId] ?? [];
      print('📊 Kullanıcı $userId için ${allLogs.length} log');
    }

    if (startDate == null && endDate == null) {
      print('📅 Tarih filtresi yok, tüm loglar döndürülüyor');
      return allLogs;
    }

    print('🎯 Tarih filtreleme başlıyor:');
    print('   Başlangıç tarihi: ${startDate?.day}/${startDate?.month}/${startDate?.year}');
    print('   Bitiş tarihi: ${endDate?.day}/${endDate?.month}/${endDate?.year}');

    final filteredLogs = allLogs.where((log) {
      try {
        // 🎯 datetime alanını kontrol et - farklı formatlar olabilir
        String? dateString = log['datetime'] ?? log['timestamp'] ?? log['date'];
        if (dateString == null) {
          print('❌ Tarih alanı bulunamadı: ${log.keys}');
          return false;
        }

        DateTime logDate;

        // 🎯 Farklı tarih formatlarını destekle
        if (dateString.contains('T')) {
          // ISO format: "2024-01-15T10:30:00"
          logDate = DateTime.parse(dateString);
        } else if (dateString.contains('-')) {
          // Date format: "2024-01-15"
          logDate = DateTime.parse(dateString);
        } else {
          // Unix timestamp veya diğer formatlar
          try {
            final timestamp = int.tryParse(dateString);
            if (timestamp != null) {
              logDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            } else {
              logDate = DateTime.parse(dateString);
            }
          } catch (e) {
            print('❌ Tarih parse hatası: $dateString - $e');
            return false;
          }
        }

        bool include = true;

        // 🎯 Başlangıç tarihi kontrolü - gün bazında
        if (startDate != null) {
          final startOfDay = DateTime(startDate!.year, startDate!.month, startDate!.day);
          final logStartOfDay = DateTime(logDate.year, logDate.month, logDate.day);
          include = include && (logStartOfDay.isAtSameMomentAs(startOfDay) || logStartOfDay.isAfter(startOfDay));
        }

        // 🎯 Bitiş tarihi kontrolü - gün bazında
        if (endDate != null) {
          final endOfDay = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
          final logStartOfDay = DateTime(logDate.year, logDate.month, logDate.day);
          include = include && (logStartOfDay.isAtSameMomentAs(DateTime(endDate!.year, endDate!.month, endDate!.day)) || logStartOfDay.isBefore(endOfDay));
        }

        return include;
      } catch (e) {
        print('❌ Tarih parse hatası: $e - Log: ${log['datetime'] ?? log['timestamp'] ?? log['date']}');
        return false;
      }
    }).toList();

    print('📅 Filtrelenmiş log sayısı: ${filteredLogs.length}');
    return filteredLogs;
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  String _getUserName(String userId) {
    try {
      final user = users.firstWhere(
            (user) => (user['id_no'] ?? user['id']) == userId,
        orElse: () => {'name': 'Bilinmeyen Kullanıcı'},
      );
      return user['name'] ?? 'Bilinmeyen Kullanıcı';
    } catch (e) {
      return 'Bilinmeyen Kullanıcı';
    }
  }

  void showRecognitionPhoto(String userId, String timestamp, String photoType, {String? base64Data}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: base64Data != null && base64Data.isNotEmpty
              ? Image.memory(
            base64Decode(base64Data),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Center(child: Text('Fotoğraf yüklenemedi')),
          )
              : Image.network(
            '${FaceApiService.baseUrl}/recognition_photos/$userId/$timestamp/$photoType',
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
      appBar: AppBar(
        title: Text('Tanıma Sorgu'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                recognitionLogs.clear();
                selectedUserId = null;
                startDate = null;
                endDate = null;
              });
              await _initializeData();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Column(
            children: [
              // Filtre bölümü
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: isLandscape
                    ? _buildLandscapeFilters()
                    : _buildPortraitFilters(),
              ),


              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : selectedUserId == null
                    ? Center(child: Text('Sorgulamak için bir kullanıcı seçin'))
                    : _buildRecognitionLogsList(isLandscape),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPortraitFilters() {
    return Column(
      children: [
        // Kullanıcı seçimi
        DropdownButtonFormField<String>(
          value: selectedUserId,
          decoration: InputDecoration(
            labelText: 'Kullanıcı Seçin',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tüm Kullanıcılar'),
            ),
            ...users.map((user) {
              final idNo = user['id_no'] ?? user['id'];
              return DropdownMenuItem<String>(
                value: idNo,
                child: Text('${user['name']} (${idNo})'),
              );
            }).toList(),
          ],
          onChanged: (value) async {
            print('🎯 Kullanıcı seçildi: $value');
            setState(() {
              selectedUserId = value;
            });

            // Kullanıcı seçildikten sonra logları çek
            await fetchRecognitionLogs(value);
          },
        ),
        SizedBox(height: 16),

        // Tarih filtreleri
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          startDate != null
                              ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                              : 'Başlangıç',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          endDate != null
                              ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                              : 'Bitiş',
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeFilters() {
    return Row(
      children: [
        // Kullanıcı seçimi
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: selectedUserId,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Seçin',
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text('Tüm Kullanıcılar'),
              ),
              ...users.map((user) {
                final idNo = user['id_no'] ?? user['id'];
                return DropdownMenuItem<String>(
                  value: idNo,
                  child: Text('${user['name']} (${idNo})'),
                );
              }).toList(),
            ],
            onChanged: (value) async {
              print('🎯 Kullanıcı seçildi (landscape): $value');
              setState(() {
                selectedUserId = value;
              });

              // Kullanıcı seçildikten sonra logları çek
              await fetchRecognitionLogs(value);
            },
          ),
        ),
        SizedBox(width: 16),

        // Tarih filtreleri
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, true),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      startDate != null
                          ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                          : 'Başlangıç',
                      style: TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => _selectDate(context, false),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      endDate != null
                          ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                          : 'Bitiş',
                      style: TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecognitionLogsList(bool isLandscape) {
    final logs = getFilteredLogs(selectedUserId);

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              selectedUserId == null
                  ? 'Hiç tanıma kaydı bulunamadı'
                  : _getEmptyMessage(),
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (startDate != null || endDate != null) ...[
              SizedBox(height: 8),
              Text(
                _getDateRangeText(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // 🎯 Filtreleme bilgisi
        if (startDate != null || endDate != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: Colors.blue[700]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📅 ${_getDateRangeText()} - ${logs.length} kayıt bulundu',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                    });
                  },
                  child: Icon(Icons.clear, size: 16, color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        Expanded(
          child: isLandscape
              ? _buildLandscapeLogsList(logs)
              : _buildPortraitLogsList(logs),
        ),
      ],
    );
  }

  // 🎯 Tarih aralığı metni
  String _getDateRangeText() {
    if (startDate != null && endDate != null) {
      return '${startDate!.day}/${startDate!.month}/${startDate!.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year}';
    } else if (startDate != null) {
      return '${startDate!.day}/${startDate!.month}/${startDate!.year} tarihinden itibaren';
    } else if (endDate != null) {
      return '${endDate!.day}/${endDate!.month}/${endDate!.year} tarihine kadar';
    }
    return '';
  }

  // 🎯 Boş mesaj metni
  String _getEmptyMessage() {
    if (startDate != null || endDate != null) {
      return 'Bu tarih aralığında tanıma kaydı bulunamadı';
    } else {
      return 'Bu kullanıcı için tanıma kaydı bulunamadı';
    }
  }

  Widget _buildPortraitLogsList(List<dynamic> logs) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final timestamp = log['timestamp'];
        final photoUrls = log['photo_urls'] ?? {};

        return Dismissible(
          key: Key(timestamp),
          direction: DismissDirection.endToStart, // Sağdan sola kaydır
          background: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white, size: 30),
                SizedBox(height: 4),
                Text(
                  'Sil',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Kaydı Sil'),
                  content: Text('Bu tanıma kaydını silmek istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            final userId = selectedUserId ?? log['user_id'];
            if (userId != null) {
              deleteRecognitionLog(userId, timestamp);
            }
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar - Küçük fotoğraf
                      if (log['full_base64'] != null && log['full_base64'].isNotEmpty)
                        GestureDetector(
                          onTap: () => showRecognitionPhoto(
                            selectedUserId ?? log['user_id'],
                            timestamp,
                            'full_image.jpg',
                            base64Data: log['full_base64'],
                          ),
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.memory(
                                base64Decode(log['full_base64']),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person, color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      else if (photoUrls.isNotEmpty && photoUrls['full_image'] != null)
                        GestureDetector(
                          onTap: () => showRecognitionPhoto(
                            selectedUserId ?? log['user_id'],
                            timestamp,
                            'full_image.jpg',
                          ),
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                '${FaceApiService.baseUrl}${photoUrls['full_image']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person, color: Colors.grey),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 50,
                          height: 50,
                          margin: EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.grey[200],
                          ),
                          child: Icon(Icons.person, color: Colors.grey),
                        ),

                      // Bilgiler
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(log['datetime']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (selectedUserId == null && log['user_id'] != null)
                              Text(
                                'Kullanıcı: ${_getUserName(log['user_id'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLogsList(List<dynamic> logs) {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: (MediaQuery.of(context).size.width / 400).floor().clamp(2, 3),
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final timestamp = log['timestamp'];
        final photoUrls = log['photo_urls'] ?? {};

        return Dismissible(
          key: Key(timestamp),
          direction: DismissDirection.endToStart, // Sağdan sola kaydır
          background: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'Sil',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Kaydı Sil'),
                  content: Text('Bu tanıma kaydını silmek istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            final userId = selectedUserId ?? log['user_id'];
            if (userId != null) {
              deleteRecognitionLog(userId, timestamp);
            }
          },
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar - Küçük fotoğraf
                      if (log['full_base64'] != null && log['full_base64'].isNotEmpty)
                        GestureDetector(
                          onTap: () => showRecognitionPhoto(
                            selectedUserId ?? log['user_id'],
                            timestamp,
                            'full_image.jpg',
                            base64Data: log['full_base64'],
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(
                                base64Decode(log['full_base64']),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person, color: Colors.grey, size: 16),
                              ),
                            ),
                          ),
                        )
                      else if (photoUrls.isNotEmpty && photoUrls['full_image'] != null)
                        GestureDetector(
                          onTap: () => showRecognitionPhoto(
                            selectedUserId ?? log['user_id'],
                            timestamp,
                            'full_image.jpg',
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                '${FaceApiService.baseUrl}${photoUrls['full_image']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.person, color: Colors.grey, size: 16),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                            color: Colors.grey[200],
                          ),
                          child: Icon(Icons.person, color: Colors.grey, size: 16),
                        ),

                      // Bilgiler
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time, color: Colors.blue, size: 12),
                                SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    _formatDateTime(log['datetime']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (selectedUserId == null && log['user_id'] != null)
                              Text(
                                '${_getUserName(log['user_id'])}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 