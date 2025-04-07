// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Eklendi
import 'constants/app_constants.dart';
import 'providers/auth_provider.dart'; // Eklendi
import 'screens/auth/auth_wrapper.dart'; // Eklendi

void main() {
  runApp(const MyApp()); // const eklendi
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // const eklendi ve super.key eklendi

  @override
  Widget build(BuildContext context) {
    // AuthProvider'ı tüm uygulamanın erişimine sun
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Input border'ları için genel stil (opsiyonel)
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        // Başlangıç ekranını AuthWrapper olarak ayarla
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
