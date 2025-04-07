import 'package:flutter/material.dart';
import '../../models/offer_model.dart';
import '../../models/book_model.dart'; // Eklendi
import '../../services/api_service.dart';
import '../book/book_detail_screen.dart';
import '../meetings/meeting_plan_screen.dart'; // Doğru path kontrol edildi

class OfferDetailScreen extends StatefulWidget {
  final int offerId;
  final int currentUserId; // Teklifi kabul/red yetkisi için

  const OfferDetailScreen({
    super.key, // Linter uyarısı için düzeltildi
    required this.offerId,
    required this.currentUserId, // Gerçek kullanıcı ID'si alınmalı
  });

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState(); // Linter uyarısı için düzeltildi (State sınıfı private kalabilir)
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  late Future<Offer> _offerFuture;
  final ApiService _apiService = ApiService();
  bool _isProcessing = false; // Kabul/Red işlemi sırasında yükleme

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  void _loadOfferDetails() {
    setState(() {
      // fetchOfferById metodu artık ApiService içinde varsayılıyor
      _offerFuture = _apiService.fetchOfferById(widget.offerId);
    });
  }

  // Teklifi kabul etme işlemi
  Future<void> _acceptOffer(Offer offer) async {
    setState(() => _isProcessing = true);
    try {
      // updateOfferStatus metodu artık ApiService içinde varsayılıyor
      bool success = await _apiService.updateOfferStatus(
        widget.offerId,
        OfferStatus.accepted,
      );
      if (success) {
        // await sonrası context kullanmadan önce 'mounted' kontrolü
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teklif kabul edildi! Buluşma planlayın.'),
          ),
        );

        // Kabul edildikten sonra buluşma planlama ekranına git
        // pushReplacement bu ekranı kapatır ve yenisini açar
        // ignore: unused_local_variable // planResult kullanılmıyor, lint uyarısı için ignore eklendi
        final planResult = await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    MeetingPlanScreen(offer: offer), // Offer nesnesini gönder
          ),
        );
        // pushReplacement kullanıldığı için geri dönüldüğünde bu ekrana gelinmez,
        // bu yüzden aşağıdaki if bloğu genelde gereksiz olur.
        // if (planResult != true) {
        //   if (!mounted) return;
        //   Navigator.pop(context, true);
        // }
      }
    } catch (e) {
      if (!mounted)
        return; // await sonrası context kullanmadan önce 'mounted' kontrolü
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    } finally {
      // Widget hala ağaçta ise state'i güncelle
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Teklifi reddetme işlemi
  Future<void> _rejectOffer() async {
    setState(() => _isProcessing = true);
    try {
      bool success = await _apiService.updateOfferStatus(
        widget.offerId,
        OfferStatus.rejected,
      );
      if (success) {
        if (!mounted)
          return; // await sonrası context kullanmadan önce 'mounted' kontrolü
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Teklif reddedildi.')));
        // Önceki ekranı yenilemek için true döndürerek geri git
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted)
        return; // await sonrası context kullanmadan önce 'mounted' kontrolü
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teklif Detayı')),
      body: FutureBuilder<Offer>(
        future: _offerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Hata: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final offer = snapshot.data!;
            // Teklifi sadece istenen kitabın sahibi kabul/red edebilir
            final bool canAcceptOrReject =
                offer.requestedBookOwnerId == widget.currentUserId &&
                offer.status == OfferStatus.pending;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                // İçerik uzun olabilir
                children: [
                  _buildOfferSection(
                    title:
                        'Teklif Eden Kullanıcı (${offer.offeringUser?.name ?? 'ID: ${offer.offeringUserId}'})',
                    book: offer.offeredBook,
                    bookId: offer.offeredBookId,
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Icon(Icons.swap_horiz, size: 40, color: Colors.teal),
                  ),
                  const SizedBox(height: 20),
                  _buildOfferSection(
                    title:
                        'İstenen Kitap (Sahibi: Siz)', // Veya offer.requestedBookOwner?.username
                    book: offer.requestedBook,
                    bookId: offer.requestedBookId,
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  if (offer.message != null && offer.message!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Teklif Mesajı:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(offer.message!),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                  ],
                  const SizedBox(height: 10),
                  Center(
                    child: _buildStatusChip(offer.status),
                  ), // Durum etiketi
                  const SizedBox(height: 30),

                  // Kabul/Red Butonları (Sadece yetkili kullanıcı ve beklemedeyse göster)
                  if (canAcceptOrReject)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _rejectOffer,
                          icon: const Icon(Icons.close),
                          label: const Text('Reddet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _isProcessing ? null : () => _acceptOffer(offer),
                          icon: const Icon(Icons.check),
                          label: const Text('Kabul Et'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  // İşlem sırasında yükleme göstergesi
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  // Teklif kabul edildiyse buluşma planlama butonu gösterilebilir
                  if (offer.status == OfferStatus.accepted)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Buluşma Planla/Görüntüle'),
                          onPressed: () {
                            // Buluşma planlama ekranına gitmeden önce mounted kontrolü gereksiz
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        MeetingPlanScreen(offer: offer),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Teklif bulunamadı.'));
          }
        },
      ),
    );
  }

  // Teklifin bir tarafını (teklif eden/istenen) gösteren widget
  Widget _buildOfferSection({
    required String title,
    Book? book,
    required int bookId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        book != null
            ? Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal[50],
                  // Linter uyarısı için child sona alındı
                  child: const Icon(Icons.book_outlined),
                ),
                title: Text(book.title),
                subtitle: Text(book.author),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  // Kitap detayına git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(bookId: bookId),
                    ),
                  );
                },
              ),
            )
            : Text(
              'Kitap bilgisi yüklenemedi (ID: $bookId)',
            ), // Kitap detayı yoksa
      ],
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
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}
