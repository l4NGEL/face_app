import 'package:flutter/material.dart';
import 'package:my_faceapp/home_page.dart';


void main() {
  runApp(FaceRecognitionApp());
}

class FaceRecognitionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yüz Tanıma Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const HomePage(),
    );
  }
}

