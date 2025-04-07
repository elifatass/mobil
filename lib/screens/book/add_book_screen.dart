import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FilteringTextInputFormatter için
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Yeni alanlar için controller'lar
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _publisherController = TextEditingController();
  final _descriptionController = TextEditingController(); // Açıklama da vardı
  // final _photoUrlController = TextEditingController(); // İsterseniz fotoğraf URL

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kullanıcı girişi gerekli.')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // Yıl değerini int'e çevir, boşsa null yap
      final int? year = int.tryParse(_yearController.text);

      final newBook = Book(
        // Modeldeki alanlara göre doldur
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        isbn:
            _isbnController.text.trim().isNotEmpty
                ? _isbnController.text.trim()
                : null,
        year: year,
        publisher:
            _publisherController.text.trim().isNotEmpty
                ? _publisherController.text.trim()
                : null,
        ownerId: userId, // Giriş yapmış kullanıcının ID'si
        // description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        // photoUrl: _photoUrlController.text.trim().isNotEmpty ? _photoUrlController.text.trim() : null,
      );

      try {
        bool success = await _apiService.addBook(newBook);
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitap başarıyla eklendi!')),
          );
          Navigator.pop(context, true); // Başarı durumunu geri gönder
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    // Tüm controller'ları dispose et
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _publisherController.dispose();
    _descriptionController.dispose();
    // _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kitap Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Kitap Adı *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      // trim() eklendi
                      return 'Lütfen kitap adını girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: 'Yazar Adı *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      // trim() eklendi
                      return 'Lütfen yazar adını girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // --- YENİ ALANLAR ---
                TextFormField(
                  controller: _isbnController,
                  decoration: const InputDecoration(labelText: 'ISBN'),
                  keyboardType:
                      TextInputType.text, // Veya number, ISBN formatına göre
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(labelText: 'Yayın Yılı'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ], // Sadece sayı girilsin
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final year = int.tryParse(value);
                      if (year == null) {
                        return 'Lütfen geçerli bir yıl girin.';
                      }
                      // İsteğe bağlı: Mantıklı bir yıl aralığı kontrolü
                      // if (year < 1000 || year > DateTime.now().year) {
                      //   return 'Geçerli bir yıl girin.';
                      // }
                    }
                    return null; // Yıl girmek zorunlu değilse
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _publisherController,
                  decoration: const InputDecoration(labelText: 'Yayınevi'),
                ),
                const SizedBox(height: 16), // Açıklama için boşluk

                TextFormField(
                  controller: _descriptionController, // Açıklama alanı
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 3,
                ),

                // --- YENİ ALANLAR BİTTİ ---
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
