import 'dart:io' show Platform;

class AppConstants {
  // !!! BURAYI KENDİ BİLGİSAYARININ IP ADRESİYLE DEĞİŞTİR !!!
  // Terminalde 'ipconfig' (Windows) veya 'ifconfig' (Mac/Linux) ile öğren.
  static const String _localIpAddress =
      "YOUR_COMPUTER_IP_ADDRESS"; // Örn: "192.168.1.105"

  // API sunucusunun çalıştığı port (Flask için varsayılan 5000)
  static const String _apiPort = "5000";

  // Platforma göre doğru API adresini döndürür
  static String get apiBaseUrl {
    if (Platform.isAndroid) {
      // Android emülatör host makineye 10.0.2.2 üzerinden erişir
      return 'http://10.0.2.2:$_apiPort/api';
    } else {
      // iOS simülatörü veya aynı ağdaki fiziksel cihazlar için
      // Bilgisayarının yerel ağdaki IP adresini kullan
      return 'http://$_localIpAddress:$_apiPort/api';
      // Alternatif: return 'http://localhost:$_apiPort/api'; // iOS simülatörü için bazen çalışır
    }
  }

  // Örnek olarak başka sabitler de eklenebilir
  static const String appName = "Kitap Takas Uygulaması";
}
