import 'dart:convert';

// JSON'dan Book listesi parse etmek için yardımcı fonksiyon
List<Book> bookListFromJson(String str) =>
    List<Book>.from(json.decode(str).map((x) => Book.fromJson(x)));

// Tek bir Book objesini API'ye göndermek için JSON'a dönüştürmek için
String bookToJson(Book data) => json.encode(data.toJson());

class Book {
  final int? id; // Veritabanından gelince atanır (auto-increment)
  final String? isbn;
  final String title;
  final String author;
  final int? year; // bigint(20) -> int? (null olabilir)
  final String? publisher;
  final int ownerId; // user_id'ye karşılık gelir (kimin eklediği)
  final String?
  photoUrl; // Önceki koddan kalma, isterseniz kaldırılabilir veya kullanılabilir

  Book({
    this.id,
    this.isbn,
    required this.title,
    required this.author,
    this.year,
    this.publisher,
    required this.ownerId, // Bu zorunlu olmalı
    this.photoUrl,
  });

  // JSON Map'inden Book nesnesi oluşturan factory constructor
  // Backend API'sinin döndürdüğü JSON anahtarlarıyla eşleşmeli!
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    // API 'id' veya 'book_id' döndürebilir, kontrol etmek lazım
    id: json["id"] ?? json["book_id"],
    // JSON anahtarlarının backend'deki sütun adlarıyla aynı olduğunu varsayıyoruz
    isbn: json["isbn"],
    title: json["title"] ?? 'Başlık Yok',
    author: json["author"] ?? 'Yazar Yok',
    year: json["year"], // JSON'dan gelen sayısal değer int'e atanır
    publisher: json["publisher"],
    // 'user_id' veya 'owner_id' anahtarını kontrol et
    ownerId:
        json["user_id"] ??
        json["owner_id"] ??
        0, // Null gelmemeli, ama kontrol ekleyelim
    photoUrl: json["photo_url"],
  );

  // Book nesnesini API'ye (POST/PUT için) göndermek için JSON Map'ine dönüştüren metot
  // Backend API'sinin beklediği JSON anahtarlarıyla eşleşmeli!
  Map<String, dynamic> toJson() => {
    // 'id' genellikle POST isteğinde gönderilmez
    "isbn": isbn,
    "title": title,
    "author": author,
    "year": year,
    "publisher": publisher,
    "user_id": ownerId, // Backend'in beklediği anahtar 'user_id'
  };
}
