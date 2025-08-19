import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/giao_dich.dart';

class XoaGiaoDichController {
  final CollectionReference _thuCollection = FirebaseFirestore.instance.collection('thu');
  final CollectionReference _chiCollection = FirebaseFirestore.instance.collection('chi');

  // Xóa giao dịch dựa trên ID và loại giao dịch
  Future<void> deleteGiaoDich(String id, String loaiGiaoDich) async {
    try {
      if (loaiGiaoDich == 'Thu nhập') {
        await _thuCollection.doc(id).delete();
      } else if (loaiGiaoDich == 'Chi tiêu') {
        await _chiCollection.doc(id).delete();
      }
    } catch (e) {
      print('Lỗi khi xóa giao dịch: $e');
      rethrow;
    }
  }
}