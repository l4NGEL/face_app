import 'package:flutter/material.dart';

class ImageViewer extends StatelessWidget {
  final String imageUrl;

  const ImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fotoğrafı Görüntüle')),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
