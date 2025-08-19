// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class TaiKhoanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TÀI KHOẢN',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
      ),
      body: Center(
        child: Text(
          'Trang Tài Khoản',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}