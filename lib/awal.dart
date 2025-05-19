import 'dart:async';
import 'package:citra_kosmetik/dashboard_awal.dart';
import 'package:flutter/material.dart';

class Awal extends StatefulWidget {
  const Awal({super.key});

  @override
  State<Awal> createState() => _AwalState();
}

class _AwalState extends State<Awal> {
  int _currentLogoIndex = 0;
  List<String> logos = ['assets/c1.png', 'assets/c2.png', 'assets/ck.png'];
  late Timer _timer;
  List<int> logoDurations = [
    1,
    1,
    2,
  ]; // Durasi dalam detik untuk masing-masing gambar

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(
      Duration(seconds: logoDurations[_currentLogoIndex]),
      (timer) {
        if (_currentLogoIndex < logos.length - 1) {
          setState(() {
            _currentLogoIndex++;
          });
          _timer.cancel();
          _startTimer(); // Mulai timer baru dengan durasi yang berbeda
        } else {
          _timer.cancel();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => DashboardAwal()),
            (route) => false,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel(); // Pastikan timer dihentikan saat widget dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih
      body: Center(
        child: Container(
          alignment: Alignment.center, // Posisi gambar di tengah layar
          child: Hero(
            tag: "Logo",
            child: Image.asset(
              logos[_currentLogoIndex],
              width: 300, // Ukuran gambar yang dapat disesuaikan
              height: 300, // Ukuran gambar yang dapat disesuaikan
              fit: BoxFit.contain, // Mengatur cara gambar mengisi ruang
            ),
          ),
        ),
      ),
    );
  }
}
