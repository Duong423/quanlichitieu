import 'package:cloud_firestore/cloud_firestore.dart';

class XoaChiTieuController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hàm xóa một khoản chi tiêu dựa trên ID
  Future<void> deleteChiTieu(String chiTieuId) async {
    try {
      await _firestore.collection('chiTieuSapToi').doc(chiTieuId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa chi tiêu: $e');
    }
  }
}