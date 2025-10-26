import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckInMapSheet extends StatefulWidget {
  final LatLng userLatLng;
  final LatLng facilityLatLng;
  final double facilityRadiusMeters;
  final Future<void> Function() onConfirm;

  const CheckInMapSheet({
    super.key,
    required this.userLatLng,
    required this.facilityLatLng,
    required this.onConfirm,
    this.facilityRadiusMeters = 100.0,
  });

  @override
  State<CheckInMapSheet> createState() => _CheckInMapSheetState();
}

class _CheckInMapSheetState extends State<CheckInMapSheet> {
  GoogleMapController? _controller;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final canConfirm = _distanceMeters(widget.userLatLng, widget.facilityLatLng) <= widget.facilityRadiusMeters;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user'),
        position: widget.userLatLng,
        infoWindow: const InfoWindow(title: 'You'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('facility'),
        position: widget.facilityLatLng,
        infoWindow: const InfoWindow(title: 'Facility'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('facility_radius'),
        center: widget.facilityLatLng,
        radius: widget.facilityRadiusMeters,
        strokeColor: Colors.green,
        strokeWidth: 2,
        fillColor: Colors.green.withOpacity(0.12),
      ),
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.map, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Confirm your location within 100m',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_distanceMeters(widget.userLatLng, widget.facilityLatLng).toStringAsFixed(0)} m',
                    style: TextStyle(
                      color: canConfirm ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _midpoint(widget.userLatLng, widget.facilityLatLng),
                  zoom: 17,
                ),
                markers: markers,
                circles: circles,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (c) => _controller = c,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (!canConfirm || _submitting)
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          try {
                            await widget.onConfirm();
                            if (mounted) Navigator.of(context).pop();
                          } finally {
                            if (mounted) setState(() => _submitting = false);
                          }
                        },
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(_submitting ? 'Checking In...' : 'Confirm Check-in'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const double earthRadius = 6371000.0;
    final double dLat = _degToRad(b.latitude - a.latitude);
    final double dLon = _degToRad(b.longitude - a.longitude);
    final double lat1 = _degToRad(a.latitude);
    final double lat2 = _degToRad(b.latitude);
    final double h =
        (1 - (MathCos(dLat) + MathCos(lat1 + lat2) * (1 - MathCos(dLon))) / 2)
            .clamp(0.0, 1.0);
    return earthRadius * 2 * MathAsin(MathSqrt(h));
  }

  LatLng _midpoint(LatLng a, LatLng b) {
    return LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);
}

// Small math helpers to avoid importing dart:math here
double MathCos(double x) => _cos(x);
double MathAsin(double x) => _asin(x);
double MathSqrt(double x) => _sqrt(x);

double _cos(double x) =>
    1 - (x * x) / 2 + (x * x * x * x) / 24 - (x * x * x * x * x * x) / 720;
double _asin(double x) {
  // Padé approximation for small x (sufficient for distance angle domain)
  final double x2 = x * x;
  return x * (1 + (1.0 / 6.0) * x2 + (3.0 / 40.0) * x2 * x2);
}
double _sqrt(double x) {
  double guess = x > 1 ? x / 2 : 1;
  for (int i = 0; i < 6; i++) {
    guess = 0.5 * (guess + x / guess);
  }
  return guess;
}


