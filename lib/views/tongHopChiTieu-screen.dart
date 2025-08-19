import 'package:flutter/material.dart';
import '../controllers/tongHopChiTieu_controller.dart';
import '../models/chiTieuTheoThang_model.dart';

class TongHopChiTieuScreen extends StatefulWidget {
  @override
  _TongHopChiTieuScreenState createState() => _TongHopChiTieuScreenState();
}

class _TongHopChiTieuScreenState extends State<TongHopChiTieuScreen> {
  final TongHopChiTieuController _controller = TongHopChiTieuController();
  List<ChiTieuTheoThang> _lichSuChiTieu = [];
  Map<String, dynamic>? _phanTichXuHuong;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tạo dữ liệu mẫu nếu chưa có
      await _controller.taoDataMauNeuCan();
      
      // Tạo tổng hợp cho 6 tháng gần nhất
      List<ChiTieuTheoThang> tongHop = await _controller.soSanhChiTieuTheoThang(6);
      Map<String, dynamic> xuHuong = await _controller.phanTichXuHuong();

      setState(() {
        _lichSuChiTieu = tongHop;
        _phanTichXuHuong = xuHuong;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Lỗi chi tiết: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải dữ liệu: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'),
      (Match m) => '${m[1]}.',
    )} đ';
  }

  Color _getXuHuongColor(String xuHuong) {
    switch (xuHuong) {
      case 'tang_manh':
        return Colors.red;
      case 'tang_nhe':
        return Colors.orange;
      case 'giam_manh':
        return Colors.green;
      case 'giam_nhe':
        return Colors.blue;
      case 'on_dinh':
        return Colors.grey;
      case 'insufficient_data':
        return Colors.amber;
      case 'error':
        return Colors.red[300]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getXuHuongIcon(String xuHuong) {
    switch (xuHuong) {
      case 'tang_manh':
      case 'tang_nhe':
        return Icons.trending_up;
      case 'giam_manh':
      case 'giam_nhe':
        return Icons.trending_down;
      case 'on_dinh':
        return Icons.trending_flat;
      case 'insufficient_data':
        return Icons.info_outline;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TỔNG HỢP CHI TIÊU',
          style: TextStyle(color: Colors.white),
          
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card xu hướng
                  if (_phanTichXuHuong != null) ...[
                    _buildXuHuongCard(_phanTichXuHuong!),
                    SizedBox(height: 16),
                  ],

                  // Tổng hợp tháng hiện tại
                  if (_lichSuChiTieu.isNotEmpty) ...[
                    _buildThangHienTaiCard(_lichSuChiTieu.first),
                    SizedBox(height: 16),
                  ],

                  // Lịch sử so sánh
                  Text(
                    'So sánh theo tháng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  
                  ..._lichSuChiTieu.map((chiTieu) => _buildChiTieuCard(chiTieu)),
                ],
              ),
            ),
    );
  }

  Widget _buildXuHuongCard(Map<String, dynamic> xuHuong) {
    String trend = xuHuong['xuHuong'] ?? 'error';
    String message = xuHuong['thongDiep'] ?? 'Không có dữ liệu';
    double phanTram = (xuHuong['phanTramThayDoi'] ?? 0.0).toDouble();

    return Card(
      color: _getXuHuongColor(trend).withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getXuHuongIcon(trend),
                  color: _getXuHuongColor(trend),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Xu hướng chi tiêu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getXuHuongColor(trend),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14),
            ),
            if (phanTram != 0 && trend != 'error' && trend != 'insufficient_data') ...[
              SizedBox(height: 4),
              Text(
                '${phanTram > 0 ? '+' : ''}${phanTram.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getXuHuongColor(trend),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThangHienTaiCard(ChiTieuTheoThang chiTieu) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tháng ${chiTieu.thang}/${chiTieu.nam}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 12),
            _buildChiTietRow('Chi tiêu thực tế:', chiTieu.chiTieuThucTe, Colors.red),
            _buildChiTietRow('Ngân sách đã dùng:', chiTieu.nganSachDaDung, Colors.orange),
            _buildChiTietRow('Chi tiêu hoàn thành:', chiTieu.chiTieuHoanThanh, Colors.green),
            Divider(),
            _buildChiTietRow('TỔNG CHI:', chiTieu.tongChi, Colors.blue[800]!, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildChiTietRow(String label, double amount, Color? color, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChiTieuCard(ChiTieuTheoThang chiTieu) {
    bool isCurrentMonth = DateTime.now().month == chiTieu.thang && 
                          DateTime.now().year == chiTieu.nam;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: isCurrentMonth ? Colors.blue[50] : null,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tháng ${chiTieu.thang}/${chiTieu.nam}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentMonth ? Colors.blue[800] : null,
                  ),
                ),
                Text(
                  _formatCurrency(chiTieu.tongChi),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chi thực tế: ${_formatCurrency(chiTieu.chiTieuThucTe)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Ngân sách: ${_formatCurrency(chiTieu.nganSachDaDung)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'Hoàn thành: ${_formatCurrency(chiTieu.chiTieuHoanThanh)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
