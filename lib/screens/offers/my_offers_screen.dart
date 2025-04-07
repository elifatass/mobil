import 'dart:convert';

import 'package:flutter/material.dart';
import '../../models/offer_model.dart';
import '../../services/api_service.dart'; // ApiService'e yeni metodlar eklenmeli
import 'offer_detail_screen.dart';
import 'package:http/http.dart' as http;

class MyOffersScreen extends StatefulWidget {
  @override
  _MyOffersScreenState createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen>
    with SingleTickerProviderStateMixin {
  // TabController için gerekli
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // !!! ÖNEMLİ: Gerçek giriş yapmış kullanıcı ID'sini almalısınız !!!
  final int currentUserId =
      1; // Bu değeri gerçek kullanıcı ID'si ile değiştirin!

  late Future<List<Offer>> _sentOffersFuture;
  late Future<List<Offer>> _receivedOffersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // 2 sekme: Gönderilen, Alınan
    _loadOffers();
  }

  void _loadOffers() {
    setState(() {
      // ApiService'de bu metodların tanımlanması gerekir:
      // fetchSentOffers(userId): Belirli kullanıcının gönderdiği teklifleri getirir
      // fetchReceivedOffers(userId): Belirli kullanıcının kitaplarına gelen teklifleri getirir
      _sentOffersFuture = _apiService.fetchSentOffers(currentUserId);
      _receivedOffersFuture = _apiService.fetchReceivedOffers(currentUserId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tekliflerim'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Gönderdiğim Teklifler'),
            Tab(text: 'Aldığım Teklifler'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadOffers,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Gönderilen Teklifler Sekmesi
          _buildOfferList(_sentOffersFuture, isSentOffer: true),
          // Alınan Teklifler Sekmesi
          _buildOfferList(_receivedOffersFuture, isSentOffer: false),
        ],
      ),
    );
  }

  // Teklif listesini oluşturan yardımcı widget
  Widget _buildOfferList(
    Future<List<Offer>> future, {
    required bool isSentOffer,
  }) {
    return FutureBuilder<List<Offer>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Hata: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final offers = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _loadOffers(),
            child: ListView.builder(
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                // Teklif kartını oluştur (daha detaylı bir widget yapılabilir)
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    // Gönderilen teklifte: İstenen kitap başlığı
                    // Alınan teklifte: Teklif edilen kitap başlığı
                    title: Text(
                      isSentOffer
                          ? 'İstek: ${offer.requestedBook?.title ?? 'Kitap ID: ${offer.requestedBookId}'}'
                          : 'Teklif: ${offer.offeredBook?.title ?? 'Kitap ID: ${offer.offeredBookId}'}',
                    ),
                    // Gönderilen teklifte: Teklif edilen KİTABINIZ
                    // Alınan teklifte: İstediği KİTABINIZ
                    subtitle: Text(
                      isSentOffer
                          ? 'Karşılığında: ${offer.offeredBook?.title ?? 'Kitap ID: ${offer.offeredBookId}'}'
                          : 'İstenen: ${offer.requestedBook?.title ?? 'Kitap ID: ${offer.requestedBookId}'}',
                    ),
                    trailing: _buildStatusChip(offer.status), // Durum etiketi
                    onTap: () async {
                      // Detay sayfasına git ve geri dönüldüğünde listeyi yenile
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => OfferDetailScreen(
                                offerId: offer.id,
                                currentUserId: currentUserId,
                              ),
                        ),
                      );
                      // Eğer detaydan true döndüyse (örn: kabul/red edildi)
                      if (result == true) {
                        _loadOffers();
                      }
                    },
                  ),
                );
              },
            ),
          );
        } else {
          return Center(child: Text('Henüz teklif yok.'));
        }
      },
    );
  }

  // Duruma göre renkli etiket (chip) oluşturan widget
  Widget _buildStatusChip(OfferStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case OfferStatus.pending:
        color = Colors.orange;
        text = 'Bekliyor';
        icon = Icons.hourglass_empty;
        break;
      case OfferStatus.accepted:
        color = Colors.green;
        text = 'Kabul Edildi';
        icon = Icons.check_circle_outline;
        break;
      case OfferStatus.rejected:
        color = Colors.red;
        text = 'Reddedildi';
        icon = Icons.cancel_outlined;
        break;
      case OfferStatus.cancelled:
        color = Colors.grey;
        text = 'İptal Edildi';
        icon = Icons.remove_circle_outline;
        break;
    }
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}

// ApiService için eklenmesi gereken metod imzaları (içerikleri doldurulmalı):
extension OfferApiService on ApiService {
  Future<List<Offer>> fetchSentOffers(int userId) async {
    // GET /api/offers?offering_user_id={userId} endpoint'ine istek at
    // Gelen JSON listesini OfferListFromJson ile parse et
    var _baseUrl;
    final String url = '$_baseUrl/offers?offering_user_id=$userId'; // Örnek URL
    print('API İsteği: GET $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        return offerListFromJson(responseBody);
      } else {
        print(
          'API Hatası: Status Code ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Gönderilen teklifler yüklenemedi.');
      }
    } catch (e) {
      print('API Hatası: $e');
      throw Exception('Teklifler yüklenirken hata: $e');
    }
    // return Future.value([]); // Geçici
  }

  Future<List<Offer>> fetchReceivedOffers(int userId) async {
    // GET /api/offers?requested_book_owner_id={userId} endpoint'ine istek at
    var _baseUrl;
    final String url =
        '$_baseUrl/offers?requested_book_owner_id=$userId'; // Örnek URL
    print('API İsteği: GET $url');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        return offerListFromJson(responseBody);
      } else {
        print(
          'API Hatası: Status Code ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('Alınan teklifler yüklenemedi.');
      }
    } catch (e) {
      print('API Hatası: $e');
      throw Exception('Teklifler yüklenirken hata: $e');
    }
    // return Future.value([]); // Geçici
  }
}
