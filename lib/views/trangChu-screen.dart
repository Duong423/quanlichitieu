// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import '../../controllers/giao_dich_controller.dart';
import '../../controllers/capNhatThangMoi_controller.dart';
import '../../models/giao_dich.dart';
import 'tatCaGiaoDich-screen.dart';
import 'themGiaoDich-screen.dart';
import 'quanLyNganSach-screen.dart';
import 'initialize_data_screen.dart';
import 'tongHopChiTieu-screen.dart';

class TrangChuScreen extends StatefulWidget {
  @override
  _TrangChuScreenState createState() => _TrangChuScreenState();
}

class _TrangChuScreenState extends State<TrangChuScreen> {
  final GiaoDichController _giaoDichController = GiaoDichController();
  final CapNhatThangMoiController _capNhatThangMoiController = CapNhatThangMoiController();
  String _selectedMonth = DateFormat('MM-yyyy').format(DateTime.now());
  final DateTime now = DateTime.now();
  final String thangNamHienTai = '${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}'; // 06-2025

  @override
  void initState() {
    super.initState();
    _checkNewMonth();
  }

  Future<void> _checkNewMonth() async {
    try {
      await _capNhatThangMoiController.checkAndUpdateNewMonth();
      setState(() {
        _selectedMonth = DateFormat('MM-yyyy').format(DateTime.now());
      });
    } catch (e) {
      print('Lỗi khi kiểm tra tháng mới: $e');
    }
  }

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  // Lấy tháng trước từ tháng hiện tại
  String getThangTruoc(String thangNam) {
    List<String> parts = thangNam.split('-');
    int thang = int.parse(parts[0]);
    int nam = int.parse(parts[1]);
    int thangTruoc = thang == 1 ? 12 : thang - 1;
    int namTruoc = thang == 1 ? nam - 1 : nam;
    return '${thangTruoc.toString().padLeft(2, '0')}-${namTruoc}';
  }

  @override
  Widget build(BuildContext context) {
    String thangNamTruoc = getThangTruoc(thangNamHienTai);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Số dư hiện tại
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[800]!, Colors.blue[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ignore: prefer_const_constructors
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'QUẢN LÝ THU CHI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // CircleAvatar(
                        //   backgroundColor: Colors.white,
                        //   child: Text(
                        //     'NT',
                        //     style: TextStyle(color: Colors.blue[800]!),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Số dư hiện tại',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    StreamBuilder<Map<String, List<GiaoDich>>>(
                      stream: CombineLatestStream.combine2(
                        _giaoDichController.getThuGiaoDichs(thangNam: thangNamHienTai),
                        _giaoDichController.getChiGiaoDichs(thangNam: thangNamHienTai),
                        (List<GiaoDich> thuList, List<GiaoDich> chiList) {
                          return {'thu': thuList, 'chi': chiList};
                        },
                      ),
                      builder: (context, AsyncSnapshot<Map<String, List<GiaoDich>>> snapshot) {
                        return FutureBuilder<double>(
                          future: _giaoDichController.getSoDuThangTruoc(thangNamHienTai),
                          builder: (context, soDuSnapshot) {
                            if (soDuSnapshot.connectionState == ConnectionState.waiting ||
                                snapshot.connectionState == ConnectionState.waiting) {
                              return const Text(
                                'Đang tải...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            if (soDuSnapshot.hasError) {
                              return Text(
                                'Lỗi số dư: ${soDuSnapshot.error}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Text(
                                'Lỗi giao dịch: ${snapshot.error}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            double soDuCu = soDuSnapshot.data ?? 0.0;
                            List<GiaoDich> thuList = snapshot.data?['thu'] ?? [];
                            List<GiaoDich> chiList = snapshot.data?['chi'] ?? [];
                            double totalThu = thuList.fold(0, (sum, gd) => sum + gd.soTien);
                            double totalChi = chiList.fold(0, (sum, gd) => sum + gd.soTien);
                            double soDuMoi = soDuCu + (totalThu - totalChi);

                            // Cập nhật số dư mới vào collection soDu
                            if (thuList.isNotEmpty || chiList.isNotEmpty) {
                              _giaoDichController.capNhatSoDu(thangNamHienTai, soDuMoi);
                            } else {
                              // Nếu không có giao dịch, đặt số dư bằng số dư cũ
                              _giaoDichController.capNhatSoDu(thangNamHienTai, soDuCu);
                            }

                            return Text(
                              formatCurrency(soDuMoi),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thu nhập',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              StreamBuilder<List<GiaoDich>>(
                                stream: _giaoDichController.getThuGiaoDichs(thangNam: thangNamHienTai),
                                builder: (context, snapshotThu) {
                                  return StreamBuilder<List<GiaoDich>>(
                                    stream: _giaoDichController.getThuGiaoDichs(thangNam: thangNamTruoc),
                                    builder: (context, snapshotThuTruoc) {
                                      if (snapshotThu.connectionState == ConnectionState.waiting ||
                                          snapshotThuTruoc.connectionState == ConnectionState.waiting) {
                                        return const Text(
                                          'Đang tải...',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      if (snapshotThu.hasError) {
                                        return Text(
                                          'Lỗi: ${snapshotThu.error}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      if (snapshotThuTruoc.hasError) {
                                        return Text(
                                          'Lỗi: ${snapshotThuTruoc.error}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      List<GiaoDich> thuList = snapshotThu.data ?? [];
                                      double totalThu = thuList.fold(0, (sum, gd) => sum + gd.soTien);

                                      if (thuList.isEmpty) {
                                        List<GiaoDich> thuListTruoc = snapshotThuTruoc.data ?? [];
                                        double totalThuTruoc = thuListTruoc.fold(0, (sum, gd) => sum + gd.soTien);
                                        return Text(
                                          totalThuTruoc == 0
                                              ? '0 đ'
                                              : '${formatCurrency(totalThuTruoc)} (Tạm thời)',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }

                                      return Text(
                                        formatCurrency(totalThu),
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Chi tiêu',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              StreamBuilder<List<GiaoDich>>(
                                stream: _giaoDichController.getChiGiaoDichs(thangNam: thangNamHienTai),
                                builder: (context, snapshotChi) {
                                  return StreamBuilder<List<GiaoDich>>(
                                    stream: _giaoDichController.getChiGiaoDichs(thangNam: thangNamTruoc),
                                    builder: (context, snapshotChiTruoc) {
                                      if (snapshotChi.connectionState == ConnectionState.waiting ||
                                          snapshotChiTruoc.connectionState == ConnectionState.waiting) {
                                        return const Text(
                                          'Đang tải...',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      if (snapshotChi.hasError) {
                                        return Text(
                                          'Lỗi: ${snapshotChi.error}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      if (snapshotChiTruoc.hasError) {
                                        return Text(
                                          'Lỗi: ${snapshotChiTruoc.error}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }
                                      List<GiaoDich> chiList = snapshotChi.data ?? [];
                                      double totalChi = chiList.fold(0, (sum, gd) => sum + gd.soTien);

                                      if (chiList.isEmpty) {
                                        List<GiaoDich> chiListTruoc = snapshotChiTruoc.data ?? [];
                                        double totalChiTruoc = chiListTruoc.fold(0, (sum, gd) => sum + gd.soTien);
                                        return Text(
                                          totalChiTruoc == 0
                                              ? '0 đ'
                                              : '${formatCurrency(totalChiTruoc)} (Tạm thời)',
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      }

                                      return Text(
                                        formatCurrency(totalChi),
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick Actions Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tính năng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            'Quản lý\nNgân sách',
                            Icons.account_balance_wallet,
                            Colors.green,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => QuanLyNganSachScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            'Thêm\nGiao dịch',
                            Icons.add_circle,
                            Colors.blue,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ThemGiaoDichScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            'Quản lý\nDanh mục',
                            Icons.category,
                            Colors.purple,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InitializeDataScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            'Xem tất cả\nGiao dịch',
                            Icons.list_alt,
                            Colors.orange,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TatCaGiaoDichScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            'Tổng hợp\nChi tiêu',
                            Icons.analytics,
                            Colors.teal,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TongHopChiTieuScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(), // Empty space
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Biểu đồ chi tiêu tuần này
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiêu tuần này',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 5, // Giá trị tối đa trên trục Y (triệu đồng)
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                                  return Text(days[value.toInt()], style: const TextStyle(fontSize: 12));
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3, color: Colors.blue)]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 4, color: Colors.blue)]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2, color: Colors.blue)]),
                            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 1, color: Colors.blue)]),
                            BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 0.5, color: Colors.blue)]),
                            BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 0, color: Colors.blue)]),
                            BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 0, color: Colors.blue)]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Giao dịch gần đây
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giao dịch gần đây',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TatCaGiaoDichScreen()),
                        );
                      },
                      child: const Text('Xem tất cả', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<GiaoDich>>(
                stream: CombineLatestStream.combine2(
                  _giaoDichController.getAllThuGiaoDichs().map((dynamicList) {
                    if (dynamicList is List<GiaoDich>) {
                      return dynamicList..sort((a, b) => b.ngayGiaoDich.compareTo(a.ngayGiaoDich));
                    }
                    return <GiaoDich>[];
                  }).map((sorted) => sorted.isNotEmpty ? [sorted.first] : []),
                  _giaoDichController.getAllChiGiaoDichs().map((dynamicList) {
                    if (dynamicList is List<GiaoDich>) {
                      return dynamicList..sort((a, b) => b.ngayGiaoDich.compareTo(a.ngayGiaoDich));
                    }
                    return <GiaoDich>[];
                  }).map((sorted) => sorted.isNotEmpty ? [sorted.first] : []),
                  (dynamic thuList, dynamic chiList) {
                    List<GiaoDich> all = [];
                    if (thuList is List<GiaoDich>) all.addAll(thuList);
                    if (chiList is List<GiaoDich>) all.addAll(chiList);
                    all.sort((a, b) => b.ngayGiaoDich.compareTo(a.ngayGiaoDich));
                    return all.isNotEmpty ? [all.first] : [];
                  },
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.refresh, color: Colors.white),
                      ),
                      title: Text('Đang tải...'),
                      subtitle: Text(''),
                      trailing: Text(''),
                    );
                  }
                  if (snapshot.hasError) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                      title: const Text('Lỗi'),
                      subtitle: Text('${snapshot.error}'),
                      trailing: const Text(''),
                    );
                  }
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.info, color: Colors.white),
                      ),
                      title: Text('Không có giao dịch'),
                      subtitle: Text(''),
                      trailing: Text(''),
                    );
                  }
                    final giaoDich = snapshot.data![0];
                    // Xác định loại giao dịch dựa vào thuộc tính loaiGiaoDich hoặc collection
                    // Nếu loaiGiaoDich không có hoặc không đúng, fallback dựa vào số tiền dương/âm
                    final isThu = (giaoDich.loaiGiaoDich?.toLowerCase() == 'thu') ||
                      (giaoDich.loaiGiaoDich?.toLowerCase() == 'thu nhập');
                    return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isThu ? const Color(0xFFE8F5E9) : const Color(0xFFFDEDED),
                      child: Icon(
                      isThu ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isThu ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(giaoDich.tenGiaoDich ?? 'Không tên'),
                    subtitle: Text(
                      '${giaoDich.ngayGiaoDich.toLocal().toString().split(' ')[0]} . ${giaoDich.danhMuc ?? ''}',
                    ),
                    trailing: Text(
                      '${isThu ? '+' : '-'}${formatCurrency(giaoDich.soTien.abs())}',
                      style: TextStyle(
                      color: isThu ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      ),
                    ),
                    );
                },
              ),
              const SizedBox(height: 16),
             
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}