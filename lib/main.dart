import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(FaceRecognitionApp());
}

class FaceRecognitionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yüz Tanıma Sistemi',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}