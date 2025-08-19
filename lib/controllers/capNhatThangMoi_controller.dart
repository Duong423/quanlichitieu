import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CapNhatThangMoiController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kiểm tra và cập nhật khi sang tháng mới
  Future<void> checkAndUpdateNewMonth() async {
    DateTime now = DateTime.now();
    String currentMonthYear = DateFormat('MM-yyyy').format(now);
    
    // Lấy tháng trước
    DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
    String lastMonthYear = DateFormat('MM-yyyy').format(lastMonth);

    // Kiểm tra xem đã cập nhật cho tháng này chưa
    DocumentSnapshot currentMonthDoc = await _firestore
        .collection('monthlyStatus')
        .doc(currentMonthYear)
        .get();

    if (!currentMonthDoc.exists) {
      // Nếu chưa cập nhật cho tháng này
      await _updateNewMonth(lastMonthYear, currentMonthYear);
    }
  }

  Future<void> _updateNewMonth(String lastMonthYear, String currentMonthYear) async {
    try {
      // Lấy số dư tháng trước
      DocumentSnapshot lastMonthBalance = await _firestore
          .collection('soDu')
          .doc(lastMonthYear)
          .get();

      double lastMonthBalanceAmount = 0.0;
      if (lastMonthBalance.exists) {
        lastMonthBalanceAmount = (lastMonthBalance.data() as Map<String, dynamic>)['soDu'] ?? 0.0;
      }

      // Xóa dữ liệu thu/chi của tháng trước
      await _deleteLastMonthData(lastMonthYear);

      // Cập nhật số dư tháng mới
      await _firestore.collection('soDu').doc(currentMonthYear).set({
        'thangNam': currentMonthYear,
        'soDu': lastMonthBalanceAmount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Đánh dấu đã cập nhật cho tháng này
      await _firestore.collection('monthlyStatus').doc(currentMonthYear).set({
        'updated': true,
        'lastMonth': lastMonthYear,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi khi cập nhật tháng mới: $e');
      rethrow;
    }
  }

  Future<void> _deleteLastMonthData(String lastMonthYear) async {
    try {
      // Lấy ngày đầu và cuối của tháng trước
      List<String> parts = lastMonthYear.split('-');
      int month = int.parse(parts[0]);
      int year = int.parse(parts[1]);
      DateTime startDate = DateTime(year, month, 1);
      DateTime endDate = DateTime(year, month + 1, 1);

      // Xóa dữ liệu thu của tháng trước
      QuerySnapshot thuSnapshot = await _firestore
          .collection('thu')
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: startDate)
          .where('ngayGiaoDich', isLessThan: endDate)
          .get();

      for (var doc in thuSnapshot.docs) {
        await doc.reference.delete();
      }

      // Xóa dữ liệu chi của tháng trước
      QuerySnapshot chiSnapshot = await _firestore
          .collection('chi')
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: startDate)
          .where('ngayGiaoDich', isLessThan: endDate)
          .get();

      for (var doc in chiSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Lỗi khi xóa dữ liệu tháng cũ: $e');
      rethrow;
    }
  }

  // Cập nhật số dư hiện tại
  Future<void> updateCurrentBalance(double amount) async {
    try {
      String currentMonthYear = DateFormat('MM-yyyy').format(DateTime.now());
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot soDuDoc = await transaction.get(
          _firestore.collection('soDu').doc(currentMonthYear)
        );

        if (soDuDoc.exists) {
          double currentBalance = (soDuDoc.data() as Map<String, dynamic>)['soDu'] ?? 0.0;
          transaction.update(
            _firestore.collection('soDu').doc(currentMonthYear),
            {'soDu': currentBalance + amount}
          );
        } else {
          transaction.set(
            _firestore.collection('soDu').doc(currentMonthYear),
            {
              'thangNam': currentMonthYear,
              'soDu': amount,
              'lastUpdated': FieldValue.serverTimestamp(),
            }
          );
        }
      });
    } catch (e) {
      print('Lỗi khi cập nhật số dư: $e');
      rethrow;
    }
  }
} 