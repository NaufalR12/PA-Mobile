import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'marker_data.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  List<Marker> _markers = [];
  LatLng? _mylocation;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // get current location
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi GPS tidak aktif. Mohon aktifkan GPS Anda.'),
            duration: Duration(seconds: 3),
          ),
        );
        return Future.error("Location services are disabled");
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Izin lokasi ditolak. Beberapa fitur mungkin tidak berfungsi.'),
              duration: Duration(seconds: 3),
            ),
          );
          return Future.error("Location permissions are denied");
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Izin lokasi ditolak secara permanen. Mohon aktifkan di pengaturan aplikasi.'),
            duration: Duration(seconds: 3),
          ),
        );
        return Future.error("Location permissions are permanently denied");
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      );
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          duration: Duration(seconds: 3),
        ),
      );
      rethrow;
    }
  }

  // Load nearby banks and ATMs using Overpass API
  Future<void> _loadNearbyBanksAndATMs() async {
    if (_mylocation == null) return;

    final query = '''
    [out:json];
    (
      node["amenity"="bank"](around:2000,${_mylocation!.latitude},${_mylocation!.longitude});
      node["amenity"="atm"](around:2000,${_mylocation!.latitude},${_mylocation!.longitude});
    );
    out body;
    ''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    final response = await http.post(url, body: {'data': query});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final elements = data['elements'] as List;

      setState(() {
        _markers.clear();
        _markers = elements.map((element) {
          final lat = element['lat'];
          final lon = element['lon'];
          final name = element['tags']?['name'] ?? 'Tanpa Nama';
          final type = element['tags']?['amenity'];

          return Marker(
            point: LatLng(lat, lon),
            width: 80,
            height: 80,
            child: Column(
              children: [
                Icon(
                  type == 'bank' ? Icons.account_balance : Icons.atm,
                  color: type == 'bank' ? Colors.blueAccent : Colors.green,
                  size: 30,
                ),
                Text(
                  name,
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList();
      });
    } else {
      print("Gagal memuat data Overpass: ${response.statusCode}");
    }
  }

  // show current location
  void _showCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      print('Location obtained: ${position.latitude}, ${position.longitude}');

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLatLng, 15.0);

      setState(() {
        _mylocation = currentLatLng;
      });

      await _loadNearbyBanksAndATMs();
    } catch (e) {
      print('Error in _showCurrentLocation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan lokasi: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // search with distance sorting
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty || _mylocation == null) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=10&countrycodes=ID&accept-language=id';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    final Distance distance = Distance();

    if (data.isNotEmpty) {
      final results = (data as List).map((item) {
        final lat = double.tryParse(item['lat'] ?? '0') ?? 0;
        final lon = double.tryParse(item['lon'] ?? '0') ?? 0;
        final dist = distance.as(
          LengthUnit.Kilometer,
          _mylocation!,
          LatLng(lat, lon),
        );
        return {...item, 'distance': dist};
      }).toList();

      results.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        _searchResults = results;
      });
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }

  // move to specific location
  void _moveToLocation(double lat, double lon) {
    LatLng location = LatLng(lat, lon);
    _mapController.move(location, 15.0);

    setState(() {
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _showCurrentLocation();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _searchPlaces(_searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank & ATM Terdekat'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(-7.7769, 110.3572),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(markers: _markers),
              if (_mylocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _mylocation!,
                      width: 80,
                      height: 80,
                      child: Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                SizedBox(
                  height: 55,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari lokasi...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _searchResults = [];
                                });
                              },
                              icon: Icon(Icons.clear),
                            )
                          : null,
                    ),
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                ),
                if (_isSearching && _searchResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (ctx, index) {
                        final place = _searchResults[index];
                        final distance = place['distance'] as double;
                        return ListTile(
                          title: Text(place['display_name']),
                          subtitle:
                              Text('Jarak: ${distance.toStringAsFixed(1)} km'),
                          onTap: () {
                            final lat = double.parse(place['lat']);
                            final lon = double.parse(place['lon']);
                            _moveToLocation(lat, lon);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              onPressed: _showCurrentLocation,
              child: Icon(Icons.location_searching_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
