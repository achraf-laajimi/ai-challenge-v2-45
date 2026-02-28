import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants.dart';

class DoctorMarker {
  final String id;
  final String name;
  final String specialty;
  final double distanceKm;
  final LatLng position;

  DoctorMarker({
    required this.id,
    required this.name,
    required this.specialty,
    required this.distanceKm,
    required this.position,
  });
}

class HealthMapPage extends StatefulWidget {
  const HealthMapPage({super.key});

  @override
  State<HealthMapPage> createState() => _HealthMapPageState();
}

class _HealthMapPageState extends State<HealthMapPage> {
  static const _initialPosition = LatLng(48.8566, 2.3522); // Paris
  final Set<Marker> _markers = {};
  DoctorMarker? _selectedDoctor;
  final List<DoctorMarker> _doctors = [
    DoctorMarker(
      id: '1',
      name: 'Dr. Marie Dupont',
      specialty: 'Médecin généraliste',
      distanceKm: 0.8,
      position: const LatLng(48.8580, 2.3540),
    ),
    DoctorMarker(
      id: '2',
      name: 'Dr. Jean Martin',
      specialty: 'Pédiatre',
      distanceKm: 1.2,
      position: const LatLng(48.8550, 2.3500),
    ),
    DoctorMarker(
      id: '3',
      name: 'Dr. Sophie Bernard',
      specialty: 'Cardiologue',
      distanceKm: 2.1,
      position: const LatLng(48.8600, 2.3480),
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final d in _doctors) {
      _markers.add(
        Marker(
          markerId: MarkerId(d.id),
          position: d.position,
          onTap: () => setState(() => _selectedDoctor = d),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _initialPosition,
            zoom: 14,
          ),
          markers: _markers,
          myLocationEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),
        // Top bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Médecins à proximité',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom sheet with doctor list / detail
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppStyles.radiusLarge),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _selectedDoctor == null
                  ? ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sélectionnez un médecin sur la carte',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._doctors.map((d) => _doctorTile(d)),
                      ],
                    )
                  : ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.person,
                                size: 40, color: AppColors.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedDoctor!.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _selectedDoctor!.specialty,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 16,
                                          color: AppColors.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_selectedDoctor!.distanceKm.toStringAsFixed(1)} km',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _selectedDoctor = null),
                              child: Text(
                                'Fermer',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _doctorTile(DoctorMarker d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
          child: Icon(Icons.person, color: AppColors.primaryColor),
        ),
        title: Text(
          d.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${d.specialty} • ${d.distanceKm.toStringAsFixed(1)} km',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: () => setState(() => _selectedDoctor = d),
      ),
    );
  }
}
