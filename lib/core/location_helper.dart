import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final double latitude;
  final double longitude;
  final String alamatLengkap;
  final String mapsUrl;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.alamatLengkap,
    required this.mapsUrl,
  });
}

class LocationHelper {
  // Titik Pusat PPM Al-Ajwah (Batu Ampar, Balikpapan)
  static const double pondokLat = -1.214562;
  static const double pondokLng = 116.838224;
  static const double defaultRadiusMeters = 100.0;

  /// Memeriksa izin GPS, meminta izin popup ke user jika belum ada, dan mengambil koordinat
  static Future<LocationResult> getCurrentLocationWithAddress() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Minta user menyalakan GPS jika belum aktif
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS di HP Anda belum aktif. Silakan aktifkan layanan lokasi/GPS.');
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak. Klik untuk meminta izin lagi.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('Izin lokasi ditolak permanen. Silakan izinkan di menu Pengaturan Aplikasi HP.');
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );

    String alamatText = 'Koordinat: ${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'PPMAlAjwahApp/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['display_name'] != null) {
          alamatText = data['display_name'].toString();
        }
      }
    } catch (_) {}

    final String mapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      alamatLengkap: alamatText,
      mapsUrl: mapsUrl,
    );
  }

  static double getDistanceToPondok(double currentLat, double currentLng) {
    return Geolocator.distanceBetween(
      currentLat,
      currentLng,
      pondokLat,
      pondokLng,
    );
  }
}