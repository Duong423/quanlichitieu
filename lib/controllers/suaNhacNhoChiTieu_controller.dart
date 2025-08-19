import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chiTieuSapToi_model.dart';

class SuaNhacNhoChiTieuController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateChiTieu(String id, ChiTieuSapToi chiTieu) async {
    try {
      await _firestore.collection('chiTieuSapToi').doc(id).update({
        'tenGiaoDich': chiTieu.tenGiaoDich,
        'ngayDenHan': Timestamp.fromDate(chiTieu.ngayDenHan),
        'soTien': chiTieu.soTien,
        'status': chiTieu.status,
        'no': chiTieu.no,
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật chi tiêu: $e');
    }
  }
} 