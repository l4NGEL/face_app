import 'package:flutter/material.dart';

class PageHome extends StatelessWidget {
  const PageHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFDFB), // Arka plan
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            const Text(
              "Face App'e Hoş Geldiniz",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3A3A3A),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            // İlk tanıtım: face1.png
            Image.asset(
              'assets/face1.png',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 12),
            const Text(
              "Gerçek Zamanlı Yüz Tanıma",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3A3A),
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Kameradan alınan görüntülerle anlık tanıma yapar.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),



            const SizedBox(height: 32),

            // İkinci tanıtım: face2.png
            Image.asset(
              'assets/face2.png',
              width: 300,
              height: 300,
            ),
            const SizedBox(height: 12),
            const Text(
              "Yüksek Doğruluk ve Güvenli Eşleştirme",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A3A3A),
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Kişi tanımlamaları, özel yüz vektörleriyle güvenli şekilde yapılır.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),


            const SizedBox(height: 40),

            // Yönlendirme notu
            const Text(
              "Tanıma için sağa kaydırın\n"
                  "Kişi eklemek için sola kaydırın\n"
                  "Ana menüye iki kez dokunarak tanınan kişileri görüntüleyin",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18),

            ),
          ],
        ),
      ),
    );
  }
}
