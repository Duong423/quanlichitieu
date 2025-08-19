import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/giao_dich.dart';

class GiaoDichController {
  final CollectionReference _thuCollection =
      FirebaseFirestore.instance.collection('thu');
  final CollectionReference _chiCollection =
      FirebaseFirestore.instance.collection('chi');
  final CollectionReference _soDuCollection =
      FirebaseFirestore.instance.collection('soDu');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Thêm giao dịch mới dựa trên loại giao dịch
  Future<void> addGiaoDich(GiaoDich giaoDich) async {
    try {
      Map<String, dynamic> giaoDichMap = giaoDich.toMap();
      if (giaoDich.loaiGiaoDich == 'Thu nhập') {
        await _thuCollection.add(giaoDichMap);
      } else if (giaoDich.loaiGiaoDich == 'Chi tiêu') {
        await _chiCollection.add(giaoDichMap);
      }
    } catch (e) {
      print('Lỗi khi thêm giao dịch: $e');
      rethrow;
    }
  }

  // Lấy danh sách giao dịch từ collection thu, sắp xếp theo ngày giảm dần, lọc theo tháng năm
  Stream<List<GiaoDich>> getThuGiaoDichs({String? thangNam}) {
    Query query = _thuCollection.orderBy('ngayGiaoDich', descending: true);
    if (thangNam != null) {
      List<String> parts = thangNam.split('-');
      int thang = int.parse(parts[0]);
      int nam = int.parse(parts[1]);
      DateTime start = DateTime(nam, thang, 1);
      DateTime end = DateTime(nam, thang + 1, 1);
      query = query
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('ngayGiaoDich', isLessThan: Timestamp.fromDate(end));
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GiaoDich.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // Lấy danh sách giao dịch từ collection chi, sắp xếp theo ngày giảm dần, lọc theo tháng năm
  Stream<List<GiaoDich>> getChiGiaoDichs({String? thangNam}) {
    Query query = _chiCollection.orderBy('ngayGiaoDich', descending: true);
    if (thangNam != null) {
      List<String> parts = thangNam.split('-');
      int thang = int.parse(parts[0]);
      int nam = int.parse(parts[1]);
      DateTime start = DateTime(nam, thang, 1);
      DateTime end = DateTime(nam, thang + 1, 1);
      query = query
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('ngayGiaoDich', isLessThan: Timestamp.fromDate(end));
    }
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => GiaoDich.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  // Lấy toàn bộ giao dịch từ collection thu, sắp xếp theo ngày giảm dần
  Stream<List<GiaoDich>> getAllThuGiaoDichs() {
    return _thuCollection
        .orderBy('ngayGiaoDich', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GiaoDich.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Lấy toàn bộ giao dịch từ collection chi, sắp xếp theo ngày giảm dần
  Stream<List<GiaoDich>> getAllChiGiaoDichs() {
    return _chiCollection
        .orderBy('ngayGiaoDich', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GiaoDich.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Lấy số dư của tháng trước
  Future<double> getSoDuThangTruoc(String thangNam) async {
    List<String> parts = thangNam.split('-');
    int thang = int.parse(parts[0]);
    int nam = int.parse(parts[1]);
    int thangTruoc = thang == 1 ? 12 : thang - 1;
    int namTruoc = thang == 1 ? nam - 1 : nam;
    String thangNamTruoc = '${thangTruoc.toString().padLeft(2, '0')}-${namTruoc}';

    DocumentSnapshot doc = await _soDuCollection.doc(thangNamTruoc).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['soDu']?.toDouble() ?? 0.0;
    }
    return 0.0; // Nếu chưa có số dư tháng trước, trả về 0
  }

  // Lưu hoặc cập nhật số dư vào collection soDu
  Future<void> capNhatSoDu(String thangNam, double soDu) async {
    await _soDuCollection.doc(thangNam).set({
      'thangNam': thangNam,
      'soDu': soDu,
    }, SetOptions(merge: true));
  }

  // Lấy số dư hiện tại của tháng hiện tại
  Future<double> getSoDuHienTai() async {
    final now = DateTime.now();
    String thangNam = '${now.month.toString().padLeft(2, '0')}-${now.year}';
    
    DocumentSnapshot doc = await _soDuCollection.doc(thangNam).get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['soDu']?.toDouble() ?? 0.0;
    }
    
    // Nếu chưa có số dư tháng này, tính toán từ thu nhập và chi tiêu
    final tongThuNhap = await getTongThuNhapThang(now.month, now.year);
    final tongChiTieu = await getTongChiTieuThang(now.month, now.year);
    final soDuTinhToan = tongThuNhap - tongChiTieu;
    
    // Lưu số dư đã tính toán
    await capNhatSoDu(thangNam, soDuTinhToan);
    return soDuTinhToan;
  }

  Stream<List<GiaoDich>> getCompletedChiGiaoDichs() {
    return _firestore
        .collection('chi')
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GiaoDich.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> updateTransactionCompletion(String id, String collection, bool isCompleted) async {
    await _firestore.collection(collection).doc(id).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> addCompletedTransaction(GiaoDich giaoDich) async {
    await _firestore.collection('chi').add({
      ...giaoDich.toMap(),
      'isCompleted': true,
      'completedAt': FieldValue.serverTimestamp(),
      'originalTransactionId': giaoDich.id,
    });
  }

  // Lấy tổng thu nhập theo danh mục và tháng năm
  Future<double> getTongThuNhapByDanhMuc(String danhMuc, int thang, int nam) async {
    try {
      DateTime start = DateTime(nam, thang, 1);
      DateTime end = DateTime(nam, thang + 1, 1);
      
      QuerySnapshot snapshot = await _thuCollection
          .where('danhMuc', isEqualTo: danhMuc)
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('ngayGiaoDich', isLessThan: Timestamp.fromDate(end))
          .get();
      
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['soTien'] ?? 0.0).toDouble();
      }
      
      return total;
    } catch (e) {
      print('Lỗi khi lấy tổng thu nhập theo danh mục: $e');
      return 0.0;
    }
  }

  // Lấy tổng thu nhập của tháng
  Future<double> getTongThuNhapThang(int thang, int nam) async {
    try {
      DateTime start = DateTime(nam, thang, 1);
      DateTime end = DateTime(nam, thang + 1, 1);
      
      QuerySnapshot snapshot = await _thuCollection
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('ngayGiaoDich', isLessThan: Timestamp.fromDate(end))
          .get();
      
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['soTien'] ?? 0.0).toDouble();
      }
      
      return total;
    } catch (e) {
      print('Lỗi khi lấy tổng thu nhập tháng: $e');
      return 0.0;
    }
  }

  // Lấy tổng chi tiêu của tháng
  Future<double> getTongChiTieuThang(int thang, int nam) async {
    try {
      DateTime start = DateTime(nam, thang, 1);
      DateTime end = DateTime(nam, thang + 1, 1);
      
      QuerySnapshot snapshot = await _chiCollection
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('ngayGiaoDich', isLessThan: Timestamp.fromDate(end))
          .get();
      
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['soTien'] ?? 0.0).toDouble();
      }
      
      return total;
    } catch (e) {
      print('Lỗi khi lấy tổng chi tiêu tháng: $e');
      return 0.0;
    }
  }
}