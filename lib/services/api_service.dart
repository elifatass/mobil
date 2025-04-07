import 'dart:convert';
import 'dart:io'; // HttpException ve SocketException için
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/book_model.dart';
import '../models/offer_model.dart'; // Eklendi
import '../models/meeting_model.dart'; // Eklendi
import '../models/user_model.dart'; // Eklendi (Offer içinde kullanılıyor)

class ApiService {
  final String _baseUrl = AppConstants.apiBaseUrl;

  // --- Kitap Metodları ---

  Future<List<Book>> fetchBooks() async {
    final String url = '$_baseUrl/books/';
    // print('API İsteği: GET $url'); // Geliştirme sırasında print yerine logger kullanın

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // print('API Yanıtı (Başarılı): ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}...');
        String responseBody = utf8.decode(response.bodyBytes);
        return bookListFromJson(responseBody);
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'Kitaplar yüklenemedi. Hata kodu: ${response.statusCode}',
        );
      }
    } on SocketException {
      // print('API Hatası: Bağlantı hatası (Sunucu kapalı veya URL yanlış)');
      throw Exception(
        'Sunucuya bağlanılamıyor. İnternet bağlantınızı veya API adresini kontrol edin.',
      );
    } on HttpException {
      // print('API Hatası: HTTP Hatası (Geçersiz yanıt)');
      throw Exception('Geçersiz bir sunucu yanıtı alındı.');
    } on FormatException {
      // print('API Hatası: Format Hatası (JSON parse edilemedi)');
      throw Exception('Sunucudan gelen veri formatı hatalı.');
    } catch (e) {
      // print('API Hatası: Bilinmeyen hata - $e');
      throw Exception('Bilinmeyen bir hata oluştu: $e');
    }
  }

  Future<Book> fetchBookById(int id) async {
    final String url = '$_baseUrl/books/$id';
    // print('API İsteği: GET $url');

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // print('API Yanıtı (Başarılı): ${response.body}');
        String responseBody = utf8.decode(response.bodyBytes);
        return Book.fromJson(json.decode(responseBody));
      } else if (response.statusCode == 404) {
        // print('API Hatası: Kitap bulunamadı (404)');
        throw Exception('$id ID\'li kitap bulunamadı.');
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Kitap yüklenemedi. Hata kodu: ${response.statusCode}');
      }
    } on SocketException {
      // print('API Hatası: Bağlantı hatası');
      throw Exception('Sunucuya bağlanılamıyor.');
    } catch (e) {
      // print('API Hatası: Bilinmeyen hata - $e');
      throw Exception('Kitap getirilirken hata: $e');
    }
  }

  Future<bool> addBook(Book book) async {
    final String url = '$_baseUrl/books/';
    // print('API İsteği: POST $url, Data: ${book.toJson()}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(book.toJson()),
      );

      if (response.statusCode == 201) {
        // print('API Yanıtı (Başarılı - Kitap Eklendi): ${response.body}');
        return true;
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        String errorMessage =
            'Kitap eklenemedi. Hata kodu: ${response.statusCode}';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['hata'] != null) {
            errorMessage = errorData['hata'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on SocketException {
      // print('API Hatası: Bağlantı hatası');
      throw Exception('Sunucuya bağlanılamıyor.');
    } catch (e) {
      // print('API Hatası: Bilinmeyen hata - $e');
      throw Exception('Kitap eklenirken hata: $e');
    }
  }

  Future<bool> deleteBook(int id) async {
    final String url = '$_baseUrl/books/$id';
    // print('API İsteği: DELETE $url');

    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200 || response.statusCode == 204) {
        // print('API Yanıtı (Başarılı - Kitap Silindi)');
        return true;
      } else if (response.statusCode == 404) {
        // print('API Hatası: Silinecek kitap bulunamadı (404)');
        throw Exception('$id ID\'li kitap bulunamadı.');
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        String errorMessage =
            'Kitap silinemedi. Hata kodu: ${response.statusCode}';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['hata'] != null) {
            errorMessage = errorData['hata'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on SocketException {
      // print('API Hatası: Bağlantı hatası');
      throw Exception('Sunucuya bağlanılamıyor.');
    } catch (e) {
      // print('API Hatası: Bilinmeyen hata - $e');
      throw Exception('Kitap silinirken hata: $e');
    }
  }

  Future<bool> updateBook(int id, Book book) async {
    final String url = '$_baseUrl/books/$id';
    // print('API İsteği: PUT $url, Data: ${book.toJson()}');

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(book.toJson()),
      );

      if (response.statusCode == 200) {
        // print('API Yanıtı (Başarılı - Kitap Güncellendi): ${response.body}');
        return true;
      } else if (response.statusCode == 404) {
        // print('API Hatası: Güncellenecek kitap bulunamadı (404)');
        throw Exception('$id ID\'li kitap bulunamadı.');
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        String errorMessage =
            'Kitap güncellenemedi. Hata kodu: ${response.statusCode}';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['hata'] != null) {
            errorMessage = errorData['hata'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on SocketException {
      // print('API Hatası: Bağlantı hatası');
      throw Exception('Sunucuya bağlanılamıyor.');
    } catch (e) {
      // print('API Hatası: Bilinmeyen hata - $e');
      throw Exception('Kitap güncellenirken hata: $e');
    }
  }

  // --- Teklif Metodları (Extension'lardan Taşındı) ---

  Future<List<Offer>> fetchSentOffers(int userId) async {
    // GET /api/offers?offering_user_id={userId} endpoint'ine istek at
    final String url = '$_baseUrl/offers?offering_user_id=$userId'; // Örnek URL
    // print('API İsteği: GET $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        return offerListFromJson(responseBody);
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Gönderilen teklifler yüklenemedi.');
      }
    } catch (e) {
      // print('API Hatası: $e');
      throw Exception('Teklifler yüklenirken hata: $e');
    }
  }

  Future<List<Offer>> fetchReceivedOffers(int userId) async {
    // GET /api/offers?requested_book_owner_id={userId} endpoint'ine istek at
    final String url =
        '$_baseUrl/offers?requested_book_owner_id=$userId'; // Örnek URL
    // print('API İsteği: GET $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        return offerListFromJson(responseBody);
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Alınan teklifler yüklenemedi.');
      }
    } catch (e) {
      // print('API Hatası: $e');
      throw Exception('Teklifler yüklenirken hata: $e');
    }
  }

  Future<Offer> fetchOfferById(int offerId) async {
    // GET /api/offers/{offerId} endpoint'ine istek at
    // Mümkünse ilişkili kitap ve kullanıcı bilgilerini de (join ile) getirmeli
    // Backend'inizin ?_expand=... veya benzeri bir parametreyi desteklediğini varsayıyoruz
    final String url =
        '$_baseUrl/offers/$offerId?_expand=offered_book&_expand=requested_book&_expand=offering_user';
    // print('API İsteği: GET $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        return Offer.fromJson(json.decode(responseBody));
      } else if (response.statusCode == 404) {
        // print('API Hatası: Teklif bulunamadı (404)');
        throw Exception('$offerId ID\'li teklif bulunamadı.');
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        throw Exception('Teklif detayları yüklenemedi.');
      }
    } catch (e) {
      // print('API Hatası: $e');
      throw Exception('Teklif detayları yüklenirken hata: $e');
    }
  }

  Future<bool> updateOfferStatus(int offerId, OfferStatus newStatus) async {
    // PUT veya PATCH /api/offers/{offerId} endpoint'ine istek at
    final String url = '$_baseUrl/offers/$offerId';
    final String statusString = newStatus.toString().split('.').last;
    // print('API İsteği: PATCH $url, Data: {"status": "$statusString"}');

    try {
      final response = await http.patch(
        // Genellikle PATCH kullanılır
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'status': statusString}),
      );
      if (response.statusCode == 200) {
        // print('API Yanıtı (Başarılı - Teklif Durumu Güncellendi)');
        return true;
      } else {
        // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
        String errorMessage = 'Teklif durumu güncellenemedi.';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['hata'] != null) errorMessage = errorData['hata'];
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      // print('API Hatası: $e');
      throw Exception('Teklif durumu güncellenirken hata: $e');
    }
  }
  // lib/services/api_service.dart
  // ... (önceki importlar ve kodlar) ...

  // ... (önceki _baseUrl ve diğer metodlar) ...

  // --- Authentication Metodları ---

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final String url =
        '$_baseUrl/auth/register'; // Backend endpoint'inizle eşleştirin
    // print('API İsteği: POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': name,
          'email': email,
          'password': password, // Şifre backend'e gönderiliyor
        }),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      // print('API Yanıtı (Register): ${response.statusCode} - $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Başarılı kayıt
        // Backend sadece mesaj mı döndürüyor, yoksa token/user mı?
        // Şimdilik sadece mesaj döndürdüğünü varsayalım.
        return {
          'success': true,
          'message': responseData['message'] ?? 'Kayıt başarılı!',
        };
      } else {
        // Hata durumu
        return {
          'success': false,
          'message':
              responseData['hata'] ??
              responseData['error'] ??
              'Kayıt sırasında bir hata oluştu.',
        };
      }
    } catch (e) {
      // print('API Hatası (Register): $e');
      return {
        'success': false,
        'message': 'Sunucuya bağlanırken bir hata oluştu: $e',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final String url =
        '$_baseUrl/auth/login'; // Backend endpoint'inizle eşleştirin
    // print('API İsteği: POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      // print('API Yanıtı (Login): ${response.statusCode} - $responseData');

      if (response.statusCode == 200) {
        // Başarılı giriş
        // Backend'in token ve kullanıcı bilgisini döndürdüğünü varsayalım
        if (responseData['token'] != null && responseData['user'] != null) {
          return {
            'success': true,
            'token': responseData['token'],
            'user': responseData['user'], // Bu bir Map<String, dynamic> olmalı
          };
        } else {
          return {'success': false, 'message': 'Sunucudan eksik bilgi döndü.'};
        }
      } else {
        // Hata durumu
        return {
          'success': false,
          'message':
              responseData['hata'] ??
              responseData['error'] ??
              'Giriş sırasında bir hata oluştu.',
        };
      }
    } catch (e) {
      // print('API Hatası (Login): $e');
      return {
        'success': false,
        'message': 'Sunucuya bağlanırken bir hata oluştu: $e',
      };
    }
  }

  // --- Diğer Metodlar (fetchBooks, addBook, fetchOffers, createMeeting vb.) ---
  // ... (önceki metodlar burada kalacak) ...
}
// --- Buluşma Metodları (Extension'dan Taşındı) ---

Future<bool> createMeeting(Meeting meetingData) async {
  // POST /api/meetings endpoint'ine istek at
  var _baseUrl;
  final String url = '$_baseUrl/meetings/';
  // print('API İsteği: POST $url, Data: ${meetingData.toJson()}');

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(meetingData.toJson()),
    );

    if (response.statusCode == 201) {
      // Created
      // print('API Yanıtı (Başarılı - Buluşma Oluşturuldu): ${response.body}');
      return true;
    } else {
      // print('API Hatası: Status Code ${response.statusCode}, Body: ${response.body}');
      String errorMessage = 'Buluşma planlanamadı.';
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        if (errorData['hata'] != null) errorMessage = errorData['hata'];
      } catch (_) {}
      throw Exception(errorMessage);
    }
  } catch (e) {
    // print('API Hatası: $e');
    throw Exception('Buluşma planlanırken hata: $e');
  }
}

login({required String email, required String password}) {}

register({
  required String name,
  required String email,
  required String password,
}) {}
