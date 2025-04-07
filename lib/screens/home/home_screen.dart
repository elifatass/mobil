import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/book_model.dart';
import '../../widgets/book_card.dart';
import '../book/add_book_screen.dart';
import '../../providers/auth_provider.dart';
import '../offers/my_offers_screen.dart'; // Teklifler ekranı için import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Book>> _booksFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  void _loadBooks() {
    // Eğer widget ağaçtan kaldırıldıysa setState çağırma
    if (!mounted) return;
    setState(() {
      _booksFuture = _apiService.fetchBooks();
    });
  }

  // Çıkış yapma dialog ve işlemi
  Future<void> _showLogoutConfirmationDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await authProvider.logout();
      // AuthWrapper zaten state değişikliğini dinleyip LoginScreen'e yönlendirecek.
      // Bu yüzden burada ek bir Navigator işlemi GEREKMEZ.
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı sadece bir kez build içinde alalım
    // listen: true yaparsak kullanıcı bilgisi değişince (login/logout) arayüz güncellenir
    // Ama burada sadece başlangıçta isim almak ve logout için kullanıyoruz
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?.name ?? 'Kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: Text('Kitap Takas - Hoş Geldin $userName!'),
        actions: [
          // Tekliflerim Butonu
          IconButton(
            icon: const Icon(Icons.swap_horiz_sharp),
            onPressed: () {
              // MyOffersScreen'in const constructor'ı olmadığını varsayıyoruz
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MyOffersScreen(),
                ), // const kaldırıldı
              );
            },
            tooltip: 'Tekliflerim',
          ),
          // Yenile butonu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _loadBooks, // Metod referansı olarak kullanmak daha temiz
            tooltip: 'Yenile',
          ),
          // Çıkış Yap Butonu
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmationDialog, // Ayrı bir metoda taşıdık
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadBooks(),
        child: FutureBuilder<List<Book>>(
          future: _booksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    // Hata mesajı ve yenile butonu
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hata: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        onPressed: _loadBooks,
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final books = snapshot.data!;
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return BookCard(book: books[index]);
                },
              );
            } else {
              return Center(
                // Kitap yoksa gösterilecek mesaj ve yenile butonu
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Gösterilecek kitap bulunamadı.'),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yenile'),
                      onPressed: _loadBooks,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // AddBookScreen'e gitmeden önce mounted kontrolü gereksiz
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBookScreen(),
            ), // const eklendi
          );
          // Eğer kitap başarıyla eklendiyse listeyi yenile
          if (result == true && mounted) {
            // Geri dönüldüğünde mounted kontrolü
            _loadBooks();
          }
        },
        tooltip: 'Yeni Kitap Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }
}
