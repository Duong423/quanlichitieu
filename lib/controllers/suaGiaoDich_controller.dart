import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/giao_dich.dart';

class SuaGiaoDichController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateGiaoDich(GiaoDich giaoDich, String loaiGiaoDich) async {
    try {
      CollectionReference collection = loaiGiaoDich == 'Thu nhập'
          ? _firestore.collection('thu')
          : _firestore.collection('chi');

      await collection.doc(giaoDich.id).update({
        'tenGiaoDich': giaoDich.tenGiaoDich,
        'soTien': giaoDich.soTien,
        'danhMuc': giaoDich.danhMuc,
        'ngayGiaoDich': Timestamp.fromDate(giaoDich.ngayGiaoDich),
        'ghiChu': giaoDich.ghiChu,
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật giao dịch: $e');
    }
  }
}