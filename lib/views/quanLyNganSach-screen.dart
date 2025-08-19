// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../controllers/danh_muc_controller.dart';
import '../models/ngan_sach_danh_muc.dart';

class QuanLyNganSachScreen extends StatefulWidget {
  @override
  _QuanLyNganSachScreenState createState() => _QuanLyNganSachScreenState();
}

class _QuanLyNganSachScreenState extends State<QuanLyNganSachScreen> {
  final DanhMucController _danhMucController = DanhMucController();
  DateTime _selectedDate = DateTime.now();

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} đ';
  }

  Widget _buildBudgetCard(NganSachDanhMuc nganSach) {
    final percentUsed = nganSach.nganSach > 0 ? (nganSach.daSuDung / nganSach.nganSach) : 0.0;
    final remaining = nganSach.nganSach - nganSach.daSuDung;
    
    Color progressColor = Colors.green;
    if (percentUsed > 0.8) {
      progressColor = Colors.red;
    } else if (percentUsed > 0.6) {
      progressColor = Colors.orange;
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getCategoryIcon(nganSach.tenDanhMuc), color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      nganSach.tenDanhMuc,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditBudgetDialog(nganSach);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(nganSach);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Ngân sách: ${formatCurrency(nganSach.nganSach)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Đã sử dụng: ${formatCurrency(nganSach.daSuDung)}',
              style: TextStyle(fontSize: 16, color: progressColor),
            ),
            SizedBox(height: 4),
            Text(
              'Còn lại: ${formatCurrency(remaining)}',
              style: TextStyle(
                fontSize: 16,
                color: remaining >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentUsed.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            SizedBox(height: 8),
            Text(
              '${(percentUsed * 100).toStringAsFixed(1)}% đã sử dụng',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'Ăn uống': return Icons.fastfood;
      case 'Mua sắm': return Icons.shopping_bag;
      case 'Di chuyển': return Icons.directions_car;
      case 'Nhà cửa': return Icons.home;
      case 'Giải trí': return Icons.movie;
      case 'Sức khỏe': return Icons.favorite;
      case 'Giáo dục': return Icons.school;
      case 'Hóa đơn': return Icons.receipt;
      default: return Icons.more_horiz;
    }
  }

  void _showEditBudgetDialog(NganSachDanhMuc nganSach) {
    final TextEditingController budgetController = TextEditingController();
    budgetController.text = nganSach.nganSach.toString();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chỉnh sửa ngân sách'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Danh mục: ${nganSach.tenDanhMuc}'),
              SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ngân sách mới (VND)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (budgetController.text.isNotEmpty) {
                  final newBudget = double.parse(budgetController.text);
                  try {
                    await _danhMucController.updateNganSach(nganSach.id!, newBudget);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cập nhật ngân sách thành công!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(NganSachDanhMuc nganSach) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa ngân sách cho danh mục "${nganSach.tenDanhMuc}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _danhMucController.deleteNganSach(nganSach.id!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xóa ngân sách thành công!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Xóa', style: TextStyle(color: Colors.white)),
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
        title: Text(
          'QUẢN LÝ NGÂN SÁCH',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, color: Colors.white),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tháng ${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NganSachDanhMuc>>(
              stream: _danhMucController.getNganSachsByMonth(
                _selectedDate.month,
                _selectedDate.year,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, 
                             size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có ngân sách nào được đặt\ncho tháng này',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildBudgetCard(snapshot.data![index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
