import 'dart:math';

class DistanceService {
  static double milesBetween({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusMiles = 3958.8;

    final lat1Radians = _degreesToRadians(lat1);
    final lon1Radians = _degreesToRadians(lon1);
    final lat2Radians = _degreesToRadians(lat2);
    final lon2Radians = _degreesToRadians(lon2);

    final deltaLat = lat2Radians - lat1Radians;
    final deltaLon = lon2Radians - lon1Radians;

    final a = pow(sin(deltaLat / 2), 2) +
        cos(lat1Radians) *
            cos(lat2Radians) *
            pow(sin(deltaLon / 2), 2);

    final c = 2 * atan2(
      sqrt(a),
      sqrt(1 - a),
    );

    return earthRadiusMiles * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}