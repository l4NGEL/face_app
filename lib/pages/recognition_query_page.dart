import 'package:flutter/material.dart';
import '../services/face_api_services.dart';

class RecognitionQueryPage extends StatefulWidget {
  @override
  _RecognitionQueryPageState createState() => _RecognitionQueryPageState();
}

class _RecognitionQueryPageState extends State<RecognitionQueryPage> {
  List<dynamic> users = [];
  Map<String, List<dynamic>> recognitionLogs = {};
  bool isLoading = true;
  String? selectedUserId;
  DateTime? startDate;
  DateTime? endDate;

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

  Future<void> fetchRecognitionLogs(String userId) async {
    try {
      final logs = await FaceApiService.getRecognitionLogs(userId);
      setState(() {
        recognitionLogs[userId] = logs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tanıma kayıtları alınamadı: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? DateTime.now().subtract(Duration(days: 7)) : DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  List<dynamic> getFilteredLogs(String userId) {
    final logs = recognitionLogs[userId] ?? [];
    if (startDate == null && endDate == null) return logs;

    return logs.where((log) {
      try {
        final logDate = DateTime.parse(log['datetime']);
        bool include = true;
        
        if (startDate != null) {
          include = include && logDate.isAfter(startDate!.subtract(Duration(days: 1)));
        }
        
        if (endDate != null) {
          include = include && logDate.isBefore(endDate!.add(Duration(days: 1)));
        }
        
        return include;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  void showRecognitionPhoto(String userId, String timestamp, String photoType) {
    final photoUrl = '${FaceApiService.baseUrl}/recognition_photos/$userId/$timestamp/$photoType';
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
      appBar: AppBar(
        title: Text('Tanıma Sorgu'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                recognitionLogs.clear();
                selectedUserId = null;
                startDate = null;
                endDate = null;
              });
              fetchUsers();
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
              
              // Sonuçlar bölümü
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
          onChanged: (value) {
            setState(() {
              selectedUserId = value;
            });
            if (value != null) {
              fetchRecognitionLogs(value);
            }
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
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text(
                        startDate != null 
                          ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                          : 'Başlangıç Tarihi',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
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
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text(
                        endDate != null 
                          ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                          : 'Bitiş Tarihi',
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
            onChanged: (value) {
              setState(() {
                selectedUserId = value;
              });
              if (value != null) {
                fetchRecognitionLogs(value);
              }
            },
          ),
        ),
        SizedBox(width: 16),
        
        // Tarih filtreleri
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
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      startDate != null 
                        ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
                        : 'Başlangıç Tarihi',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
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
                  Icon(Icons.calendar_today, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      endDate != null 
                        ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
                        : 'Bitiş Tarihi',
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
    final logs = getFilteredLogs(selectedUserId!);
    
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Bu tarih aralığında tanıma kaydı bulunamadı',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return isLandscape 
        ? _buildLandscapeLogsList(logs)
        : _buildPortraitLogsList(logs);
  }

  Widget _buildPortraitLogsList(List<dynamic> logs) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final timestamp = log['timestamp'];
        final photoUrls = log['photo_urls'] ?? {};
        
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      _formatDateTime(log['datetime']),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Fotoğraflar
                if (photoUrls.isNotEmpty)
                  Row(
                    children: [
                      if (photoUrls['full_image'] != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showRecognitionPhoto(
                              selectedUserId!,
                              timestamp,
                              'full_image.jpg',
                            ),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${FaceApiService.baseUrl}${photoUrls['full_image']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                      Center(child: Icon(Icons.error)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
                      if (photoUrls['face_crop'] != null)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => showRecognitionPhoto(
                              selectedUserId!,
                              timestamp,
                              'face_crop.jpg',
                            ),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${FaceApiService.baseUrl}${photoUrls['face_crop']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                      Center(child: Icon(Icons.error)),
                                ),
                              ),
                            ),
                          ),
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
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(12),
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
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                
                // Fotoğraflar
                if (photoUrls.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        if (photoUrls['full_image'] != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showRecognitionPhoto(
                                selectedUserId!,
                                timestamp,
                                'full_image.jpg',
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '${FaceApiService.baseUrl}${photoUrls['full_image']}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                        Center(child: Icon(Icons.error)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (photoUrls['full_image'] != null && photoUrls['face_crop'] != null)
                          SizedBox(width: 4),
                        if (photoUrls['face_crop'] != null)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => showRecognitionPhoto(
                                selectedUserId!,
                                timestamp,
                                'face_crop.jpg',
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '${FaceApiService.baseUrl}${photoUrls['face_crop']}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                        Center(child: Icon(Icons.error)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 