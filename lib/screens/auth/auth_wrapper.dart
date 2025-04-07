// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart'; // Ana ekran
import 'login_screen.dart'; // Giriş ekranı

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Oturum durumuna göre ekran seçimi
    if (authProvider.isAuthenticated) {
      return HomeScreen(); // Kullanıcı giriş yapmışsa ana ekranı göster
    } else {
      // Otomatik giriş denemesi yapılıyor mu diye kontrol et (opsiyonel splash screen)
      // Bu FutureBuilder yapısı, uygulama açılırken kısa bir yükleme ekranı gösterir
      return FutureBuilder(
        future: authProvider.tryAutoLogin(), // Oturum açmayı dene
        builder:
            (ctx, authResultSnapshot) =>
                authResultSnapshot.connectionState == ConnectionState.waiting
                    ? const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    ) // Yükleniyor...
                    : const LoginScreen(), // Otomatik giriş başarısızsa veya denenmediyse giriş ekranı
      );
    }
  }
}
