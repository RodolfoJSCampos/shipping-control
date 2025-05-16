import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;
  final _collection = 'pedidos';

  Future<void> addOrder(OrderModel order) async {
    await _db.collection(_collection).doc(order.id).set(order.toMap());
  }

  Stream<List<OrderModel>> getOrders() {
    return _db.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data());
      }).toList();
    });
  }
}
