import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item_model.dart';

class RestaurantProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<RestaurantModel> _restaurants = [];
  List<MenuItemModel> _menuItems = [];
  bool _isLoading = false;
  String? _error;
  bool _initialized = false;

  List<RestaurantModel> get restaurants => _restaurants;
  List<MenuItemModel> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Gefiltert: nur Restaurants mit isFeatured == true
  List<RestaurantModel> get featuredRestaurants =>
      _restaurants.where((r) => r.isFeatured).toList();

  /// Menü-Einträge, gruppiert nach Restaurant-ID
  Map<String, List<MenuItemModel>> get menuByRestaurant {
    final map = <String, List<MenuItemModel>>{};
    for (final item in _menuItems) {
      map.putIfAbsent(item.restaurantId, () => []);
      map[item.restaurantId]!.add(item);
    }
    return map;
  }

  /// Lädt Restaurants + Menüs aus Firestore
  Future<void> loadRestaurants({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Prüfe Internetverbindung
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        _error = 'Keine Internetverbindung';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Restaurants laden
      final restSnapshot =
          await _firestore.collection('restaurants').get();
      _restaurants = restSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantModel.fromJson(data);
      }).toList();

      // Menü-Items laden
      final menuSnapshot =
          await _firestore.collection('menu_items').get();
      _menuItems = menuSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return MenuItemModel.fromJson(data);
      }).toList();

      _initialized = true;
      _error = null;
    } on FirebaseException catch (e) {
      _error = 'Firebase-Fehler: ${e.message}';
    } catch (e) {
      _error = 'Fehler beim Laden: $e';
    }

    _isLoading = false;
    notifyListeners();

    // Leeres Ergebnis ist ein valider Zustand – kein Fehler
    if (_restaurants.isEmpty && !_isLoading && _error == null) {
      // Kein Fehler, aber auch keine Daten – UI zeigt "Keine Restaurants gefunden"
    }
  }

  /// Gibt ein Restaurant anhand seiner ID zurück
  RestaurantModel? getRestaurantById(String id) {
    try {
      return _restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Gibt die Menü-Einträge eines bestimmten Restaurants zurück
  List<MenuItemModel> getMenuItems(String restaurantId) {
    return _menuItems.where((m) => m.restaurantId == restaurantId).toList();
  }

  /// Durchsucht Restaurants nach Name oder Beschreibung
  List<RestaurantModel> searchRestaurants(String query) {
    if (query.isEmpty) return _restaurants;
    final q = query.toLowerCase();
    return _restaurants.where((r) {
      return r.nameAr.toLowerCase().contains(q) ||
          r.nameEn.toLowerCase().contains(q) ||
          r.descriptionAr.toLowerCase().contains(q) ||
          r.district.toLowerCase().contains(q);
    }).toList();
  }

  /// Durchsucht Menü-Einträge nach Name oder Beschreibung
  List<MenuItemModel> searchMenuItems(String query) {
    if (query.isEmpty) return _menuItems;
    final q = query.toLowerCase();
    return _menuItems.where((m) {
      return m.nameAr.toLowerCase().contains(q) ||
          m.nameEn.toLowerCase().contains(q) ||
          m.descriptionAr.toLowerCase().contains(q);
    }).toList();
  }
}