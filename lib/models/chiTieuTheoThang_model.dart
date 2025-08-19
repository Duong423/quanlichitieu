import 'package:cloud_firestore/cloud_firestore.dart';

class ChiTieuTheoThang {
  final int thang;
  final int nam;
  final double chiTieuThucTe;      // Từ bảng 'chi'
  final double nganSachDaDung;     // Từ bảng 'ngan_sach_danh_muc'
  final double chiTieuHoanThanh;   // Từ bảng 'chiTieuSapToi' đã hoàn thành
  final double tongChi;            // Tổng cộng 3 loại trên
  final DateTime ngayCapNhat;

  ChiTieuTheoThang({
    required this.thang,
    required this.nam,
    required this.chiTieuThucTe,
    required this.nganSachDaDung,
    required this.chiTieuHoanThanh,
    required this.ngayCapNhat,
  }) : tongChi = chiTieuThucTe + nganSachDaDung + chiTieuHoanThanh;

  Map<String, dynamic> toMap() {
    return {
      'thang': thang,
      'nam': nam,
      'chiTieuThucTe': chiTieuThucTe,
      'nganSachDaDung': nganSachDaDung,
      'chiTieuHoanThanh': chiTieuHoanThanh,
      'tongChi': tongChi,
      'ngayCapNhat': ngayCapNhat,
    };
  }

  factory ChiTieuTheoThang.fromMap(Map<String, dynamic> map) {
    return ChiTieuTheoThang(
      thang: map['thang'] ?? 0,
      nam: map['nam'] ?? 0,
      chiTieuThucTe: (map['chiTieuThucTe'] ?? 0).toDouble(),
      nganSachDaDung: (map['nganSachDaDung'] ?? 0).toDouble(),
      chiTieuHoanThanh: (map['chiTieuHoanThanh'] ?? 0).toDouble(),
      ngayCapNhat: (map['ngayCapNhat'] as Timestamp).toDate(),
    );
  }
}
