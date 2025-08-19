// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, sort_child_properties_last

import 'package:flutter/material.dart';
import '../controllers/danh_muc_co_ban_controller.dart';
import '../models/danh_muc_co_ban.dart';

class InitializeDataScreen extends StatefulWidget {
  @override
  _InitializeDataScreenState createState() => _InitializeDataScreenState();
}

class _InitializeDataScreenState extends State<InitializeDataScreen> {
  final DanhMucCoBanController _controller = DanhMucCoBanController();
  bool _isInitializing = false;

  Future<void> _initializeCategories() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      await _controller.initializeDefaultCategories();
      
      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Khởi tạo danh mục thành công!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Thêm một chút delay để user thấy hiệu ứng
      await Future.delayed(Duration(milliseconds: 500));
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Lỗi: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedIcon = 'more_horiz'; // Move inside StatefulBuilder
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Thêm danh mục mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên danh mục',
                        hintText: 'Ví dụ: Đầu tư, Quà tặng, v.v.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Mô tả (tùy chọn)',
                        hintText: 'Mô tả chi tiết về danh mục',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Text('Chọn biểu tượng:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildIconChoice('more_horiz', Icons.more_horiz, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('attach_money', Icons.attach_money, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('savings', Icons.savings, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('card_giftcard', Icons.card_giftcard, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('pets', Icons.pets, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('sports_esports', Icons.sports_esports, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('local_gas_station', Icons.local_gas_station, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('restaurant', Icons.restaurant, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('book', Icons.book, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('fitness_center', Icons.fitness_center, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('computer', Icons.computer, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                        _buildIconChoice('phone', Icons.phone, selectedIcon, (newIcon) { setDialogState(() { selectedIcon = newIcon; }); }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty) {
                      try {
                        await _controller.addDanhMuc(DanhMucCoBan(
                          tenDanhMuc: nameController.text.trim(),
                          icon: selectedIcon,
                          moTa: descriptionController.text.trim(),
                          ngayTao: DateTime.now(),
                        ));
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(child: Text('Thêm danh mục "${nameController.text}" thành công!')),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error, color: Colors.white),
                                SizedBox(width: 8),
                                Expanded(child: Text('Lỗi: $e')),
                              ],
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Vui lòng nhập tên danh mục!'),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIconChoice(String iconName, IconData icon, String selectedIcon, Function(String) onTap) {
    return GestureDetector(
      onTap: () {
        onTap(iconName);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selectedIcon == iconName ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedIcon == iconName ? Colors.blue : Colors.grey,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: selectedIcon == iconName ? Colors.blue : Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Khởi tạo dữ liệu', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            // Hiệu ứng mượt mà khi quay về
            Navigator.of(context).pop();
          },
          tooltip: 'Quay về trang chủ',
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.2),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Khởi tạo danh mục mặc định',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tạo các danh mục cơ bản như Ăn uống, Mua sắm, v.v.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isInitializing ? null : _initializeCategories,
              child: _isInitializing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Đang khởi tạo...'),
                      ],
                    )
                  : Text('Khởi tạo danh mục mặc định'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            OutlinedButton(
              onPressed: _showAddCategoryDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Thêm danh mục thủ công'),
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Danh sách danh mục hiện tại:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<DanhMucCoBan>>(
                stream: _controller.getAllDanhMucs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Chưa có danh mục nào.\nHãy khởi tạo danh mục mặc định hoặc thêm thủ công.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final category = snapshot.data![index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_getIconFromName(category.icon), color: Colors.blue),
                          title: Text(category.tenDanhMuc),
                          subtitle: Text(
                            category.moTa.isNotEmpty 
                                ? category.moTa 
                                : 'Không có mô tả',
                          ),
                          trailing: PopupMenuButton(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _showDeleteConfirmDialog(category);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Xóa', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            // Nút quay về trang chủ với hiệu ứng đẹp
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Hiệu ứng mượt mà khi quay về trang chủ
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.home, color: Colors.white),
                label: Text(
                  'Quay về trang chủ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.3),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
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
      default: return Icons.more_horiz;
    }
  }

  void _showDeleteConfirmDialog(DanhMucCoBan category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa danh mục "${category.tenDanhMuc}"?\n\nLưu ý: Việc xóa danh mục có thể ảnh hưởng đến các giao dịch đã có.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _controller.deleteDanhMuc(category.id!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(child: Text('Xóa danh mục "${category.tenDanhMuc}" thành công!')),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(child: Text('Lỗi khi xóa: $e')),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
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
}
