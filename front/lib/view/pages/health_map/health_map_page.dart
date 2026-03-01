import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/constants.dart';
import '../../../models/ai_response.dart';
import '../../../service/ai_service.dart';

class HealthMapPage extends StatefulWidget {
  const HealthMapPage({super.key});

  @override
  State<HealthMapPage> createState() => _HealthMapPageState();
}

class _HealthMapPageState extends State<HealthMapPage> {
  static const _defaultPosition = LatLng(48.8566, 2.3522); // Paris fallback

  GoogleMapController? _mapController;
  LatLng _myPosition = _defaultPosition;
  final Set<Marker> _markers = {};
  List<AiPlace> _doctors = [];
  AiPlace? _selectedDoctor;
  String? _aiNote;
  bool _loading = true;
  String? _error;

  // ── lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Get device location
      final pos = await _requestLocation();
      if (pos != null) {
        _myPosition = LatLng(pos.latitude, pos.longitude);
      }

      // 2. Call AI backend
      final response = await AiService.instance.chat(
        lat: _myPosition.latitude,
        lng: _myPosition.longitude,
        includeDoctors: true,
        includeNutrition: false,
      );

      if (response != null) {
        _doctors = response.doctors;
        _aiNote = response.note;
        _buildMarkers();
      } else {
        _error = 'Impossible de charger les médecins. Vérifiez la connexion.';
      }
    } catch (e) {
      _error = 'Erreur : $e';
    } finally {
      setState(() => _loading = false);
      // Move camera to user position
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_myPosition, 14),
      );
    }
  }

  Future<Position?> _requestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  void _buildMarkers() {
    _markers.clear();
    // User location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('_me'),
        position: _myPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: 'Ma position'),
      ),
    );

    for (int i = 0; i < _doctors.length; i++) {
      final d = _doctors[i];
      if (d.lat == null || d.lng == null) continue;
      _markers.add(
        Marker(
          markerId: MarkerId(d.placeId ?? 'doc_$i'),
          position: LatLng(d.lat!, d.lng!),
          infoWindow: InfoWindow(title: d.name, snippet: d.address),
          onTap: () => setState(() => _selectedDoctor = d),
        ),
      );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _myPosition,
            zoom: 14,
          ),
          onMapCreated: (c) => _mapController = c,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
        ),
        // ── Top bar ─────────────────────────────────────────────────────
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
                if (_loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.medical_services, color: AppColors.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _loading
                            ? 'Recherche en cours...'
                            : 'Médecins à proximité',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_aiNote != null && !_loading)
                        Text(
                          _aiNote!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (!_loading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: AppColors.primaryColor,
                    tooltip: 'Actualiser',
                    onPressed: _loadDoctors,
                  ),
              ],
            ),
          ),
        ),
        // ── Bottom sheet ────────────────────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.35,
          minChildSize: 0.2,
          maxChildSize: 0.65,
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
              child: _selectedDoctor != null
                  ? _buildDoctorDetail(scrollController, _selectedDoctor!)
                  : _buildDoctorList(scrollController),
            );
          },
        ),
      ],
    );
  }

  // ── doctor list ────────────────────────────────────────────────────────
  Widget _buildDoctorList(ScrollController sc) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _handle(),
        const SizedBox(height: 16),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              style: GoogleFonts.inter(
                color: AppColors.sugarWarning,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else if (_doctors.isEmpty)
          Text(
            'Aucun médecin trouvé à proximité.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          )
        else ...[
          Text(
            '${_doctors.length} médecin(s) recommandé(s)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ..._doctors.map((d) => _doctorTile(d)),
        ],
      ],
    );
  }

  // ── doctor detail ──────────────────────────────────────────────────────
  Widget _buildDoctorDetail(ScrollController sc, AiPlace d) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _handle(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              child: Icon(Icons.local_hospital,
                  size: 28, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (d.address != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: AppColors.primaryColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              d.address!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (d.openNow != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (d.openNow!
                                  ? AppColors.sugarNormal
                                  : AppColors.sugarWarning)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          d.openNow! ? 'Ouvert maintenant' : 'Fermé',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: d.openNow!
                                ? AppColors.sugarNormal
                                : AppColors.sugarWarning,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedDoctor = null),
              child: Text(
                'Retour',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (d.lat != null && d.lng != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(LatLng(d.lat!, d.lng!), 17),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text('Voir sur la carte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── doctor tile ────────────────────────────────────────────────────────
  Widget _doctorTile(AiPlace d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
          child: Icon(Icons.local_hospital, color: AppColors.primaryColor),
        ),
        title: Text(
          d.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          [
            if (d.address != null) d.address!,
            if (d.openNow == true) 'Ouvert',
          ].join(' • '),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          setState(() => _selectedDoctor = d);
          if (d.lat != null && d.lng != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(d.lat!, d.lng!), 16),
            );
          }
        },
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────
  Widget _handle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

