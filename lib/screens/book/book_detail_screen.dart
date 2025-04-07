import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart'; // AuthProvider için eklendi
import '../../providers/auth_provider.dart'; // Eklendi
// import '../book/edit_book_screen.dart'; // Düzenleme ekranı için (opsiyonel)

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<Book> _bookFuture;
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
  }

  void _loadBookDetails() {
    setState(() {
      _bookFuture = _apiService.fetchBookById(widget.bookId);
    });
  }

  Future<void> _deleteBook(int currentUserId, int ownerId) async {
    // Sadece kitabın sahibi silebilsin
    if (currentUserId != ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kitabı silme yetkiniz yok.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kitabı Sil'),
          content: const Text(
            'Bu kitabı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      try {
        bool success = await _apiService.deleteBook(widget.bookId);
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitap başarıyla silindi!')),
          );
          // Başarıyla silindiyse bir önceki ekrana dön (listeyi yenilemek için true dönebilir)
          Navigator.pop(
            context,
            true,
          ); // true değeri HomeScreen'de yakalanabilir
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  // Opsiyonel: Kitap Düzenleme Ekranına Git
  void _goToEditScreen(Book book) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => EditBookScreen(book: book), // EditBookScreen oluşturulmalı
    //   ),
    // ).then((updated) {
    //    // Düzenleme ekranından true değeriyle dönülürse detayları yenile
    //    if (updated == true) {
    //      _loadBookDetails();
    //    }
    // });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Düzenleme özelliği henüz eklenmedi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Giriş yapmış kullanıcı ID'sini alalım (silme/düzenleme yetkisi için)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Detayı'),
        actions: [
          // Yetki kontrolü ile Silme ve Düzenleme Butonları
          FutureBuilder<Book>(
            future: _bookFuture, // Mevcut future'ı kullan
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  currentUserId != null &&
                  snapshot.data!.ownerId == currentUserId) {
                // Kitabın sahibi ise butonları göster
                return Row(
                  children: [
                    // Opsiyonel: Düzenle Butonu
                    // IconButton(
                    //   icon: const Icon(Icons.edit_outlined),
                    //   onPressed: () => _goToEditScreen(snapshot.data!),
                    //   tooltip: 'Kitabı Düzenle',
                    // ),
                    _isDeleting
                        ? const Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                        : IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed:
                              () => _deleteBook(
                                currentUserId,
                                snapshot.data!.ownerId,
                              ),
                          tooltip: 'Kitabı Sil',
                        ),
                  ],
                );
              }
              // Sahibi değilse veya yükleniyorsa/hata varsa boş widget döndür
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Book>(
        future: _bookFuture,
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
            final book = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: RefreshIndicator(
                // Sayfayı yenileme özelliği
                onRefresh: () async => _loadBookDetails(),
                child: ListView(
                  children: [
                    if (book.photoUrl != null &&
                        Uri.tryParse(book.photoUrl!)?.isAbsolute == true)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Image.network(
                            book.photoUrl!,
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yazar: ${book.author}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // --- YENİ ALANLARI GÖSTER ---
                    if (book.isbn != null && book.isbn!.isNotEmpty) ...[
                      _buildDetailRow(Icons.qr_code, 'ISBN', book.isbn!),
                    ],
                    if (book.year != null) ...[
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        'Yayın Yılı',
                        book.year.toString(),
                      ),
                    ],
                    if (book.publisher != null &&
                        book.publisher!.isNotEmpty) ...[
                      _buildDetailRow(
                        Icons.business_outlined,
                        'Yayınevi',
                        book.publisher!,
                      ),
                    ],

                    // --- YENİ ALANLAR BİTTİ ---
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Açıklama',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title ?? 'Açıklama bulunmuyor.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Ekleyen Kullanıcı ID: ${book.ownerId}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('Kitap bilgisi bulunamadı.'));
          }
        },
      ),
    );
  }

  // Detay satırını oluşturan yardımcı widget
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)), // Değer uzunsa alt satıra geçsin
        ],
      ),
    );
  }
}
