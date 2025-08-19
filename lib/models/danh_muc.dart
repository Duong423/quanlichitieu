class DanhMuc {
  String? id;
  String tenDanhMuc;
  String icon;
  double nganSach;
  double daSuDung;
  int thang;
  int nam;
  DateTime ngayTao;

  DanhMuc({
    this.id,
    required this.tenDanhMuc,
    required this.icon,
    required this.nganSach,
    this.daSuDung = 0,
    required this.thang,
    required this.nam,
    required this.ngayTao,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenDanhMuc': tenDanhMuc,
      'icon': icon,
      'nganSach': nganSach,
      'daSuDung': daSuDung,
      'thang': thang,
      'nam': nam,
      'ngayTao': ngayTao.toIso8601String(),
    };
  }

  static DanhMuc fromMap(Map<String, dynamic> map, String id) {
    return DanhMuc(
      id: id,
      tenDanhMuc: map['tenDanhMuc'] ?? '',
      icon: map['icon'] ?? '',
      nganSach: (map['nganSach'] ?? 0).toDouble(),
      daSuDung: (map['daSuDung'] ?? 0).toDouble(),
      thang: map['thang'] ?? 0,
      nam: map['nam'] ?? 0,
      ngayTao: DateTime.parse(map['ngayTao']),
    );
  }
}
