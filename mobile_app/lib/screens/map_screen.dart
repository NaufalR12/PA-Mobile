import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<Polyline> _polylines = [];
  LatLng? _mylocation;
  LatLng? _selectedLocation;
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String? _selectedLocationName;
  String? _distance;
  String? _duration;

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

    setState(() {
      _distance = null;
      _duration = null;
    });

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
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = LatLng(lat, lon);
                  _selectedLocationName = name;
                });
                _getRoute(LatLng(lat, lon));
                _showLocationDetails(name, type);
              },
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

  // Fungsi untuk mendapatkan rute
  Future<void> _getRoute(LatLng destination) async {
    if (_mylocation == null) return;

    try {
      // Menggunakan OSRM (Open Source Routing Machine)
      final url = Uri.parse(
          'http://router.project-osrm.org/route/v1/driving/${_mylocation!.longitude},${_mylocation!.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok') {
          final List<dynamic> coordinates =
              data['routes'][0]['geometry']['coordinates'];
          final List<LatLng> polylineCoordinates = coordinates
              .map((coord) => LatLng(
                    double.parse(coord[1].toString()),
                    double.parse(coord[0].toString()),
                  ))
              .toList();

          // Mendapatkan jarak dan durasi
          final double distanceInMeters =
              data['routes'][0]['distance'].toDouble();
          final double durationInSeconds =
              data['routes'][0]['duration'].toDouble();

          // Konversi ke format yang lebih mudah dibaca
          String formattedDistance;
          if (distanceInMeters >= 1000) {
            formattedDistance =
                '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
          } else {
            formattedDistance = '${distanceInMeters.toStringAsFixed(0)} m';
          }

          String formattedDuration;
          if (durationInSeconds >= 3600) {
            final hours = (durationInSeconds / 3600).floor();
            final minutes = ((durationInSeconds % 3600) / 60).floor();
            formattedDuration =
                '$hours jam ${minutes > 0 ? '$minutes menit' : ''}';
          } else {
            final minutes = (durationInSeconds / 60).floor();
            formattedDuration = '$minutes menit';
          }

          setState(() {
            _distance = formattedDistance;
            _duration = formattedDuration;
            _polylines = [
              Polyline(
                points: polylineCoordinates,
                color: Colors.blue,
                strokeWidth: 5,
              ),
            ];
          });
        }
      }
    } catch (e) {
      print('Error getting route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mendapatkan rute: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Fungsi untuk membuka aplikasi maps
  Future<void> _openMaps(LatLng destination) async {
    try {
      // Mencoba membuka dengan Google Maps menggunakan geo: URI
      final googleMapsUrl =
          'geo:${destination.latitude},${destination.longitude}?q=${destination.latitude},${destination.longitude}';

      // Alternatif dengan Google Maps web
      final googleMapsWebUrl =
          'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}';

      // Alternatif dengan OpenStreetMap
      final osmUrl =
          'https://www.openstreetmap.org/?mlat=${destination.latitude}&mlon=${destination.longitude}#map=15/${destination.latitude}/${destination.longitude}';

      // Coba buka dengan geo: URI terlebih dahulu
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      // Jika tidak berhasil, coba buka Google Maps web
      else if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
        await launchUrl(
          Uri.parse(googleMapsWebUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      // Jika masih tidak berhasil, coba buka OpenStreetMap
      else if (await canLaunchUrl(Uri.parse(osmUrl))) {
        await launchUrl(
          Uri.parse(osmUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Tidak dapat membuka aplikasi maps. Pastikan Anda memiliki aplikasi maps yang terinstall.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error opening maps: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka aplikasi maps: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Fungsi untuk menampilkan detail lokasi
  void _showLocationDetails(String name, String type) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Tipe: ${type == 'bank' ? 'Bank' : 'ATM'}'),
            if (_distance != null && _duration != null) ...[
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Icon(Icons.directions_walk, color: Colors.blue),
                      SizedBox(height: 4),
                      Text(
                        _distance!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Jarak'),
                    ],
                  ),
                  Column(
                    children: [
                      Icon(Icons.timer, color: Colors.orange),
                      SizedBox(height: 4),
                      Text(
                        _duration!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Waktu Tempuh'),
                    ],
                  ),
                ],
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedLocation != null) {
                  _openMaps(_selectedLocation!);
                }
              },
              icon: Icon(Icons.directions),
              label: Text('Buka di Maps'),
            ),
          ],
        ),
      ),
    );
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
              PolylineLayer(polylines: _polylines),
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
