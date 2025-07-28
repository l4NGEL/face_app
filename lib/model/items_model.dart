class Items {
  final String img;
  final String title;
  final String subTitle;

  Items({
    required this.img,
    required this.title,
    required this.subTitle,
  });
}

List<Items> listOfItems = [
  Items(
    img: "assets/face1.png",
    title: "Yüz fotoğrafıyla kişi kaydı",
    subTitle:
    "Ad, kimlik ve yüz görseliyle kişileri hızlı, güvenli ve kolayca sisteme ekleyin.",
  ),
  Items(
    img: "assets/face2.png",
    title: "Gerçek zamanlı yüz tanıma",
    subTitle:
    "Kamera görüntüsüyle kişileri anında tanıyın. Yapay zeka ile desteklenen hızlı tanıma.",
  ),
  Items(
    img: "assets/face4.png",
    title: "Doğru ve güvenli doğrulama",
    subTitle:
    "",
  ),
];


