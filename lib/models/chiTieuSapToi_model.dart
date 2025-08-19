import 'package:cloud_firestore/cloud_firestore.dart';

class ChiTieuSapToi {
  final String? id;
  final String tenGiaoDich;
  final DateTime ngayDenHan;
  final double soTien;
  final String status;
  final String? no;

  ChiTieuSapToi({
    this.id,
    required this.tenGiaoDich,
    required this.ngayDenHan,
    required this.soTien,
    required this.status,
    this.no,
  });

  // Convert model to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'tenGiaoDich': tenGiaoDich,
      'ngayDenHan': ngayDenHan,
      'soTien': soTien,
      'status': status,
      'no': no,
    };
  }

  // Create model from Firebase document
  factory ChiTieuSapToi.fromMap(Map<String, dynamic> map, String id) {
    return ChiTieuSapToi(
      id: id,
      tenGiaoDich: map['tenGiaoDich'] ?? '',
      ngayDenHan: (map['ngayDenHan'] as Timestamp).toDate(),
      soTien: (map['soTien'] as num).toDouble(),
      status: map['status'] ?? 'Sắp tới hạn',
      no: map['no'],
    );
  }
}