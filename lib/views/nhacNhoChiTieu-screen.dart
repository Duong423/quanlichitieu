// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/themNhacNhoChiTieu_controller.dart';
import '../controllers/capNhatNhacNhoChiTieu_controller.dart';
import '../controllers/xoa_chi_tieu_controller.dart';
import '../controllers/suaNhacNhoChiTieu_controller.dart';
import '../models/chiTieuSapToi_model.dart';
import 'main_screen.dart';

class NhacNhoChiTieuScreen extends StatefulWidget {
  @override
  _NhacNhoChiTieuScreenState createState() => _NhacNhoChiTieuScreenState();
}

class _NhacNhoChiTieuScreenState extends State<NhacNhoChiTieuScreen> {
  final ThemChiTieuController _themChiTieuController = ThemChiTieuController();
  final CapNhatChiTieuController _capNhatChiTieuController = CapNhatChiTieuController();
  final XoaChiTieuController _xoaChiTieuController = XoaChiTieuController();
  final SuaNhacNhoChiTieuController _suaChiTieuController = SuaNhacNhoChiTieuController();
  
  // Biến để lưu trạng thái filter
  String selectedFilter = 'Tất cả';

  Future<void> _showAddChiTieuDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String tenGiaoDich = '';
    double soTien = 0;
    DateTime ngayDenHan = DateTime.now();
    String? selectedNo;
    TextEditingController dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(ngayDenHan),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Thêm khoản chi tiêu mới'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Tên giao dịch'),
                        validator: (value) =>
                            value!.isEmpty ? 'Vui lòng nhập tên giao dịch' : null,
                        onChanged: (value) => tenGiaoDich = value,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Số tiền (đ)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Vui lòng nhập số tiền';
                          if (double.tryParse(value) == null || double.parse(value) <= 0)
                            return 'Số tiền phải là số dương';
                          return null;
                        },
                        onChanged: (value) => soTien = double.tryParse(value) ?? soTien,
                      ),
                      TextFormField(
                        controller: dateController,
                        decoration: InputDecoration(labelText: 'Ngày đến hạn'),
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: ngayDenHan,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            ngayDenHan = picked;
                            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                          }
                        },
                        validator: (value) =>
                            value!.isEmpty ? 'Vui lòng chọn ngày đến hạn' : null,
                      ),
                      SizedBox(height: 16),
                      Text('Loại nợ:', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Tôi'),
                              value: 'Tôi',
                              groupValue: selectedNo,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedNo = value;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Họ'),
                              value: 'Họ',
                              groupValue: selectedNo,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedNo = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && selectedNo != null) {
                      try {
                        ChiTieuSapToi chiTieu = ChiTieuSapToi(
                          tenGiaoDich: tenGiaoDich,
                          ngayDenHan: ngayDenHan,
                          soTien: soTien,
                          status: ngayDenHan.isBefore(DateTime.now()) ? 'Quá hạn' : 'Sắp tới hạn',
                          no: selectedNo,
                        );
                        await _themChiTieuController.addChiTieu(chiTieu);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Thêm chi tiêu thành công!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi thêm chi tiêu: $e')),
                        );
                      }
                    } else if (selectedNo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng chọn loại nợ')),
                      );
                    }
                  },
                  child: Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditChiTieuDialog(BuildContext context, ChiTieuSapToi chiTieu) async {
    final _formKey = GlobalKey<FormState>();
    String tenGiaoDich = chiTieu.tenGiaoDich;
    double soTien = chiTieu.soTien;
    DateTime ngayDenHan = chiTieu.ngayDenHan;
    String? selectedNo = chiTieu.no;
    double? congThemSoTien;
    TextEditingController dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(ngayDenHan),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Sửa khoản chi tiêu'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: tenGiaoDich,
                        decoration: InputDecoration(labelText: 'Tên giao dịch'),
                        validator: (value) =>
                            value!.isEmpty ? 'Vui lòng nhập tên giao dịch' : null,
                        onChanged: (value) => tenGiaoDich = value,
                      ),
                      TextFormField(
                        initialValue: soTien.toString(),
                        decoration: InputDecoration(labelText: 'Số tiền (đ)'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return 'Vui lòng nhập số tiền';
                          if (double.tryParse(value) == null || double.parse(value) <= 0)
                            return 'Số tiền phải là số dương';
                          return null;
                        },
                        onChanged: (value) => soTien = double.tryParse(value) ?? soTien,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Cộng thêm số tiền (nếu có)'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          congThemSoTien = double.tryParse(value) ?? 0;
                        },
                      ),
                      TextFormField(
                        controller: dateController,
                        decoration: InputDecoration(labelText: 'Ngày đến hạn'),
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: ngayDenHan,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            ngayDenHan = picked;
                            dateController.text = DateFormat('dd/MM/yyyy').format(picked);
                          }
                        },
                        validator: (value) =>
                            value!.isEmpty ? 'Vui lòng chọn ngày đến hạn' : null,
                      ),
                      SizedBox(height: 16),
                      Text('Loại nợ:', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Tôi'),
                              value: 'Tôi',
                              groupValue: selectedNo,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedNo = value;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Họ'),
                              value: 'Họ',
                              groupValue: selectedNo,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedNo = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && selectedNo != null) {
                      try {
                        double soTienMoi = soTien + (congThemSoTien ?? 0);
                        ChiTieuSapToi updatedChiTieu = ChiTieuSapToi(
                          id: chiTieu.id,
                          tenGiaoDich: tenGiaoDich,
                          ngayDenHan: ngayDenHan,
                          soTien: soTienMoi,
                          status: ngayDenHan.isBefore(DateTime.now()) ? 'Quá hạn' : 'Sắp tới hạn',
                          no: selectedNo,
                        );
                        await _suaChiTieuController.updateChiTieu(chiTieu.id!, updatedChiTieu);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cập nhật chi tiêu thành công!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi cập nhật chi tiêu: $e')),
                        );
                      }
                    } else if (selectedNo == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vui lòng chọn loại nợ')),
                      );
                    }
                  },
                  child: Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NHẮC NHỞ CHI TIÊU',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget thông báo cảnh báo
              _buildWarningNotificationWidget(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Các khoản chi tiêu sắp tới',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.blue[800]),
                    onPressed: () => _showAddChiTieuDialog(context),
                  ),
                ],
              ),
              Wrap(
                children: [
                  _buildFilterChip('Tất cả'),
                  SizedBox(width: 8),
                  _buildFilterChip('Sắp tới'),
                  SizedBox(width: 8),
                  _buildFilterChip('Quá hạn'),
                  SizedBox(width: 8),
                  _buildFilterChip('Hoàn thành'),
                ],
              ),
              SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chiTieuSapToi')
                    .orderBy('ngayDenHan', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Lỗi: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('Không có khoản chi tiêu nào.');
                  }

                  List<ChiTieuSapToi> chiTieuList = snapshot.data!.docs.map((doc) {
                    return ChiTieuSapToi.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  }).toList();

                  // Lọc danh sách theo filter đã chọn
                  List<ChiTieuSapToi> filteredList = _filterChiTieuList(chiTieuList);

                  return Column(
                    children: filteredList.map((chiTieu) {
                      String displayStatus;
                      Color statusColor;
                      IconData statusIcon;
                      DateTime now = DateTime.now();
                      DateTime today = DateTime(now.year, now.month, now.day);
                      DateTime denHan = DateTime(
                        chiTieu.ngayDenHan.year,
                        chiTieu.ngayDenHan.month,
                        chiTieu.ngayDenHan.day,
                      );

                      int daysUntilDue = denHan.difference(today).inDays;

                      if (chiTieu.status == 'Đã hoàn thành') {
                        displayStatus = 'Đã hoàn thành';
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                      } else if (denHan.isBefore(today)) {
                        displayStatus = 'Quá hạn';
                        statusColor = Colors.red;
                        statusIcon = Icons.warning;
                      } else {
                        displayStatus = 'Sắp tới hạn $daysUntilDue ngày';
                        statusColor = Colors.yellow[700]!;
                        statusIcon = Icons.access_time;
                      }

                      return _buildReminderCard(
                        title: chiTieu.tenGiaoDich,
                        date: DateFormat('dd/MM/yyyy').format(chiTieu.ngayDenHan),
                        status: displayStatus,
                        amount: chiTieu.soTien.toStringAsFixed(0),
                        statusColor: statusColor,
                        statusIcon: statusIcon,
                        chiTieuId: chiTieu.id!,
                        isCompleted: chiTieu.status == 'Đã hoàn thành',
                        onComplete: () async {
                          try {
                            await _capNhatChiTieuController.updateChiTieuStatus(
                              chiTieu.id!,
                              'Đã hoàn thành',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Đã đánh dấu hoàn thành và xóa cảnh báo!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningNotificationWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chiTieuSapToi')
          .orderBy('ngayDenHan', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container();
        }

        List<ChiTieuSapToi> chiTieuList = snapshot.data!.docs.map((doc) {
          return ChiTieuSapToi.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Lọc các khoản cần cảnh báo
        List<Map<String, dynamic>> warnings = [];
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);

        for (var chiTieu in chiTieuList) {
          if (chiTieu.status == 'Đã hoàn thành') continue; // Bỏ qua các khoản đã hoàn thành
          
          DateTime denHan = DateTime(
            chiTieu.ngayDenHan.year,
            chiTieu.ngayDenHan.month,
            chiTieu.ngayDenHan.day,
          );
          
          int daysUntilDue = denHan.difference(today).inDays;
          
          // Cảnh báo đỏ: quá hạn hoặc đến hạn hôm nay
          if (daysUntilDue <= 0) {
            warnings.add({
              'chiTieu': chiTieu,
              'type': 'overdue',
              'daysUntilDue': daysUntilDue,
              'message': daysUntilDue == 0 
                  ? 'Hôm nay đến hạn' 
                  : 'Quá hạn ${(-daysUntilDue)} ngày',
            });
          }
          // Cảnh báo cam: còn 1-3 ngày
          else if (daysUntilDue <= 3) {
            warnings.add({
              'chiTieu': chiTieu,
              'type': 'warning',
              'daysUntilDue': daysUntilDue,
              'message': 'Còn $daysUntilDue ngày',
            });
          }
        }

        if (warnings.isEmpty) {
          return Container();
        }

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            children: warnings.map((warning) {
              final chiTieu = warning['chiTieu'] as ChiTieuSapToi;
              final type = warning['type'] as String;
              final message = warning['message'] as String;
              
              Color backgroundColor;
              Color textColor;
              Color iconColor;
              IconData icon;
              String title;
              
              if (type == 'overdue') {
                backgroundColor = Colors.red[50]!;
                textColor = Colors.red[800]!;
                iconColor = Colors.red;
                icon = Icons.error;
                title = '🚨 Quá hạn thanh toán';
              } else {
                backgroundColor = Colors.orange[50]!;
                textColor = Colors.orange[800]!;
                iconColor = Colors.orange;
                icon = Icons.warning;
                title = '⚠️ Sắp đến hạn';
              }
              
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${chiTieu.tenGiaoDich} - ${message}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Số tiền: ${_formatCurrency(chiTieu.soTien)}',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        try {
                          await _capNhatChiTieuController.updateChiTieuStatus(
                            chiTieu.id!,
                            'Đã hoàn thành',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Đã đánh dấu hoàn thành và xóa cảnh báo!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi cập nhật: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.check_circle, color: Colors.green, size: 20),
                      tooltip: 'Đánh dấu hoàn thành',
                    ),
                    IconButton(
                      onPressed: () async {
                        // Tìm và hiển thị dialog chỉnh sửa
                        DocumentSnapshot doc = await FirebaseFirestore.instance
                            .collection('chiTieuSapToi')
                            .doc(chiTieu.id)
                            .get();
                        
                        if (doc.exists) {
                          ChiTieuSapToi fullChiTieu = ChiTieuSapToi.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          );
                          _showEditChiTieuDialog(context, fullChiTieu);
                        }
                      },
                      icon: Icon(Icons.edit, color: iconColor, size: 20),
                      tooltip: 'Chỉnh sửa',
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} đ';
  }

  // Phương thức lọc danh sách chi tiêu theo filter
  List<ChiTieuSapToi> _filterChiTieuList(List<ChiTieuSapToi> chiTieuList) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    switch (selectedFilter) {
      case 'Sắp tới':
        return chiTieuList.where((chiTieu) {
          if (chiTieu.status == 'Đã hoàn thành') return false;
          DateTime denHan = DateTime(
            chiTieu.ngayDenHan.year,
            chiTieu.ngayDenHan.month,
            chiTieu.ngayDenHan.day,
          );
          return denHan.isAfter(today);
        }).toList();
      
      case 'Quá hạn':
        return chiTieuList.where((chiTieu) {
          if (chiTieu.status == 'Đã hoàn thành') return false;
          DateTime denHan = DateTime(
            chiTieu.ngayDenHan.year,
            chiTieu.ngayDenHan.month,
            chiTieu.ngayDenHan.day,
          );
          return denHan.isBefore(today) || denHan.isAtSameMomentAs(today);
        }).toList();
      
      case 'Hoàn thành':
        return chiTieuList.where((chiTieu) => chiTieu.status == 'Đã hoàn thành').toList();
      
      case 'Tất cả':
      default:
        return chiTieuList;
    }
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? Colors.blue[800] : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String title,
    required String date,
    required String status,
    required String amount,
    required Color statusColor,
    required IconData statusIcon,
    required String chiTieuId,
    required bool isCompleted,
    required VoidCallback onComplete,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Color.fromARGB(255, 4, 99, 207),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Thời gian: $date', style: TextStyle(color: Colors.white)),
            Text('Hạn: $status', style: TextStyle(color: Colors.white)),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('chiTieuSapToi').doc(chiTieuId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  Map<String, dynamic>? data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data != null && data.containsKey('no')) {
                    String no = data['no'] ?? '';
                    if (no.isNotEmpty) {
                      return Text('Nợ: $no', style: TextStyle(color: Colors.white));
                    }
                  }
                }
                return SizedBox.shrink();
              },
            ),
            SizedBox(height: 8),
            Text(
              '$amount đ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isCompleted)
                  ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(8),
                    ),
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    DocumentSnapshot doc = await FirebaseFirestore.instance
                        .collection('chiTieuSapToi')
                        .doc(chiTieuId)
                        .get();
                    
                    if (doc.exists) {
                      ChiTieuSapToi chiTieu = ChiTieuSapToi.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      _showEditChiTieuDialog(context, chiTieu);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(8),
                  ),
                  child: Icon(Icons.edit, color: Colors.white),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _xoaChiTieuController.deleteChiTieu(chiTieuId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Chi tiêu đã được xóa!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi xóa: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(8),
                  ),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}