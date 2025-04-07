import 'dart:convert'; // ***** EKLENDİ *****
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'dart:async'; // Timer için değil, sadece Future için gerekli (kaldırılabilir)

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  // Timer? _authTimer; // Kullanılmıyor, kaldırıldı
  // DateTime? _expiryDate; // Kullanılmıyor, kaldırıldı

  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Kullanıcı girişi
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // ApiService içinde 'login' metodu OLMALI!
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _token = response['token'];
        _user = User.fromJson(response['user'] as Map<String, dynamic>);

        // Token ve kullanıcı bilgilerini cihaz hafızasına kaydet
        final prefs = await SharedPreferences.getInstance();
        // jsonEncode burada kullanılacak (dart:convert import edildi)
        prefs.setString(
          'userData',
          jsonEncode({
            'token': _token,
            'userId': _user!.id,
            'email': _user!.email,
            'name': _user!.name,
          }),
        );

        _setLoading(false);
        notifyListeners();
        return true; // Başarılı
      } else {
        _errorMessage = response['message'];
        _setLoading(false);
        notifyListeners();
        return false; // Başarısız
      }
    } catch (error) {
      _errorMessage = "Giriş sırasında beklenmedik bir hata oluştu: $error";
      _setLoading(false);
      notifyListeners();
      return false; // Başarısız
    }
  }

  // Kullanıcı kaydı
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      // ApiService içinde 'register' metodu OLMALI!
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );
      _setLoading(false);
      if (response['success'] != true) {
        _errorMessage = response['message'];
      }
      notifyListeners();
      return response; // {success: true/false, message: '...'}
    } catch (error) {
      _errorMessage = "Kayıt sırasında beklenmedik bir hata oluştu: $error";
      _setLoading(false);
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  // Otomatik giriş denemesi (Uygulama açıldığında çağrılır)
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    try {
      // jsonDecode burada kullanılacak (dart:convert import edildi)
      final extractedUserData =
          jsonDecode(prefs.getString('userData')!) as Map<String, dynamic>;

      // Temel kontroller
      if (extractedUserData['token'] == null ||
          extractedUserData['userId'] == null) {
        await logout(); // Eksik veri varsa çıkış yap
        return false;
      }

      _token = extractedUserData['token'];
      _user = User(
        id: extractedUserData['userId'],
        name: extractedUserData['name'] ?? 'İsim Yok', // Null kontrolü
        email: extractedUserData['email'] ?? 'E-posta Yok', // Null kontrolü
      );
      notifyListeners();
      return true;
    } catch (e) {
      // JSON parse hatası veya başka bir sorun olursa
      await logout(); // Güvenlik için çıkış yap
      return false;
    }
  }

  // Çıkış yapma
  Future<void> logout() async {
    _token = null;
    _user = null;
    // Zamanlayıcı referansı kaldırıldı
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(
        'userData',
      ); // Sadece userData'yı silmek genellikle yeterli
      // await prefs.clear(); // Tüm SharedPreferences'ı silmek için
    } catch (e) {
      // print("SharedPreferences silinirken hata: $e"); // Hata loglama
    }
  }

  // Yükleme durumunu ayarlayan özel metod
  void _setLoading(bool value) {
    // isLoading zaten aynı değerdeyse gereksiz yere notify etme
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
