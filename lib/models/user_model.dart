// lib/models/user_model.dart
import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) =>
    json.encode(data.toJsonForUpdate()); // Güncelleme için farklı olabilir

class User {
  final int id; // user_id'ye karşılık gelir
  final String name;
  final String email;
  final String? profilePictureUrl; // Opsiyonel

  // Client tarafında şifre tutulmaz!
  // Sadece login/register isteği için geçici olarak kullanılabilir.

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    // API'den dönecek anahtarlarla eşleşmeli (Python'da ne döndürüyorsanız)
    id: json["user_id"] ?? json["id"] ?? 0, // user_id veya id olabilir
    name: json["name"] ?? 'İsim Yok',
    email: json["email"] ?? 'E-posta Yok',
    profilePictureUrl: json["profile_picture_url"],
  );

  // Kullanıcı bilgilerini güncellemek için API'ye gönderilecek JSON
  Map<String, dynamic> toJsonForUpdate() => {
    "name": name,
    "email": email,
    "profile_picture_url": profilePictureUrl,
    // Şifre güncelleme ayrı bir endpoint/mantıkla yapılmalı
  };
}
