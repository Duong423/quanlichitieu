import 'package:cloud_firestore/cloud_firestore.dart';

class GiaoDich {
  final String? id;
  final String tenGiaoDich;
  final double soTien;
  final String danhMuc;
  final DateTime ngayGiaoDich;
  final String? ghiChu;
  final String loaiGiaoDich;
  final bool isCompleted;

  GiaoDich({
    this.id,
    required this.tenGiaoDich,
    required this.soTien,
    required this.danhMuc,
    required this.ngayGiaoDich,
    this.ghiChu,
    required this.loaiGiaoDich,
    this.isCompleted = false,
  });

  // Chuyển đổi từ Map (dữ liệu từ Firestore) sang GiaoDich
  factory GiaoDich.fromMap(String id, Map<String, dynamic> map) {
    return GiaoDich(
      id: id,
      tenGiaoDich: map['tenGiaoDich'] ?? '',
      soTien: (map['soTien'] ?? 0).toDouble(),
      danhMuc: map['danhMuc'] ?? '',
      ngayGiaoDich: (map['ngayGiaoDich'] as Timestamp).toDate(),
      ghiChu: map['ghiChu'],
      loaiGiaoDich: map['loaiGiaoDich'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // Chuyển đổi GiaoDich sang Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'tenGiaoDich': tenGiaoDich,
      'soTien': soTien,
      'danhMuc': danhMuc,
      'ngayGiaoDich': ngayGiaoDich,
      'ghiChu': ghiChu,
      'loaiGiaoDich': loaiGiaoDich,
      'isCompleted': isCompleted,
    };
  }
}