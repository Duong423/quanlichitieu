class DanhMucCoBan {
  String? id;
  String tenDanhMuc;
  String icon;
  String moTa;
  DateTime ngayTao;

  DanhMucCoBan({
    this.id,
    required this.tenDanhMuc,
    required this.icon,
    this.moTa = '',
    required this.ngayTao,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenDanhMuc': tenDanhMuc,
      'icon': icon,
      'moTa': moTa,
      'ngayTao': ngayTao.toIso8601String(),
    };
  }

  static DanhMucCoBan fromMap(Map<String, dynamic> map, String id) {
    return DanhMucCoBan(
      id: id,
      tenDanhMuc: map['tenDanhMuc'] ?? '',
      icon: map['icon'] ?? '',
      moTa: map['moTa'] ?? '',
      ngayTao: DateTime.parse(map['ngayTao']),
    );
  }
}
