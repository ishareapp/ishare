import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../core/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../core/extensions/translation_extension.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int bookingId;
  final String driverName;
  final String driverPhone;
  final String passengerName;
  final String passengerPhone;
  final bool isDriver;
  
  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    required this.driverName,
    required this.driverPhone,
    required this.passengerName,
    required this.passengerPhone,
    required this.isDriver,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  Position? _otherPersonPosition;
  Timer? _locationTimer;
  bool _isTracking = false;
  bool _isSosActive = false;
  
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  
  // Emergency contacts
  final String policeNumber = "112";
  final String ambulanceNumber = "912";

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showPermissionDialog();
      return;
    }
    
    // Start tracking
    await _getCurrentLocation();
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _isTracking = true;
      });
      
      // Send location to backend
      await _sendLocationUpdate(position);
      
      // Fetch other person's location
      await _fetchOtherPersonLocation();
      
      // Update map
      _updateMap();
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _startLocationUpdates() {
    // Update location every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _getCurrentLocation();
    });
  }

  Future<void> _sendLocationUpdate(Position position) async {
    try {
      final token = await StorageService.getToken();
      
      await http.post(
        Uri.parse("${StorageService.baseUrl}/rides/update-location/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "booking_id": widget.bookingId,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "is_driver": widget.isDriver,
        }),
      );
    } catch (e) {
      print("Error sending location: $e");
    }
  }

  Future<void> _fetchOtherPersonLocation() async {
    try {
      final token = await StorageService.getToken();
      
      final response = await http.get(
        Uri.parse("${StorageService.baseUrl}/rides/get-location/${widget.bookingId}/"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final otherLocation = widget.isDriver 
            ? data['passenger_location'] 
            : data['driver_location'];
        
        if (otherLocation != null) {
          setState(() {
            _otherPersonPosition = Position(
              latitude: otherLocation['latitude'],
              longitude: otherLocation['longitude'],
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching other location: $e");
    }
  }

  void _updateMap() {
    if (_currentPosition == null) return;
    
    List<Marker> markers = [];
    
    // Current user marker
    markers.add(
      Marker(
        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        width: 80,
        height: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isDriver ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isDriver ? 'You (Driver)' : 'You',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.navigation,
              color: widget.isDriver ? Colors.blue : Colors.green,
              size: 40,
            ),
          ],
        ),
      ),
    );
    
    // Other person marker
    if (_otherPersonPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_otherPersonPosition!.latitude, _otherPersonPosition!.longitude),
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDriver ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.isDriver ? widget.passengerName : widget.driverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.person_pin_circle,
                color: widget.isDriver ? Colors.green : Colors.blue,
                size: 40,
              ),
            ],
          ),
        ),
      );
      
      // Draw route line
      _polylines = [
        Polyline(
          points: [
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            LatLng(_otherPersonPosition!.latitude, _otherPersonPosition!.longitude),
          ],
          color: const Color(0xFF1E3A8A),
          strokeWidth: 4.0,
        ),
      ];
    }
    
    setState(() {
      _markers = markers;
    });
    
    // Move camera to show both markers
    if (_otherPersonPosition != null) {
      _fitBounds();
    } else {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        14.0,
      );
    }
  }

  void _fitBounds() {
    if (_currentPosition == null || _otherPersonPosition == null) return;
    
    final bounds = LatLngBounds(
      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      LatLng(_otherPersonPosition!.latitude, _otherPersonPosition!.longitude),
    );
    
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Future<void> _triggerSOS() async {
    setState(() => _isSosActive = true);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            const Text(
              "SOS ACTIVATED",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emergency alert has been sent!",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text("Your location has been shared with:"),
            const SizedBox(height: 8),
            Text("• ${widget.isDriver ? widget.passengerName : widget.driverName}"),
            const Text("• Emergency contacts"),
            const Text("• ISHARE support team"),
            const SizedBox(height: 16),
            const Text(
              "What would you like to do?",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _callPolice();
            },
            icon: const Icon(Icons.phone),
            label: const Text("Call Police"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    // Send SOS alert to backend
    try {
      final token = await StorageService.getToken();
      
      await http.post(
        Uri.parse("${StorageService.baseUrl}/rides/sos-alert/"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "booking_id": widget.bookingId,
          "latitude": _currentPosition?.latitude,
          "longitude": _currentPosition?.longitude,
          "is_driver": widget.isDriver,
        }),
      );
    } catch (e) {
      print("Error sending SOS: $e");
    }
  }

  Future<void> _callPolice() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: policeNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _callOtherPerson() async {
    final phone = widget.isDriver ? widget.passengerPhone : widget.driverPhone;
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _shareLocation() async {
    if (_currentPosition == null) return;
    
    final String googleMapsUrl = 
        "https://www.google.com/maps?q=${_currentPosition!.latitude},${_currentPosition!.longitude}";
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Location: $googleMapsUrl"),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: "Open",
          onPressed: () async {
            final Uri url = Uri.parse(googleMapsUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Permission Required"),
        content: const Text(
          "This feature requires location access to track your ride and provide emergency services. "
          "Please enable location permission in settings.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Tracking"),
        centerTitle: true,
        backgroundColor: _isSosActive ? Colors.red : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _callOtherPerson,
            tooltip: "Call ${widget.isDriver ? 'Passenger' : 'Driver'}",
          ),
          IconButton(
            icon: const Icon(Icons.share_location),
            onPressed: _shareLocation,
            tooltip: "Share Location",
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    initialZoom: 14.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ishare.ridesharing',
                    ),
                    PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),
          
          // Top Info Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E3A8A),
                      child: Text(
                        widget.isDriver 
                            ? widget.passengerName[0].toUpperCase()
                            : widget.driverName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isDriver ? widget.passengerName : widget.driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            widget.isDriver ? "Passenger" : "Driver",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isTracking)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Live",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // SOS Button (Floating)
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _triggerSOS,
              backgroundColor: _isSosActive ? Colors.red.shade700 : Colors.red,
              icon: const Icon(Icons.sos, size: 32),
              label: Text(
                _isSosActive ? "SOS ACTIVE" : "SOS",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}