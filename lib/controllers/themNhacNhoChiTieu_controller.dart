import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chiTieuSapToi_model.dart';

class ThemChiTieuController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addChiTieu(ChiTieuSapToi chiTieu) async {
    try {
      Map<String, dynamic> data = {
        'tenGiaoDich': chiTieu.tenGiaoDich,
        'ngayDenHan': Timestamp.fromDate(chiTieu.ngayDenHan),
        'soTien': chiTieu.soTien,
        'status': chiTieu.status,
        'no': chiTieu.no ?? '',
      };
      
      await _firestore.collection('chiTieuSapToi').add(data);
    } catch (e) {
      throw Exception('Lỗi khi thêm chi tiêu: $e');
    }
  }

   
}