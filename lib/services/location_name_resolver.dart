import 'dart:math' as math;

class LocationNameResolver {
  static const _places = <_KnownPlace>[
    _KnownPlace('Tiruchirappalli (Trichy), Tamil Nadu', 10.7905, 78.7047),
    _KnownPlace('Chennai, Tamil Nadu', 13.0827, 80.2707),
    _KnownPlace('Coimbatore, Tamil Nadu', 11.0168, 76.9558),
    _KnownPlace('Madurai, Tamil Nadu', 9.9252, 78.1198),
    _KnownPlace('Salem, Tamil Nadu', 11.6643, 78.1460),
    _KnownPlace('Tirunelveli, Tamil Nadu', 8.7139, 77.7567),
    _KnownPlace('Thanjavur, Tamil Nadu', 10.7870, 79.1378),
    _KnownPlace('Erode, Tamil Nadu', 11.3410, 77.7172),
    _KnownPlace('Tiruppur, Tamil Nadu', 11.1085, 77.3411),
    _KnownPlace('Vellore, Tamil Nadu', 12.9165, 79.1325),
    _KnownPlace('Dindigul, Tamil Nadu', 10.3673, 77.9803),
    _KnownPlace('Karur, Tamil Nadu', 10.9601, 78.0766),
    _KnownPlace('Kumbakonam, Tamil Nadu', 10.9617, 79.3881),
    _KnownPlace('Nagapattinam, Tamil Nadu', 10.7672, 79.8449),
    _KnownPlace('Cuddalore, Tamil Nadu', 11.7447, 79.7680),
    _KnownPlace('Pudukkottai, Tamil Nadu', 10.3797, 78.8208),
    _KnownPlace('Namakkal, Tamil Nadu', 11.2189, 78.1677),
    _KnownPlace('Dharmapuri, Tamil Nadu', 12.1211, 78.1582),
    _KnownPlace('Krishnagiri, Tamil Nadu', 12.5186, 78.2137),
    _KnownPlace('Thoothukudi, Tamil Nadu', 8.7642, 78.1348),
    _KnownPlace('Kanyakumari, Tamil Nadu', 8.0883, 77.5385),
    _KnownPlace('Ramanathapuram, Tamil Nadu', 9.3639, 78.8395),
    _KnownPlace('Sivaganga, Tamil Nadu', 9.8433, 78.4809),
    _KnownPlace('Virudhunagar, Tamil Nadu', 9.5680, 77.9624),
    _KnownPlace('Perambalur, Tamil Nadu', 11.2320, 78.8807),
    _KnownPlace('Ariyalur, Tamil Nadu', 11.1401, 79.0786),
    _KnownPlace('Villupuram, Tamil Nadu', 11.9401, 79.4861),
    _KnownPlace('Tiruvannamalai, Tamil Nadu', 12.2253, 79.0747),
  ];

  static String resolve(double latitude, double longitude) {
    var nearest = _places.first;
    var nearestDistance = double.infinity;
    for (final place in _places) {
      final distance = _distanceKm(
        latitude,
        longitude,
        place.latitude,
        place.longitude,
      );
      if (distance < nearestDistance) {
        nearest = place;
        nearestDistance = distance;
      }
    }
    if (nearestDistance <= 85) return nearest.name;
    return 'GPS • ${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
  }

  static double _distanceKm(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const radius = 6371.0;
    double radians(double value) => value * math.pi / 180;
    final latitudeDelta = radians(latitudeB - latitudeA);
    final longitudeDelta = radians(longitudeB - longitudeA);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(radians(latitudeA)) *
            math.cos(radians(latitudeB)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final safeA = a.clamp(0.0, 1.0).toDouble();
    return radius * 2 * math.atan2(math.sqrt(safeA), math.sqrt(1 - safeA));
  }
}

class _KnownPlace {
  final String name;
  final double latitude;
  final double longitude;

  const _KnownPlace(this.name, this.latitude, this.longitude);
}
