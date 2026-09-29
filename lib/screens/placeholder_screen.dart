import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/button_navbar.dart';

// Dipakai sementara untuk 3 fitur yang dikerjakan anggota tim lain
class PlaceholderScreen extends StatelessWidget {
  final String judul;
  final int navIndex;

  const PlaceholderScreen({super.key, required this.judul, required this.navIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        title: Text(judul, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('Fitur "$judul" sedang dikerjakan tim lain',
            style: const TextStyle(color: AppColors.textGrey)),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: navIndex),
    );
  }
}