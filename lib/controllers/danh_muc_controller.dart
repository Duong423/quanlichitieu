import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ngan_sach_danh_muc.dart';
import 'danh_muc_co_ban_controller.dart';
import 'giao_dich_controller.dart';

class DanhMucController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collection = 'ngan_sach_danh_muc';
  final DanhMucCoBanController _danhMucCoBanController = DanhMucCoBanController();
  final GiaoDichController _giaoDichController = GiaoDichController();

  // Add new budget for category
  Future<void> addNganSach(NganSachDanhMuc nganSach) async {
    try {
      await _firestore.collection(collection).add(nganSach.toMap());
    } catch (e) {
      throw Exception('Failed to add budget: $e');
    }
  }

  // Get budgets by month and year
  Stream<List<NganSachDanhMuc>> getNganSachsByMonth(int thang, int nam) {
    return _firestore
        .collection(collection)
        .where('thang', isEqualTo: thang)
        .where('nam', isEqualTo: nam)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NganSachDanhMuc.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update budget usage
  Future<void> updateDaSuDung(String id, double soTienMoi) async {
    try {
      await _firestore.collection(collection).doc(id).update({
        'daSuDung': soTienMoi,
        'ngayCapNhat': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update budget usage: $e');
    }
  }

  // Get specific budget by category ID and month/year
  Future<NganSachDanhMuc?> getNganSachByDanhMucId(String danhMucId, int thang, int nam) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where('danhMucId', isEqualTo: danhMucId)
          .where('thang', isEqualTo: thang)
          .where('nam', isEqualTo: nam)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return NganSachDanhMuc.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  // Get budget by category name and month/year (for backward compatibility)
  Future<NganSachDanhMuc?> getNganSachByTenDanhMuc(String tenDanhMuc, int thang, int nam) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where('tenDanhMuc', isEqualTo: tenDanhMuc)
          .where('thang', isEqualTo: thang)
          .where('nam', isEqualTo: nam)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return NganSachDanhMuc.fromMap(snapshot.docs.first.data() as Map<String, dynamic>, snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get budget: $e');
    }
  }

  // Delete budget
  Future<void> deleteNganSach(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  // Update budget amount
  Future<void> updateNganSach(String id, double nganSachMoi) async {
    try {
      await _firestore.collection(collection).doc(id).update({
        'nganSach': nganSachMoi,
        'ngayCapNhat': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  // Create budget with category ID and validation
  Future<void> createNganSachWithDanhMucId(String danhMucId, String tenDanhMuc, double nganSach, int thang, int nam) async {
    try {
      // Kiểm tra số dư hiện tại
      final soDuHienTai = await _giaoDichController.getSoDuHienTai();
      
      if (soDuHienTai < nganSach) {
        throw Exception(
          'Không thể đặt ngân sách ${_formatCurrency(nganSach)} cho danh mục "$tenDanhMuc".\n'
          'Số dư hiện tại chỉ có ${_formatCurrency(soDuHienTai)}.\n'
          'Vui lòng giảm ngân sách hoặc tăng thu nhập trước.'
        );
      }
      
      // Kiểm tra xem đã có ngân sách cho danh mục này trong tháng chưa
      final existingBudget = await getNganSachByDanhMucId(danhMucId, thang, nam);
      if (existingBudget != null) {
        throw Exception('Danh mục "$tenDanhMuc" đã có ngân sách cho tháng $thang/$nam');
      }
      
      final nganSachDanhMuc = NganSachDanhMuc(
        danhMucId: danhMucId,
        tenDanhMuc: tenDanhMuc,
        nganSach: nganSach,
        thang: thang,
        nam: nam,
        ngayTao: DateTime.now(),
        ngayCapNhat: DateTime.now(),
      );
      
      await addNganSach(nganSachDanhMuc);
    } catch (e) {
      rethrow;
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} đ';
  }

  // Update budget usage by category name (for transaction integration)
  Future<void> updateDaSuDungByDanhMuc(String tenDanhMuc, double soTien, int thang, int nam) async {
    try {
      // First get the category to get its ID
      final danhMuc = await _danhMucCoBanController.getDanhMucByName(tenDanhMuc);
      if (danhMuc == null) return;

      // Find budget for this category and month
      final nganSach = await getNganSachByDanhMucId(danhMuc.id!, thang, nam);
      if (nganSach != null) {
        final newUsage = nganSach.daSuDung + soTien;
        await updateDaSuDung(nganSach.id!, newUsage);
      }
    } catch (e) {
      throw Exception('Failed to update budget usage: $e');
    }
  }

  // Kiểm tra cảnh báo ngân sách còn lại dưới 10%
  Future<List<Map<String, dynamic>>> checkBudgetWarnings() async {
    try {
      final now = DateTime.now();
      final warnings = <Map<String, dynamic>>[];
      
      // Lấy tất cả ngân sách của tháng hiện tại
      QuerySnapshot snapshot = await _firestore
          .collection(collection)
          .where('thang', isEqualTo: now.month)
          .where('nam', isEqualTo: now.year)
          .get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final nganSach = data['nganSach']?.toDouble() ?? 0.0;
        final daSuDung = data['daSuDung']?.toDouble() ?? 0.0;
        final tenDanhMuc = data['tenDanhMuc'] ?? '';
        
        if (nganSach > 0) {
          final conLai = nganSach - daSuDung;
          final phanTramConLai = (conLai / nganSach) * 100;
          
          // Cảnh báo khi còn lại dưới 10%
          if (phanTramConLai <= 10 && phanTramConLai >= 0) {
            warnings.add({
              'tenDanhMuc': tenDanhMuc,
              'nganSach': nganSach,
              'daSuDung': daSuDung,
              'conLai': conLai,
              'phanTramConLai': phanTramConLai,
              'loaiCanhBao': phanTramConLai <= 0 ? 'vuot_ngan_sach' : 'gan_het_ngan_sach'
            });
          }
        }
      }
      
      return warnings;
    } catch (e) {
      print('Lỗi khi kiểm tra cảnh báo ngân sách: $e');
      return [];
    }
  }

  // Lấy thông tin chi tiết ngân sách một danh mục
  Future<Map<String, dynamic>?> getBudgetStatus(String tenDanhMuc) async {
    try {
      final now = DateTime.now();
      final danhMuc = await _danhMucCoBanController.getDanhMucByName(tenDanhMuc);
      if (danhMuc == null) return null;

      final nganSach = await getNganSachByDanhMucId(danhMuc.id!, now.month, now.year);
      if (nganSach == null) return null;

      final conLai = nganSach.nganSach - nganSach.daSuDung;
      final phanTramConLai = (conLai / nganSach.nganSach) * 100;
      final phanTramDaSuDung = (nganSach.daSuDung / nganSach.nganSach) * 100;

      return {
        'tenDanhMuc': nganSach.tenDanhMuc,
        'nganSach': nganSach.nganSach,
        'daSuDung': nganSach.daSuDung,
        'conLai': conLai,
        'phanTramConLai': phanTramConLai,
        'phanTramDaSuDung': phanTramDaSuDung,
        'trangThai': _getBudgetStatusText(phanTramConLai),
        'mauSac': _getBudgetStatusColor(phanTramConLai)
      };
    } catch (e) {
      print('Lỗi khi lấy trạng thái ngân sách: $e');
      return null;
    }
  }

  String _getBudgetStatusText(double phanTramConLai) {
    if (phanTramConLai <= 0) return 'Đã vượt ngân sách';
    if (phanTramConLai <= 10) return 'Gần hết ngân sách';
    if (phanTramConLai <= 30) return 'Cần chú ý';
    return 'Bình thường';
  }

  String _getBudgetStatusColor(double phanTramConLai) {
    if (phanTramConLai <= 0) return 'red';
    if (phanTramConLai <= 10) return 'orange';
    if (phanTramConLai <= 30) return 'yellow';
    return 'green';
  }
}
