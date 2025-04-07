import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için (pubspec'a ekleyin: intl: ^0.18.0 veya üstü)
import '../../models/offer_model.dart';
import '../../models/meeting_model.dart';
import '../../services/api_service.dart'; // ApiService'e yeni metodlar eklenmeli
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class MeetingPlanScreen extends StatefulWidget {
  final Offer offer; // Kabul edilmiş teklif bilgisi

  const MeetingPlanScreen({Key? key, required this.offer}) : super(key: key);

  @override
  _MeetingPlanScreenState createState() => _MeetingPlanScreenState();
}

class _MeetingPlanScreenState extends State<MeetingPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Elazığ için önceden tanımlanmış lokasyonlar (API'den de çekilebilir)
  final List<String> _locations = [
    'Fırat Üniversitesi Kütüphanesi Önü',
    'Park 23 AVM Starbucks',
    'Öğretmenevi Lobisi',
    'Ahmet Tevfik Ozan Fuar ve Kongre Merkezi',
    'Elazığ Belediyesi Önü',
    // ... Diğer popüler ve güvenli yerler
  ];
  String? _selectedLocation; // Seçilen lokasyon
  DateTime? _selectedDate; // Seçilen tarih
  TimeOfDay? _selectedTime; // Seçilen saat

  bool _isLoading = false; // Kaydetme işlemi sırasında

  // Tarih seçiciyi gösteren fonksiyon
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // Geçmiş tarih seçilemesin
      lastDate: DateTime.now().add(
        Duration(days: 30),
      ), // En fazla 30 gün sonrası
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Saat seçiciyi gösteren fonksiyon
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Buluşmayı kaydetme işlemi
  Future<void> _submitMeeting() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lütfen buluşma tarihi ve saati seçin.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      // Seçilen tarih ve saati birleştir
      final meetingDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Yeni Meeting nesnesi oluştur
      final newMeeting = Meeting(
        // ID backend tarafından atanacak, burada 0 veya null geçilebilir
        id: 0,
        offerId: widget.offer.id,
        location: _selectedLocation!,
        meetingTime: meetingDateTime,
        user1Id: widget.offer.offeringUserId, // Teklifi yapan
        user2Id: widget.offer.requestedBookOwnerId, // Teklifi kabul eden
        // status backend'de 'planned' olarak atanabilir
      );

      try {
        // ApiService'de bu metodun tanımlanması gerekir: createMeeting(meetingData)
        bool success = await _apiService.createMeeting(newMeeting);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Buluşma başarıyla planlandı!')),
          );
          // Planlama başarılıysa bir önceki ekrana dön (veya ana ekrana)
          // Önceki ekranın yenilenmesi için pop(true) kullanılabilir
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Seçilen tarih ve saati formatla
    final dateFormat = DateFormat(
      'dd MMMM yyyy, EEEE',
      'tr_TR',
    ); // intl paketi gerekli
    final timeFormat = MaterialLocalizations.of(
      context,
    ); // Lokal saat formatı için

    return Scaffold(
      appBar: AppBar(title: Text('Buluşma Planla')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // İçerik dikeyde sığmayabilir
            children: [
              Text(
                'Teklif ID: ${widget.offer.id}',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                'Aşağıdaki bilgileri doldurarak kitap takası için buluşma ayarlayabilirsiniz.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24),

              // Lokasyon Seçimi
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                hint: Text('Buluşma Lokasyonu Seçin *'),
                isExpanded: true,
                items:
                    _locations.map((String location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Lütfen bir lokasyon seçin' : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 15,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Tarih Seçimi
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text(
                  _selectedDate == null
                      ? 'Buluşma Tarihi Seçin *'
                      : 'Tarih: ${dateFormat.format(_selectedDate!)}',
                ),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 20),

              // Saat Seçimi
              ListTile(
                leading: Icon(Icons.access_time),
                title: Text(
                  _selectedTime == null
                      ? 'Buluşma Saati Seçin *'
                      : 'Saat: ${timeFormat.formatTimeOfDay(_selectedTime!)}',
                ), // Lokal format
                trailing: Icon(Icons.arrow_drop_down),
                onTap: () => _selectTime(context),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 40),

              // Kaydet Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _submitMeeting,
                child:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text('Buluşmayı Planla'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ApiService için eklenmesi gereken metod imzası:
extension MeetingApiService on ApiService {
  Future<bool> createMeeting(Meeting meetingData) async {
    // POST /api/meetings endpoint'ine istek at
    // Body içinde meetingData.toJson() ile JSON gönder
    var _baseUrl;
    final String url = '$_baseUrl/meetings/';
    print('API İsteği: POST $url, Data: ${meetingData.toJson()}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(meetingData.toJson()),
      );

      if (response.statusCode == 201) {
        // Created
        print('API Yanıtı (Başarılı - Buluşma Oluşturuldu): ${response.body}');
        return true;
      } else {
        print(
          'API Hatası: Status Code ${response.statusCode}, Body: ${response.body}',
        );
        String errorMessage = 'Buluşma planlanamadı.';
        try {
          final errorData = jsonDecode(utf8.decode(response.bodyBytes));
          if (errorData['hata'] != null) errorMessage = errorData['hata'];
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('API Hatası: $e');
      throw Exception('Buluşma planlanırken hata: $e');
    }
    // return Future.value(true); // Geçici
  }

  // İleride buluşmaları listelemek/detay görmek için metodlar eklenebilir
  // Future<List<Meeting>> fetchMyMeetings(int userId) async { ... }
  // Future<Meeting> fetchMeetingById(int meetingId) async { ... }
}
