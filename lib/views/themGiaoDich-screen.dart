// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../../controllers/giao_dich_controller.dart';
import '../../controllers/danh_muc_controller.dart';
import '../../controllers/danh_muc_co_ban_controller.dart';
import '../../models/giao_dich.dart';
import '../../models/danh_muc_co_ban.dart';
import 'main_screen.dart';

class ThemGiaoDichScreen extends StatefulWidget {
  @override
  _ThemGiaoDichScreenState createState() => _ThemGiaoDichScreenState();
}

class _ThemGiaoDichScreenState extends State<ThemGiaoDichScreen> {
  final GiaoDichController _controller = GiaoDichController();
  final DanhMucController _danhMucController = DanhMucController();
  final DanhMucCoBanController _danhMucCoBanController = DanhMucCoBanController();
  String _loaiGiaoDich = 'Chi tiêu'; // Mặc định là Chi tiêu
  String _danhMuc = ''; // Sẽ được cập nhật từ Firebase
  DateTime _selectedDate = DateTime.now(); // Ngày mặc định là ngày hiện tại
  final TextEditingController _soTienController = TextEditingController();
  final TextEditingController _tenGiaoDichController = TextEditingController();
  final TextEditingController _ghiChuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategory();
  }

  Future<void> _initializeDefaultCategory() async {
    try {
      final categories = await _danhMucCoBanController.getAllDanhMucs().first;
      if (categories.isNotEmpty && _danhMuc.isEmpty) {
        setState(() {
          _danhMuc = categories.first.tenDanhMuc;
        });
      }
    } catch (e) {
      print('Error initializing default category: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveGiaoDich() async {
    if (_soTienController.text.isEmpty || _tenGiaoDichController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đủ thông tin!')),
      );
      return;
    }

    final giaoDich = GiaoDich(
      loaiGiaoDich: _loaiGiaoDich,
      soTien: double.parse(_soTienController.text.replaceAll('.', '')),
      tenGiaoDich: _tenGiaoDichController.text,
      danhMuc: _danhMuc,
      ngayGiaoDich: _selectedDate,
      ghiChu: _ghiChuController.text.isNotEmpty ? _ghiChuController.text : null,
    );

    try {
      await _controller.addGiaoDich(giaoDich);
      
      // Update budget if it's an expense
      if (_loaiGiaoDich == 'Chi tiêu') {
        await _updateBudgetUsage(giaoDich.soTien);
        // Kiểm tra cảnh báo ngân sách sau khi cập nhật
        await _checkBudgetWarning(giaoDich.danhMuc);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm giao dịch thành công!')),
      );
      
      // Clear form
      _soTienController.clear();
      _tenGiaoDichController.clear();
      _ghiChuController.clear();
      // Danh mục sẽ giữ nguyên để user tiện lợi khi thêm nhiều giao dịch cùng loại
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm giao dịch: $error')),
      );
    }
  }

  Future<void> _updateBudgetUsage(double amount) async {
    try {
      await _danhMucController.updateDaSuDungByDanhMuc(
        _danhMuc,
        amount,
        _selectedDate.month,
        _selectedDate.year,
      );
    } catch (e) {
      print('Error updating budget: $e');
    }
  }

  Future<void> _checkBudgetWarning(String danhMuc) async {
    try {
      final budgetStatus = await _danhMucController.getBudgetStatus(danhMuc);
      if (budgetStatus != null) {
        final phanTramConLai = budgetStatus['phanTramConLai'] as double;
        final tenDanhMuc = budgetStatus['tenDanhMuc'] as String;
        final conLai = budgetStatus['conLai'] as double;
        final nganSach = budgetStatus['nganSach'] as double;
        
        // Hiển thị cảnh báo nếu còn lại <= 10%
        if (phanTramConLai <= 10) {
          _showBudgetWarningDialog(
            tenDanhMuc,
            nganSach,
            conLai,
            phanTramConLai,
          );
        }
      }
    } catch (e) {
      print('Error checking budget warning: $e');
    }
  }

  void _showBudgetWarningDialog(String tenDanhMuc, double nganSach, double conLai, double phanTramConLai) {
    String title;
    String message;
    Color color;
    IconData icon;

    if (phanTramConLai <= 0) {
      title = '🚨 Đã vượt ngân sách!';
      message = 'Danh mục "$tenDanhMuc" đã vượt ngân sách ${formatCurrency(nganSach.abs())}.\nSố tiền vượt: ${formatCurrency(conLai.abs())}';
      color = Colors.red;
      icon = Icons.error;
    } else {
      title = '⚠️ Cảnh báo ngân sách!';
      message = 'Danh mục "$tenDanhMuc" chỉ còn lại ${phanTramConLai.toStringAsFixed(1)}% ngân sách.\nSố tiền còn lại: ${formatCurrency(conLai)}\nTổng ngân sách: ${formatCurrency(nganSach)}';
      color = Colors.orange;
      icon = Icons.warning;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(fontSize: 15),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb, color: color, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            phanTramConLai <= 0 
                                ? 'Hãy xem xét giảm chi tiêu hoặc tăng ngân sách.'
                                : 'Hãy chú ý chi tiêu để không vượt ngân sách.',
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đã hiểu', style: TextStyle(color: color)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showBudgetDialog(); // Mở dialog đặt ngân sách để điều chỉnh
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text('Điều chỉnh ngân sách'),
            ),
          ],
        );
      },
    );
  }

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )} đ';
  }

  void _showBudgetDialog() {
    final TextEditingController budgetController = TextEditingController();
    String selectedCategory = _danhMuc.isNotEmpty ? _danhMuc : '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đặt ngân sách cho danh mục',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  StreamBuilder<List<DanhMucCoBan>>(
                    stream: _danhMucCoBanController.getAllDanhMucs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text('Không có danh mục nào');
                      }
                      
                      List<DanhMucCoBan> categories = snapshot.data!;
                      
                      // Đảm bảo selectedCategory hợp lệ
                      if (selectedCategory.isEmpty || !categories.any((cat) => cat.tenDanhMuc == selectedCategory)) {
                        selectedCategory = categories.first.tenDanhMuc;
                      }
                      
                      return DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(labelText: 'Chọn danh mục'),
                        items: categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.tenDanhMuc,
                            child: Text(category.tenDanhMuc),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setDialogState(() {
                            selectedCategory = newValue!;
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  // Hiển thị số dư hiện tại
                  FutureBuilder<double>(
                    future: _controller.getSoDuHienTai(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 8),
                              Text('Đang kiểm tra thu nhập...'),
                            ],
                          ),
                        );
                      }
                      
                      final soDu = snapshot.data ?? 0.0;
                      return Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: soDu > 0 ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: soDu > 0 ? Colors.green[300]! : Colors.orange[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  soDu > 0 ? Icons.check_circle : Icons.warning,
                                  color: soDu > 0 ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Số dư hiện tại',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Số dư khả dụng: ${formatCurrency(soDu)}',
                              style: TextStyle(
                                color: soDu > 0 ? Colors.green[700] : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (soDu <= 0) ...[
                              SizedBox(height: 4),
                              Text(
                                '⚠️ Số dư không đủ để đặt ngân sách',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Ngân sách (VND)',
                      hintText: 'Ví dụ: 5000000',
                      helperText: 'Ngân sách phải ≤ số dư hiện có',
                      border: OutlineInputBorder(),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.cancel, color: Colors.grey),
                  label: Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text('Lưu ngân sách', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () async {
                    if (budgetController.text.isNotEmpty) {
                      final budget = double.parse(budgetController.text);
                      final now = DateTime.now();
                      
                      try {
                        // Get category by name to get its ID
                        final danhMuc = await _danhMucCoBanController.getDanhMucByName(selectedCategory);
                        if (danhMuc != null) {
                          await _danhMucController.createNganSachWithDanhMucId(
                            danhMuc.id!,
                            danhMuc.tenDanhMuc,
                            budget,
                            now.month,
                            now.year,
                          );
                          
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đặt ngân sách thành công!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Không tìm thấy danh mục!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        // Show detailed error message
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Không thể đặt ngân sách'),
                                  ),
                                ],
                              ),
                              content: Container(
                                width: double.maxFinite,
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                                ),
                                child: SingleChildScrollView(
                                  child: Text(
                                    e.toString().replaceAll('Exception: ', ''),
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Đã hiểu'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close error dialog
                                    budgetController.clear(); // Clear budget input
                                  },
                                  child: Text('Thử lại'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Vui lòng nhập số tiền ngân sách!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống': return 'fastfood';
      case 'Mua sắm': return 'shopping_bag';
      case 'Di chuyển': return 'directions_car';
      case 'Nhà cửa': return 'home';
      case 'Giải trí': return 'movie';
      case 'Sức khỏe': return 'favorite';
      case 'Giáo dục': return 'school';
      case 'Hóa đơn': return 'receipt';
      default: return 'more_horiz';
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'movie': return Icons.movie;
      case 'favorite': return Icons.favorite;
      case 'school': return Icons.school;
      case 'receipt': return Icons.receipt;
      case 'attach_money': return Icons.attach_money;
      case 'savings': return Icons.savings;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'pets': return Icons.pets;
      case 'sports_esports': return Icons.sports_esports;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'restaurant': return Icons.restaurant;
      case 'book': return Icons.book;
      case 'fitness_center': return Icons.fitness_center;
      case 'computer': return Icons.computer;
      case 'phone': return Icons.phone;
      case 'more_horiz':
      default: 
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'THÊM GIAO DỊCH',
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
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Widget hiển thị cảnh báo ngân sách
              _buildBudgetWarningWidget(),
              SizedBox(height: 16),
              // Loại giao dịch
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _loaiGiaoDich = 'Thu nhập';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _loaiGiaoDich == 'Thu nhập' ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Thu nhập',
                            style: TextStyle(
                              color: _loaiGiaoDich == 'Thu nhập' ? Colors.green : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _loaiGiaoDich = 'Chi tiêu';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              _loaiGiaoDich == 'Chi tiêu' ? Colors.red[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Chi tiêu',
                            style: TextStyle(
                              color: _loaiGiaoDich == 'Chi tiêu' ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showBudgetDialog();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Đặt ngân sách',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Số tiền
              Text(
                'Số tiền (VND)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _soTienController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: 100000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              // Tên giao dịch
              Text(
                'Tên giao dịch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _tenGiaoDichController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Tiền lương tháng 6',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Danh mục chi tiêu
              Text(
                'Danh mục chi tiêu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              StreamBuilder<List<DanhMucCoBan>>(
                stream: _danhMucCoBanController.getAllDanhMucs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Lỗi tải danh mục: ${snapshot.error}',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Chưa có danh mục nào. Hãy khởi tạo danh mục từ trang chủ.',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final categories = snapshot.data!;
                  
                  // Đảm bảo danh mục được chọn tồn tại trong danh sách
                  if (!categories.any((cat) => cat.tenDanhMuc == _danhMuc)) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _danhMuc = categories.first.tenDanhMuc;
                      });
                    });
                  }
                  
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      return _buildCategoryChip(
                        category.tenDanhMuc,
                        _getIconFromName(category.icon),
                        _danhMuc == category.tenDanhMuc,
                        () {
                          setState(() {
                            _danhMuc = category.tenDanhMuc;
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 16),
              // Ngày giao dịch
              Text(
                'Ngày giao dịch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today),
                    ],
                  ),
                  ),
                ),
              
              SizedBox(height: 16),
              // Ghi chú
              Text(
                'Ghi chú (tùy chọn)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _ghiChuController,
                decoration: InputDecoration(
                  hintText: 'Nhập ghi chú của bạn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              // Nút Lưu
              ElevatedButton(
                onPressed: _saveGiaoDich,
                child: Text('Lưu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetWarningWidget() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _danhMucController.checkBudgetWarnings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container();
        }
        
        final warnings = snapshot.data!;
        
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: Column(
            children: warnings.map((warning) {
              final tenDanhMuc = warning['tenDanhMuc'] as String;
              final phanTramConLai = warning['phanTramConLai'] as double;
              final conLai = warning['conLai'] as double;
              final loaiCanhBao = warning['loaiCanhBao'] as String;
              
              Color backgroundColor;
              Color textColor;
              Color iconColor;
              IconData icon;
              String title;
              
              if (loaiCanhBao == 'vuot_ngan_sach') {
                backgroundColor = Colors.red[50]!;
                textColor = Colors.red[700]!;
                iconColor = Colors.red;
                icon = Icons.error;
                title = 'Đã vượt ngân sách';
              } else {
                backgroundColor = Colors.orange[50]!;
                textColor = Colors.orange[700]!;
                iconColor = Colors.orange;
                icon = Icons.warning;
                title = 'Gần hết ngân sách';
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
                    Icon(icon, color: iconColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title: $tenDanhMuc',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            loaiCanhBao == 'vuot_ngan_sach'
                                ? 'Vượt ${formatCurrency(conLai.abs())}'
                                : 'Còn lại ${formatCurrency(conLai)} (${phanTramConLai.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showBudgetWarningDialog(
                          tenDanhMuc,
                          warning['nganSach'] as double,
                          conLai,
                          phanTramConLai,
                        );
                      },
                      icon: Icon(Icons.info_outline, color: iconColor, size: 20),
                      tooltip: 'Xem chi tiết',
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

  Widget _buildCategoryChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.blue : Colors.grey),
            SizedBox(width: 8),
            Text(label),
          ],
        ),
        backgroundColor: isSelected ? Colors.blue[100] : Colors.grey[200],
        labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.black),
      ),
    );
  }
}