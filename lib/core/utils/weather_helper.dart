import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches temperature for Ahmedabad using Open-Meteo (free, no API key).
/// Returns mock 42.0 on failure so the warning still shows in dev.
Future<double> fetchAhmedabadTemp() async {
  try {
    // Ahmedabad coords: 23.0225° N, 72.5714° E
    const url =
        'https://api.open-meteo.com/v1/forecast?latitude=23.0225&longitude=72.5714&current_weather=true';
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['current_weather']['temperature'] as num).toDouble();
    }
  } catch (_) {}
  return 42.0; // mock fallback
}

bool isHeatWarning(double temp) => temp > 40.0;
