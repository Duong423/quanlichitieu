import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chiTieuSapToi_model.dart';

class CapNhatChiTieuController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateChiTieuStatus(String id, String status) async {
    try {
      // Lấy thông tin chi tiêu từ collection chiTieuSapToi
      DocumentSnapshot chiTieuDoc = await _firestore.collection('chiTieuSapToi').doc(id).get();
      Map<String, dynamic> chiTieuData = chiTieuDoc.data() as Map<String, dynamic>;

      // Cập nhật trạng thái trong collection chiTieuSapToi
      await _firestore.collection('chiTieuSapToi').doc(id).update({
        'status': status,
        'ngayHoanThanh': status == 'Đã hoàn thành' ? DateTime.now() : null, // Thêm ngày hoàn thành
      });

      // Nếu trạng thái là 'Đã hoàn thành', thêm vào collection chi hoặc thu tùy theo loại nợ
      if (status == 'Đã hoàn thành') {
        String collection = chiTieuData['no'] == 'Tôi' ? 'chi' : 'thu';
        String loaiGiaoDich = chiTieuData['no'] == 'Tôi' ? 'Chi tiêu' : 'Thu nhập';
        
        await _firestore.collection(collection).add({
          'tenGiaoDich': chiTieuData['tenGiaoDich'],
          'soTien': chiTieuData['soTien'],
          'danhMuc': 'Chi tiêu đã hoàn thành',
          'ngayGiaoDich': DateTime.now(),
          'loaiGiaoDich': loaiGiaoDich,
          'ghiChu': 'Từ nhắc nhở chi tiêu: ${chiTieuData['tenGiaoDich']}',
          'isCompleted': true,
          'originalChiTieuId': id,
        });

        // Đợi 2 giây rồi xóa khoản nhắc nhở chi tiêu đã hoàn thành
        // Future.delayed(Duration(seconds: 2), () async {
        //   await _firestore.collection('chiTieuSapToi').doc(id).delete();
        // });
        

        // Cập nhật số dư trong collection soDu
        DocumentReference soDuRef = _firestore.collection('soDu').doc('current');
        await _firestore.runTransaction((transaction) async {
          DocumentSnapshot soDuDoc = await transaction.get(soDuRef);
          if (soDuDoc.exists) {
            double currentBalance = (soDuDoc.data() as Map<String, dynamic>)['soDu'] ?? 0.0;
            transaction.update(soDuRef, {
              'soDu': currentBalance - chiTieuData['soTien'],
            });
          }
        });
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật trạng thái: $e');
    }
  }
}