import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HousingMapScreen extends StatelessWidget {
  final List<Map<String, dynamic>> listings;

  const HousingMapScreen({
    super.key,
    required this.listings,
  });

  @override
  Widget build(BuildContext context) {
    final markers = listings.map((listing) {
      final latitude =
          (listing['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude =
          (listing['longitude'] as num?)?.toDouble() ?? 0.0;

      return Marker(
        markerId: MarkerId(
          listing['id']?.toString() ?? listing['title'].toString(),
        ),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: listing['title']?.toString() ?? 'Housing Listing',
          snippet:
              '\$${(listing['monthly_rent'] as num?)?.toDouble().toStringAsFixed(0) ?? '0'}/month',
        ),
      );
    }).toSet();

    const initialPosition = CameraPosition(
      target: LatLng(
        36.8508,
        -76.2859,
      ),
      zoom: 11.5,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Housing Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: initialPosition,
        markers: markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}