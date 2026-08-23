import 'package:supabase_flutter/supabase_flutter.dart';

class CommuteResult {
  final double distanceMiles;
  final int durationMinutes;

  const CommuteResult({
    required this.distanceMiles,
    required this.durationMinutes,
  });
}

class CommuteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CommuteResult> getCommute({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final response = await _supabase.functions.invoke(
      'commute-time',
      body: {
        'originLatitude': originLatitude,
        'originLongitude': originLongitude,
        'destinationLatitude': destinationLatitude,
        'destinationLongitude': destinationLongitude,
      },
    );

    final data = response.data;

    if (data == null || data is! Map) {
      throw Exception('Invalid commute-time response.');
    }

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    return CommuteResult(
      distanceMiles:
          (data['distanceMiles'] as num).toDouble(),
      durationMinutes:
          (data['durationMinutes'] as num).toInt(),
    );
  }
}