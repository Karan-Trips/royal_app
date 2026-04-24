import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches temperature for the given coordinates using Open-Meteo (free, no API key).
/// Falls back to Ahmedabad coords if none provided.
/// Returns mock 42.0 on failure so the warning still shows in dev.
Future<double> fetchAhmedabadTemp({
  double latitude = 23.0225,
  double longitude = 72.5714,
}) async {
  try {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true';
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['current_weather']['temperature'] as num).toDouble();
    }
  } catch (_) {}
  return 42.0; // mock fallback
}

bool isHeatWarning(double temp) => temp > 40.0;
