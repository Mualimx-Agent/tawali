import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/firebase_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Bestellung in Firestore anlegen
  Future<OrderModel?> placeOrder(OrderModel order) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection(FirebaseService.ordersCollection).doc();
      final data = order.toJson();
      data['id'] = docRef.id;
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      await docRef.set(data);

      final savedOrder = OrderModel.fromJson(data);
      _currentOrder = savedOrder;
      _orders.insert(0, savedOrder);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return savedOrder;
    } on FirebaseException catch (e) {
      _error = 'Firebase-Fehler: ${e.message}';
    } catch (e) {
      _error = 'Fehler beim Aufgeben der Bestellung: $e';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  /// Bestellungen eines Users aus Firestore laden
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection(FirebaseService.ordersCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      _orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return OrderModel.fromJson(data);
      }).toList();

      _error = null;
    } on FirebaseException catch (e) {
      _error = 'Firebase-Fehler: ${e.message}';
    } catch (e) {
      _error = 'Fehler beim Laden der Bestellungen: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Eine einzelne Bestellung aus Firestone laden
  Future<void> loadOrder(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection(FirebaseService.ordersCollection)
          .doc(orderId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        _currentOrder = OrderModel.fromJson(data);
      } else {
        _error = 'Bestellung nicht gefunden';
      }
    } on FirebaseException catch (e) {
      _error = 'Firebase-Fehler: ${e.message}';
    } catch (e) {
      _error = 'Fehler: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Bestellung stornieren (cancelled) in Firestore
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      await _firestore
          .collection(FirebaseService.ordersCollection)
          .doc(orderId)
          .update({
        'order_status': 'cancelled',
        'cancellation_reason': reason ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      });

      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          orderStatus: 'cancelled',
          cancellationReason: reason,
          updatedAt: DateTime.now(),
        );
        if (_currentOrder?.id == orderId) {
          _currentOrder = _orders[index];
        }
        notifyListeners();
      }
    } on FirebaseException catch (e) {
      _error = 'Fehler beim Stornieren: ${e.message}';
      notifyListeners();
    }
  }

  /// Echtzeit-Update für die aktuelle Bestellung (für Bestellverfolgung)
  void listenToOrder(String orderId) {
    _firestore
        .collection(FirebaseService.ordersCollection)
        .doc(orderId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.metadata.isFromCache == false) {
        final data = doc.data()!;
        data['id'] = doc.id;
        _currentOrder = OrderModel.fromJson(data);

        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = _currentOrder!;
        }
        notifyListeners();
      }
    });
  }
}