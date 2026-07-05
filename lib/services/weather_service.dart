import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherModel {
  final String cityName;
  final double temperature;
  final int weatherCode;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.weatherCode,
  });

  /// Terjemahan kode cuaca Open-Meteo (WMO code) ke deskripsi singkat berbahasa Indonesia
  String get description {
    if (weatherCode == 0) return 'Cerah';
    if (weatherCode <= 2) return 'Cerah Berawan';
    if (weatherCode == 3) return 'Mendung';
    if (weatherCode <= 48) return 'Berkabut';
    if (weatherCode <= 57) return 'Gerimis';
    if (weatherCode <= 67) return 'Hujan';
    if (weatherCode <= 77) return 'Salju';
    if (weatherCode <= 82) return 'Hujan Deras';
    if (weatherCode <= 99) return 'Badai Petir';
    return 'Tidak diketahui';
  }

  /// Ikon yang sesuai kondisi cuaca, dipakai di kartu dashboard
  String get iconName {
    if (weatherCode == 0) return 'sunny';
    if (weatherCode <= 2) return 'partly_cloudy';
    if (weatherCode == 3) return 'cloudy';
    if (weatherCode <= 48) return 'foggy';
    if (weatherCode <= 67) return 'rainy';
    if (weatherCode <= 82) return 'pouring';
    return 'thunderstorm';
  }

  /// Saran singkat terkait habit, supaya cuaca terasa relevan untuk aplikasi ini
  String get habitSuggestion {
    if (weatherCode == 0 || weatherCode <= 2) {
      return 'Cuaca cerah, cocok untuk olahraga atau jalan kaki di luar! ☀️';
    }
    if (weatherCode == 3 || weatherCode <= 48) {
      return 'Langit mendung, tetap semangat jalankan habit hari ini.';
    }
    return 'Sedang hujan, mungkin saatnya habit indoor seperti membaca atau olahraga ringan di rumah.';
  }

  factory WeatherModel.fromOpenMeteo(Map<String, dynamic> json, String city) {
    final current = json['current'];
    return WeatherModel(
      cityName: city,
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
    );
  }
}

class WeatherService {
  // ip-api.com: deteksi kota & koordinat berdasarkan IP, gratis tanpa API key
  static const String _ipUrl = 'http://ip-api.com/json/';
  // Open-Meteo: data cuaca real-time berdasarkan koordinat, gratis tanpa API key
  static const String _weatherBaseUrl =
      'https://api.open-meteo.com/v1/forecast';

  Future<WeatherModel> getCurrentWeather() async {
    // 1. Deteksi lokasi pengguna dari IP
    final ipResponse = await http.get(Uri.parse(_ipUrl));
    if (ipResponse.statusCode != 200) {
      throw Exception('Gagal mendeteksi lokasi');
    }
    final ipData = jsonDecode(ipResponse.body);
    final double lat = (ipData['lat'] as num).toDouble();
    final double lon = (ipData['lon'] as num).toDouble();
    final String city = ipData['city'] ?? 'Lokasimu';

    // 2. Ambil data cuaca berdasarkan koordinat tersebut
    final weatherUrl = Uri.parse(
      '$_weatherBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code',
    );
    final weatherResponse = await http.get(weatherUrl);
    if (weatherResponse.statusCode != 200) {
      throw Exception('Gagal mengambil data cuaca');
    }

    final weatherData = jsonDecode(weatherResponse.body);
    return WeatherModel.fromOpenMeteo(weatherData, city);
  }
}
