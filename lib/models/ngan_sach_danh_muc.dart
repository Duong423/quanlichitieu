class NganSachDanhMuc {
  String? id;
  String danhMucId; // ID tham chiếu đến collection danh_muc
  String tenDanhMuc; // Lưu tên để dễ query
  double nganSach;
  double daSuDung;
  int thang;
  int nam;
  DateTime ngayTao;
  DateTime ngayCapNhat;

  NganSachDanhMuc({
    this.id,
    required this.danhMucId,
    required this.tenDanhMuc,
    required this.nganSach,
    this.daSuDung = 0,
    required this.thang,
    required this.nam,
    required this.ngayTao,
    required this.ngayCapNhat,
  });

  Map<String, dynamic> toMap() {
    return {
      'danhMucId': danhMucId,
      'tenDanhMuc': tenDanhMuc,
      'nganSach': nganSach,
      'daSuDung': daSuDung,
      'thang': thang,
      'nam': nam,
      'ngayTao': ngayTao.toIso8601String(),
      'ngayCapNhat': ngayCapNhat.toIso8601String(),
    };
  }

  static NganSachDanhMuc fromMap(Map<String, dynamic> map, String id) {
    return NganSachDanhMuc(
      id: id,
      danhMucId: map['danhMucId'] ?? '',
      tenDanhMuc: map['tenDanhMuc'] ?? '',
      nganSach: (map['nganSach'] ?? 0).toDouble(),
      daSuDung: (map['daSuDung'] ?? 0).toDouble(),
      thang: map['thang'] ?? 0,
      nam: map['nam'] ?? 0,
      ngayTao: DateTime.parse(map['ngayTao']),
      ngayCapNhat: DateTime.parse(map['ngayCapNhat']),
    );
  }
}
