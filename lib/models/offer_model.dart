import 'dart:convert';
import 'book_model.dart'; // Kitap modelini kullanabiliriz
import 'user_model.dart'; // Kullanıcı modelini kullanabiliriz (veya sadece ID'leri)

// JSON'dan Offer listesi parse etmek için yardımcı fonksiyon
List<Offer> offerListFromJson(String str) =>
    List<Offer>.from(json.decode(str).map((x) => Offer.fromJson(x)));

String offerToJson(Offer data) => json.encode(data.toJson());

// Teklif durumlarını temsil eden enum (API ile tutarlı olmalı)
enum OfferStatus { pending, accepted, rejected, cancelled }

class Offer {
  final int id;
  final int offeringUserId; // Teklifi yapan kullanıcının ID'si
  final int
  offeredBookId; // Teklif edilen kitabın ID'si (teklifi yapanın kitabı)
  final int requestedBookId; // İstenen kitabın ID'si (teklifin yapıldığı kitap)
  final int requestedBookOwnerId; // İstenen kitabın sahibinin ID'si
  final OfferStatus status; // Teklifin durumu (pending, accepted, rejected)
  final DateTime createdAt; // Teklifin oluşturulma tarihi
  final String? message; // Teklifle birlikte gönderilen mesaj (opsiyonel)

  // Detay sayfasında göstermek için ilişkili nesneler (API'den join ile alınabilir)
  final Book? offeredBook; // Teklif edilen kitap detayları (opsiyonel)
  final Book? requestedBook; // İstenen kitap detayları (opsiyonel)
  final User? offeringUser; // Teklifi yapan kullanıcı detayları (opsiyonel)

  Offer({
    required this.id,
    required this.offeringUserId,
    required this.offeredBookId,
    required this.requestedBookId,
    required this.requestedBookOwnerId,
    required this.status,
    required this.createdAt,
    this.message,
    this.offeredBook,
    this.requestedBook,
    this.offeringUser,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    // Status string'ini OfferStatus enum'ına çevir
    OfferStatus currentStatus = OfferStatus.pending; // Varsayılan
    String statusString = json["status"]?.toLowerCase() ?? 'pending';
    if (statusString == 'accepted') {
      currentStatus = OfferStatus.accepted;
    } else if (statusString == 'rejected') {
      currentStatus = OfferStatus.rejected;
    } else if (statusString == 'cancelled') {
      currentStatus = OfferStatus.cancelled;
    }

    return Offer(
      id: json["id"] ?? 0,
      offeringUserId: json["offering_user_id"] ?? 0,
      offeredBookId: json["offered_book_id"] ?? 0,
      requestedBookId: json["requested_book_id"] ?? 0,
      requestedBookOwnerId: json["requested_book_owner_id"] ?? 0,
      status: currentStatus,
      // Tarih string'ini DateTime'a çevir
      createdAt: DateTime.tryParse(json["created_at"] ?? '') ?? DateTime.now(),
      message: json["message"],
      // İlişkili nesneler varsa onları da parse et
      offeredBook:
          json["offered_book"] != null
              ? Book.fromJson(json["offered_book"])
              : null,
      requestedBook:
          json["requested_book"] != null
              ? Book.fromJson(json["requested_book"])
              : null,
      offeringUser:
          json["offering_user"] != null
              ? User.fromJson(json["offering_user"])
              : null,
    );
  }

  // API'ye yeni teklif göndermek için JSON Map'ine dönüştürür
  Map<String, dynamic> toJson() => {
    // id, status, createdAt genellikle client'tan gönderilmez
    "offering_user_id": offeringUserId,
    "offered_book_id": offeredBookId,
    "requested_book_id": requestedBookId,
    "requested_book_owner_id": requestedBookOwnerId,
    "message": message,
  };
}
