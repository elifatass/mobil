import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../screens/book/book_detail_screen.dart'; // Detay ekranını import et

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        // Kitap fotoğrafı varsa gösterilebilir (şimdilik ikon)
        leading: CircleAvatar(
          // backgroundImage: book.photoUrl != null ? NetworkImage(book.photoUrl!) : null,
          child: book.photoUrl == null ? Icon(Icons.book) : null,
          backgroundColor: Colors.teal[100],
        ),
        title: Text(book.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(book.author),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Kart'a tıklandığında kitap detay ekranına git
          if (book.id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(bookId: book.id!),
              ),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Kitap ID\'si bulunamadı.')));
          }
        },
      ),
    );
  }
}
