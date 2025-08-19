import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chiTieuTheoThang_model.dart';

class TongHopChiTieuController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tính tổng chi tiêu từ bảng 'chi' theo tháng
  Future<double> _getChiTieuThucTe(int thang, int nam) async {
    try {
      DateTime startDate = DateTime(nam, thang, 1);
      DateTime endDate = DateTime(nam, thang + 1, 1).subtract(Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('chi')
          .where('ngayGiaoDich', isGreaterThanOrEqualTo: startDate)
          .where('ngayGiaoDich', isLessThanOrEqualTo: endDate)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['soTien'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Lỗi khi tính chi tiêu thực tế: $e');
      return 0;
    }
  }

  // Tính tổng ngân sách đã sử dụng theo tháng
  Future<double> _getNganSachDaDung(int thang, int nam) async {
    try {
      DateTime startDate = DateTime(nam, thang, 1);
      DateTime endDate = DateTime(nam, thang + 1, 1).subtract(Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('ngan_sach_danh_muc')
          .where('ngayTao', isGreaterThanOrEqualTo: startDate)
          .where('ngayTao', isLessThanOrEqualTo: endDate)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += (data['soTienDaDung'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Lỗi khi tính ngân sách đã dùng: $e');
      return 0;
    }
  }

  // Tính tổng chi tiêu từ nhắc nhở đã hoàn thành theo tháng
  Future<double> _getChiTieuHoanThanh(int thang, int nam) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('chiTieuSapToi')
          .where('status', isEqualTo: 'Đã hoàn thành')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Kiểm tra ngày hoàn thành (có thể lưu trong field riêng hoặc dùng ngày cập nhật cuối)
        DateTime ngayHoanThanh;
        if (data.containsKey('ngayHoanThanh')) {
          ngayHoanThanh = (data['ngayHoanThanh'] as Timestamp).toDate();
        } else {
          // Nếu không có ngày hoàn thành riêng, dùng ngày đến hạn làm ước tính
          ngayHoanThanh = (data['ngayDenHan'] as Timestamp).toDate();
        }

        if (ngayHoanThanh.month == thang && ngayHoanThanh.year == nam) {
          total += (data['soTien'] ?? 0).toDouble();
        }
      }

      return total;
    } catch (e) {
      print('Lỗi khi tính chi tiêu hoàn thành: $e');
      return 0;
    }
  }

  // Tổng hợp chi tiêu cho một tháng cụ thể
  Future<ChiTieuTheoThang> tongHopChiTieuThang(int thang, int nam) async {
    try {
      double chiTieuThucTe = await _getChiTieuThucTe(thang, nam);
      double nganSachDaDung = await _getNganSachDaDung(thang, nam);
      double chiTieuHoanThanh = await _getChiTieuHoanThanh(thang, nam);

      return ChiTieuTheoThang(
        thang: thang,
        nam: nam,
        chiTieuThucTe: chiTieuThucTe,
        nganSachDaDung: nganSachDaDung,
        chiTieuHoanThanh: chiTieuHoanThanh,
        ngayCapNhat: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Lỗi khi tổng hợp chi tiêu tháng $thang/$nam: $e');
    }
  }

  // Lưu kết quả tổng hợp vào Firestore
  Future<void> luuTongHopThang(ChiTieuTheoThang tongHop) async {
    try {
      String docId = '${tongHop.nam}_${tongHop.thang.toString().padLeft(2, '0')}';
      
      await _firestore
          .collection('tong_hop_chi_tieu')
          .doc(docId)
          .set(tongHop.toMap());
          
      print('Đã lưu tổng hợp tháng ${tongHop.thang}/${tongHop.nam}');
    } catch (e) {
      throw Exception('Lỗi khi lưu tổng hợp: $e');
    }
  }

  // So sánh chi tiêu giữa các tháng
  Future<List<ChiTieuTheoThang>> soSanhChiTieuTheoThang(int soThangCanSo) async {
    try {
      DateTime now = DateTime.now();
      List<ChiTieuTheoThang> danhSachThang = [];

      for (int i = soThangCanSo - 1; i >= 0; i--) {
        DateTime thangCanTinh = DateTime(now.year, now.month - i, 1);
        ChiTieuTheoThang tongHop = await tongHopChiTieuThang(
          thangCanTinh.month,
          thangCanTinh.year,
        );
        danhSachThang.add(tongHop);
        
        // Lưu kết quả vào Firestore để tra cứu sau
        await luuTongHopThang(tongHop);
      }

      return danhSachThang;
    } catch (e) {
      throw Exception('Lỗi khi so sánh chi tiêu theo tháng: $e');
    }
  }

  // Lấy lịch sử tổng hợp đã lưu
  Future<List<ChiTieuTheoThang>> getLichSuTongHop() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('tong_hop_chi_tieu')
          .limit(10) // Giới hạn số lượng để tránh lỗi
          .get();

      List<ChiTieuTheoThang> result = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          result.add(ChiTieuTheoThang.fromMap(data));
        } catch (e) {
          print('Lỗi khi parse document ${doc.id}: $e');
          continue;
        }
      }

      // Sắp xếp theo năm và tháng giảm dần trên client
      result.sort((a, b) {
        if (a.nam != b.nam) {
          return b.nam.compareTo(a.nam); // Năm giảm dần
        }
        return b.thang.compareTo(a.thang); // Tháng giảm dần
      });

      return result;
    } catch (e) {
      print('Lỗi khi lấy lịch sử tổng hợp: $e');
      return [];
    }
  }

  // Tính phần trăm thay đổi so với tháng trước
  double tinhPhanTramThayDoi(double thangHienTai, double thangTruoc) {
    if (thangTruoc == 0) return 0;
    return ((thangHienTai - thangTruoc) / thangTruoc) * 100;
  }

  // Kiểm tra và tạo dữ liệu mẫu nếu chưa có
  Future<void> taoDataMauNeuCan() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('tong_hop_chi_tieu')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('Tạo dữ liệu mẫu cho tổng hợp chi tiêu...');
        
        // Tạo dữ liệu mẫu cho 3 tháng gần đây
        DateTime now = DateTime.now();
        for (int i = 2; i >= 0; i--) {
          DateTime thangCanTao = DateTime(now.year, now.month - i, 1);
          
          ChiTieuTheoThang mauData = ChiTieuTheoThang(
            thang: thangCanTao.month,
            nam: thangCanTao.year,
            chiTieuThucTe: (i + 1) * 500000, // Dữ liệu mẫu
            nganSachDaDung: (i + 1) * 300000,
            chiTieuHoanThanh: (i + 1) * 200000,
            ngayCapNhat: DateTime.now(),
          );
          
          await luuTongHopThang(mauData);
        }
        
        print('Đã tạo xong dữ liệu mẫu');
      }
    } catch (e) {
      print('Lỗi khi tạo dữ liệu mẫu: $e');
    }
  }

  // Phân tích xu hướng chi tiêu
  Future<Map<String, dynamic>> phanTichXuHuong() async {
    try {
      List<ChiTieuTheoThang> lichSu = await getLichSuTongHop();
      
      if (lichSu.length < 2) {
        return {
          'message': 'Cần ít nhất 2 tháng dữ liệu để phân tích xu hướng',
          'trend': 'insufficient_data',
          'xuHuong': 'insufficient_data',
          'thongDiep': 'Chưa đủ dữ liệu để phân tích',
          'phanTramThayDoi': 0.0,
          'tongChiThangNay': 0.0,
          'tongChiThangTruoc': 0.0,
          'lichSuChiTiet': lichSu,
        };
      }

      double tongChiThangNay = lichSu.first.tongChi;
      double tongChiThangTruoc = lichSu[1].tongChi;
      double phanTramThayDoi = tinhPhanTramThayDoi(tongChiThangNay, tongChiThangTruoc);

      String xuHuong;
      String thongDiep;
      
      if (phanTramThayDoi > 10) {
        xuHuong = 'tang_manh';
        thongDiep = 'Chi tiêu tăng mạnh ${phanTramThayDoi.toStringAsFixed(1)}% so với tháng trước';
      } else if (phanTramThayDoi > 0) {
        xuHuong = 'tang_nhe';
        thongDiep = 'Chi tiêu tăng nhẹ ${phanTramThayDoi.toStringAsFixed(1)}% so với tháng trước';
      } else if (phanTramThayDoi < -10) {
        xuHuong = 'giam_manh';
        thongDiep = 'Chi tiêu giảm mạnh ${(-phanTramThayDoi).toStringAsFixed(1)}% so với tháng trước';
      } else if (phanTramThayDoi < 0) {
        xuHuong = 'giam_nhe';
        thongDiep = 'Chi tiêu giảm nhẹ ${(-phanTramThayDoi).toStringAsFixed(1)}% so với tháng trước';
      } else {
        xuHuong = 'on_dinh';
        thongDiep = 'Chi tiêu ổn định so với tháng trước';
      }

      return {
        'xuHuong': xuHuong,
        'thongDiep': thongDiep,
        'phanTramThayDoi': phanTramThayDoi,
        'tongChiThangNay': tongChiThangNay,
        'tongChiThangTruoc': tongChiThangTruoc,
        'lichSuChiTiet': lichSu.take(6).toList(), // 6 tháng gần nhất
      };
    } catch (e) {
      print('Lỗi khi phân tích xu hướng: $e');
      return {
        'message': 'Có lỗi xảy ra khi phân tích xu hướng',
        'xuHuong': 'error',
        'thongDiep': 'Không thể phân tích xu hướng lúc này',
        'phanTramThayDoi': 0.0,
        'tongChiThangNay': 0.0,
        'tongChiThangTruoc': 0.0,
        'lichSuChiTiet': <ChiTieuTheoThang>[],
      };
    }
  }
}
