import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/danh_muc_co_ban.dart';

class DanhMucCoBanController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'danh_muc';

  // Add new category (for manual setup)
  Future<void> addDanhMuc(DanhMucCoBan danhMuc) async {
    try {
      await _firestore.collection(collection).add(danhMuc.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Get all categories
  Stream<List<DanhMucCoBan>> getAllDanhMucs() {
    return _firestore
        .collection(collection)
        .orderBy('tenDanhMuc')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DanhMucCoBan.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get category by ID
  Future<DanhMucCoBan?> getDanhMucById(String id) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection(collection).doc(id).get();
      if (snapshot.exists) {
        return DanhMucCoBan.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Get category by name
  Future<DanhMucCoBan?> getDanhMucByName(String tenDanhMuc) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where('tenDanhMuc', isEqualTo: tenDanhMuc)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return DanhMucCoBan.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  // Update category
  Future<void> updateDanhMuc(String id, DanhMucCoBan danhMuc) async {
    try {
      await _firestore.collection(collection).doc(id).update(danhMuc.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  Future<void> deleteDanhMuc(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Initialize default categories (run once)
  Future<void> initializeDefaultCategories() async {
    try {
      final defaultCategories = [
        DanhMucCoBan(tenDanhMuc: 'Ăn uống', icon: 'fastfood', moTa: 'Chi phí ăn uống, nhà hàng', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Mua sắm', icon: 'shopping_bag', moTa: 'Mua sắm quần áo, đồ dùng', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Di chuyển', icon: 'directions_car', moTa: 'Xăng xe, taxi, xe bus', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Nhà cửa', icon: 'home', moTa: 'Tiền nhà, điện nước, sửa chữa', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Giải trí', icon: 'movie', moTa: 'Xem phim, du lịch, game', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Sức khỏe', icon: 'favorite', moTa: 'Khám bệnh, thuốc men', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Giáo dục', icon: 'school', moTa: 'Học phí, sách vở', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Hóa đơn', icon: 'receipt', moTa: 'Hóa đơn điện, nước, internet', ngayTao: DateTime.now()),
        DanhMucCoBan(tenDanhMuc: 'Khác', icon: 'more_horiz', moTa: 'Chi phí khác', ngayTao: DateTime.now()),
      ];

      for (var category in defaultCategories) {
        // Check if category already exists
        final existing = await getDanhMucByName(category.tenDanhMuc);
        if (existing == null) {
          await addDanhMuc(category);
        }
      }
    } catch (e) {
      throw Exception('Failed to initialize categories: $e');
    }
  }
}
