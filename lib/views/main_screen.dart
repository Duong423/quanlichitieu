// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'nhacNhoChiTieu-screen.dart';
import 'themGiaoDich-screen.dart';
import 'trangChu-screen.dart';
import 'tatCaGiaoDich-screen.dart';
import 'taiKhoan-screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Chỉ số tab hiện tại
  final List<Widget> _screens = [
    TrangChuScreen(),
    TatCaGiaoDichScreen(),
    ThemGiaoDichScreen(),
    NhacNhoChiTieuScreen(),
    TaiKhoanScreen(),
    
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[
          _selectedIndex], // Hiển thị trang tương ứng với tab được chọn
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt), label: 'Giao dịch'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add), label: 'Thêm'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Nhắc nhở'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
