import 'dart:convert';

// JSON'dan Meeting listesi parse etmek için yardımcı fonksiyon
List<Meeting> meetingListFromJson(String str) =>
    List<Meeting>.from(json.decode(str).map((x) => Meeting.fromJson(x)));

String meetingToJson(Meeting data) => json.encode(data.toJson());

class Meeting {
  final int id;
  final int offerId; // Hangi teklife istinaden yapıldığı
  final String location; // Seçilen buluşma lokasyonu (API ile tutarlı olmalı)
  final DateTime meetingTime; // Buluşma tarihi ve saati
  final int user1Id; // Teklif sahibi
  final int user2Id; // Teklifi kabul eden
  final String?
  status; // Buluşma durumu (örn: 'planned', 'completed', 'cancelled')

  Meeting({
    required this.id,
    required this.offerId,
    required this.location,
    required this.meetingTime,
    required this.user1Id,
    required this.user2Id,
    this.status,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) => Meeting(
    id: json["id"] ?? 0,
    offerId: json["offer_id"] ?? 0,
    location: json["location"] ?? 'Bilinmeyen Lokasyon',
    meetingTime:
        DateTime.tryParse(json["meeting_time"] ?? '') ?? DateTime.now(),
    user1Id: json["user1_id"] ?? 0, // API'deki isimlerle eşleşmeli
    user2Id: json["user2_id"] ?? 0,
    status: json["status"],
  );

  // Yeni buluşma oluşturmak için API'ye gönderilecek JSON
  Map<String, dynamic> toJson() => {
    "offer_id": offerId,
    "location": location,
    "meeting_time": meetingTime.toIso8601String(), // ISO formatında gönder
    "user1_id": user1Id,
    "user2_id": user2Id,
    // status genellikle backend'de atanır veya güncellenir
  };
}
