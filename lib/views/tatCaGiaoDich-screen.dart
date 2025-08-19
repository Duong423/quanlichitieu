import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import '../../controllers/giao_dich_controller.dart';
import '../../controllers/xoaGiaoDich_controller.dart';
import '../../controllers/suaGiaoDich_controller.dart';
import '../../models/giao_dich.dart';
import 'themGiaoDich-screen.dart';
import 'trangChu-screen.dart';
import 'main_screen.dart';

class TatCaGiaoDichScreen extends StatefulWidget {
  const TatCaGiaoDichScreen({Key? key}) : super(key: key);

  @override
  _TatCaGiaoDichScreenState createState() => _TatCaGiaoDichScreenState();
}

class _TatCaGiaoDichScreenState extends State<TatCaGiaoDichScreen> {
  String _loaiGiaoDich = 'Tất cả';
  final GiaoDichController _giaoDichController = GiaoDichController();
  final XoaGiaoDichController _xoaGiaoDichController = XoaGiaoDichController();
  final SuaGiaoDichController _suaGiaoDichController = SuaGiaoDichController();
  DateTime? _startDate;
  DateTime? _endDate;

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<GiaoDich> _filterByDateRange(List<GiaoDich> list) {
    if (_startDate == null || _endDate == null) return list;
    return list.where((gd) {
      final gdDate = gd.ngayGiaoDich;
      final isInRange = (gdDate.isAtSameMomentAs(_startDate!) ||
              gdDate.isAfter(_startDate!)) &&
          gdDate.isBefore(_endDate!.add(const Duration(days: 1)));
      print(
          'Checking $gdDate (Start: $_startDate, End: $_endDate): $isInRange');
      return isInRange;
    }).toList();
  }

  double _calculateTotalAmount(List<GiaoDich> giaoDichs) {
    return giaoDichs.fold(0, (sum, gd) => sum + gd.soTien);
  }

  Future<void> _showEditDialog(BuildContext context, GiaoDich giaoDich) async {
    final _formKey = GlobalKey<FormState>();
    String tenGiaoDich = giaoDich.tenGiaoDich;
    double soTien = giaoDich.soTien;
    String danhMuc = giaoDich.danhMuc;
    DateTime ngayGiaoDich = giaoDich.ngayGiaoDich;
    String ghiChu = giaoDich.ghiChu ?? '';
    TextEditingController dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(ngayGiaoDich),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa giao dịch'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: tenGiaoDich,
                    decoration: const InputDecoration(labelText: 'Tên giao dịch'),
                    validator: (value) =>
                        value!.isEmpty ? 'Vui lòng nhập tên giao dịch' : null,
                    onChanged: (value) => tenGiaoDich = value,
                  ),
                  TextFormField(
                    initialValue: soTien.toString(),
                    decoration: const InputDecoration(labelText: 'Số tiền (đ)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Vui lòng nhập số tiền';
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0)
                        return 'Số tiền phải là số dương';
                      return null;
                    },
                    onChanged: (value) =>
                        soTien = double.tryParse(value) ?? soTien,
                  ),
                  TextFormField(
                    initialValue: danhMuc,
                    decoration: const InputDecoration(labelText: 'Danh mục'),
                    validator: (value) =>
                        value!.isEmpty ? 'Vui lòng nhập danh mục' : null,
                    onChanged: (value) => danhMuc = value,
                  ),
                  TextFormField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Ngày giao dịch'),
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: ngayGiaoDich,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        ngayGiaoDich = picked;
                        dateController.text =
                            DateFormat('dd/MM/yyyy').format(picked);
                      }
                    },
                    validator: (value) =>
                        value!.isEmpty ? 'Vui lòng chọn ngày' : null,
                  ),
                  TextFormField(
                    initialValue: ghiChu,
                    decoration:
                        const InputDecoration(labelText: 'Ghi chú (tùy chọn)'),
                    onChanged: (value) => ghiChu = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    GiaoDich updatedGiaoDich = GiaoDich(
                      id: giaoDich.id,
                      tenGiaoDich: tenGiaoDich,
                      soTien: soTien,
                      danhMuc: danhMuc,
                      ngayGiaoDich: ngayGiaoDich,
                      ghiChu: ghiChu,
                      loaiGiaoDich: giaoDich.loaiGiaoDich,
                    );
                    await _suaGiaoDichController.updateGiaoDich(
                      updatedGiaoDich,
                      giaoDich.loaiGiaoDich,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cập nhật giao dịch thành công!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi cập nhật: $e')),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TẤT CẢ GIAO DỊCH',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
              'Lọc theo loại giao dịch',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
              children: [
                _buildFilterChip('Tất cả', _loaiGiaoDich == 'Tất cả', () {
                setState(() {
                  _loaiGiaoDich = 'Tất cả';
                });
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Thu nhập', _loaiGiaoDich == 'Thu nhập', () {
                setState(() {
                  _loaiGiaoDich = 'Thu nhập';
                });
                }, Colors.green[100]!),
                const SizedBox(width: 8),
                _buildFilterChip('Chi tiêu', _loaiGiaoDich == 'Chi tiêu', () {
                setState(() {
                  _loaiGiaoDich = 'Chi tiêu';
                });
                }, Colors.red[100]!),
              ],
              ),
              const SizedBox(height: 16),
              TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm giao dịch...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                ),
              ),
              ),
              const SizedBox(height: 16),
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                'Danh sách giao dịch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                onPressed: () => _selectDateRange(context),
                child:
                  const Text('Lọc', style: TextStyle(color: Colors.blue)),
                ),
              ],
              ),
              if (_startDate != null && _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                'Đang hiển thị: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<GiaoDich>>(
              stream: _loaiGiaoDich == 'Thu nhập'
                ? _giaoDichController.getThuGiaoDichs().map((list) {
                  return _filterByDateRange(list);
                  })
                : _loaiGiaoDich == 'Chi tiêu'
                  ? _giaoDichController.getChiGiaoDichs().map((list) {
                    return _filterByDateRange(list);
                    })
                  : CombineLatestStream.list([
                    _giaoDichController.getThuGiaoDichs(),
                    _giaoDichController.getChiGiaoDichs(),
                    ]).map((lists) {
                    List<GiaoDich> allGiaoDich = [];
                    for (var list in lists) {
                      if (list is List<GiaoDich>) {
                      allGiaoDich.addAll(list);
                      }
                    }
                    allGiaoDich.sort((a, b) =>
                      b.ngayGiaoDich.compareTo(a.ngayGiaoDich)); // Sắp xếp theo ngày
                    return _filterByDateRange(allGiaoDich);
                    }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                return Text('Lỗi: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Không có giao dịch nào.');
                }

                List<GiaoDich> filteredGiaoDichs = snapshot.data!;
                double totalAmount = _loaiGiaoDich != 'Tất cả'
                  ? _calculateTotalAmount(filteredGiaoDichs)
                  : 0;

                Map<DateTime, List<GiaoDich>> groupedByDate = {};
                for (var gd in filteredGiaoDichs) {
                DateTime dateKey = DateTime(gd.ngayGiaoDich.year,
                  gd.ngayGiaoDich.month, gd.ngayGiaoDich.day);
                if (!groupedByDate.containsKey(dateKey)) {
                  groupedByDate[dateKey] = [];
                }
                groupedByDate[dateKey]!.add(gd);
                }

                // Sắp xếp giao dịch trong mỗi ngày theo thời gian mới nhất (giảm dần)
                groupedByDate.forEach((date, giaoDichs) {
                giaoDichs.sort((a, b) => b.ngayGiaoDich.compareTo(a.ngayGiaoDich));
                });

                // Sắp xếp các ngày theo thứ tự mới nhất (giảm dần)
                final sortedDateEntries = groupedByDate.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key));

                return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_loaiGiaoDich != 'Tất cả')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                    'Tổng ${_loaiGiaoDich == 'Thu nhập' ? 'thu nhập' : 'chi tiêu'}: ${formatCurrency(totalAmount.abs())} ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _loaiGiaoDich == 'Thu nhập'
                        ? Colors.green
                        : Colors.red,
                    ),
                    ),
                  ),
                  ...sortedDateEntries.map((entry) {
                  DateTime date = entry.key;
                  List<GiaoDich> dateGiaoDichs = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: const TextStyle(
                        fontSize: 16, color: Colors.grey),
                    ),
                    ...dateGiaoDichs.map((gd) => Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                        margin: EdgeInsets.symmetric(vertical: 8),
                        color: Color.fromARGB(255, 4, 99, 207),
                        child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                            CrossAxisAlignment.start,
                          children: [
                          Text(
                            gd.tenGiaoDich,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            gd.danhMuc,
                            style: TextStyle(
                            fontSize: 14,
                            color: (gd.loaiGiaoDich == 'Chi tiêu' && gd.isCompleted == true)
                              ? Colors.green
                              : Colors.white,
                            ),
                             
                          ),
                          SizedBox(height: 4),
                          Text(
                            gd.ghiChu != null && gd.ghiChu!.isNotEmpty
                              ? 'Ghi chú: ${gd.ghiChu}'
                              : '',
                            style: TextStyle(
                              fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            '${gd.loaiGiaoDich == 'Thu nhập' ? '+' : '-'}${formatCurrency(gd.soTien.abs())} ',
                            style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: gd.loaiGiaoDich == 'Thu nhập'
                              ? Colors.green
                              : Colors.red,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment:
                              MainAxisAlignment.end,
                            children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(8),
                              ),
                              child: Icon(Icons.delete,
                                color: Colors.white),
                              onPressed: () async {
                              try {
                                await _xoaGiaoDichController
                                  .deleteGiaoDich(gd.id!,
                                    gd.loaiGiaoDich);
                                ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Giao dịch đã được xóa!')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Lỗi khi xóa: $e')),
                                );
                              }
                              },
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: CircleBorder(),
                              padding: EdgeInsets.all(8),
                              ),
                              child: Icon(Icons.edit,
                                color: Colors.white),
                              onPressed: () =>
                                _showEditDialog(context, gd),
                            ),
                            ],
                          ),
                          ],
                        ),
                        ),
                      )),
                    ],
                  );
                  }).toList(),
                ],
                );
              },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap,
      [Color? selectedColor]) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected
            ? (selectedColor ?? const Color(0xFFE3F2FD))
            : Colors.grey[200],
        labelStyle: TextStyle(
            color: isSelected
                ? (selectedColor != null ? Colors.black : Colors.blue)
                : Colors.black),
      ),
    );
  }
}