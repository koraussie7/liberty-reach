// lib/services/location_service.dart
/// Location service — Google Maps Nearby Search, Geocoding, etc.
/// Communicates with backend proxy at /api/location/*
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';

/// A nearby place result from Google Places API.
class NearbyPlace {
  final String placeId;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double? rating;
  final List<String> types;
  final String? photoRef;
  final bool? openNow;
  final int? priceLevel;

  const NearbyPlace({
    required this.placeId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.rating,
    this.types = const [],
    this.photoRef,
    this.openNow,
    this.priceLevel,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      placeId: json['place_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble(),
      types: (json['types'] as List?)?.cast<String>() ?? [],
      photoRef: json['photo_ref'] as String?,
      openNow: json['open_now'] as bool?,
      priceLevel: json['price_level'] as int?,
    );
  }

  /// Get the Google Places photo URL (if photo_ref is available).
  String? get photoUrl =>
      photoRef != null
          ? 'https://maps.googleapis.com/maps/api/place/photo'
              '?maxwidth=400&photoreference=$photoRef&key='
          : null;

  /// Icon based on place type.
  String get emoji {
    if (types.contains('restaurant') || types.contains('food')) return '🍽️';
    if (types.contains('hotel') || types.contains('lodging')) return '🏨';
    if (types.contains('spa')) return '💆';
    if (types.contains('cafe')) return '☕';
    if (types.contains('bar')) return '🍸';
    if (types.contains('hospital') || types.contains('doctor')) return '🏥';
    if (types.contains('gym') || types.contains('fitness')) return '💪';
    if (types.contains('store') || types.contains('shopping')) return '🛍️';
    if (types.contains('gas_station')) return '⛽';
    if (types.contains('park')) return '🌳';
    return '📍';
  }
}

/// Category filter for nearby search.
class PlaceCategory {
  final String type;
  final String label;
  final String emoji;
  final int radius; // meters

  const PlaceCategory({
    required this.type,
    required this.label,
    required this.emoji,
    this.radius = 1500,
  });

  static const List<PlaceCategory> all = [
    PlaceCategory(type: 'restaurant', label: 'Restaurants', emoji: '🍽️', radius: 1500),
    PlaceCategory(type: 'hotel', label: 'Hotels', emoji: '🏨', radius: 3000),
    PlaceCategory(type: 'spa', label: 'Spa & Massage', emoji: '💆', radius: 2000),
    PlaceCategory(type: 'cafe', label: 'Cafes', emoji: '☕', radius: 1000),
    PlaceCategory(type: 'bar', label: 'Bars & Nightlife', emoji: '🍸', radius: 1500),
    PlaceCategory(type: 'gym', label: 'Gyms', emoji: '💪', radius: 2000),
  ];
}

class LocationService extends ChangeNotifier {
  final http.Client _client = http.Client();
  final String _baseUrl = AppConstants.apiBaseUrl;

  // Current state
  List<NearbyPlace> _nearbyPlaces = [];
  bool _isLoading = false;
  String? _error;
  PlaceCategory _selectedCategory = PlaceCategory.all[0];
  Position? _currentPosition;

  // Getters
  List<NearbyPlace> get nearbyPlaces => _nearbyPlaces;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PlaceCategory get selectedCategory => _selectedCategory;
  Position? get currentPosition => _currentPosition;
  double get currentLat => _currentPosition?.latitude ?? 37.5665;
  double get currentLng => _currentPosition?.longitude ?? 126.9780;

  /// Get user's current location.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      _currentPosition = pos;
      notifyListeners();
      return pos;
    } catch (e) {
      debugPrint('[LocationService] position error: $e');
      return null;
    }
  }

  /// Search for nearby places by category.
  Future<void> searchNearby({
    PlaceCategory? category,
    double? lat,
    double? lng,
    int? radius,
  }) async {
    final cat = category ?? _selectedCategory;
    if (category != null) _selectedCategory = category;

    final useLat = lat ?? currentLat;
    final useLng = lng ?? currentLng;
    final rad = radius ?? cat.radius;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await _client
          .post(
            Uri.parse('$_baseUrl/api/location/nearby'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lat': useLat,
              'lng': useLng,
              'radius': rad,
              'type': cat.type,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _nearbyPlaces = (data['results'] as List?)
                ?.map((p) =>
                    NearbyPlace.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        _error = 'Search failed (${resp.statusCode})';
      }
    } catch (e) {
      debugPrint('[LocationService] search error: $e');
      _error = 'Could not search nearby places';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set category and re-search.
  Future<void> setCategory(PlaceCategory category) async {
    if (category.type == _selectedCategory.type) return;
    await searchNearby(category: category);
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
