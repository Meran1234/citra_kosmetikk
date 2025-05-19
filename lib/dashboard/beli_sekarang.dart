import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BeliScreen extends StatefulWidget {
  final String merek;
  final String gambar;
  final int harga;
  final int quantity;

  const BeliScreen({
    super.key,
    required this.merek,
    required this.gambar,
    required this.harga,
    required this.quantity,
  });

  @override
  State<BeliScreen> createState() => _BeliScreenState();
}

class _BeliScreenState extends State<BeliScreen> {
  String id = 'id_user';
  String nama = 'Nama';
  String noTelp = 'No. Telepon';
  List<dynamic> alamatList = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadNama();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      id = prefs.getInt('id_user')?.toString() ?? 'id_user';
    });
    if (id.isNotEmpty) {
      fetchAlamat();
    }
  }

  Future<void> _loadNama() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idUser = prefs.getInt('id_user')?.toString() ?? '';

    if (idUser.isNotEmpty) {
      final dio = Dio();
      try {
        final response = await dio.post(
          'https://citrakosmetik.my.id/get_pembeli.php',
          data: {'id_user': idUser},
          options: Options(
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          ),
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          setState(() {
            nama = response.data['pembeli'][0]['nama'] ?? 'Tidak diketahui';
            noTelp =
                response.data['pembeli'][0]['no_telp'] ??
                'No. Telepon tidak tersedia';
          });
        } else {
          setState(() {
            nama = 'Nama tidak ditemukan';
            noTelp = 'No. Telepon tidak tersedia';
          });
        }
      } catch (e) {
        setState(() {
          nama = 'Error fetching data';
          noTelp = 'Error fetching phone number';
        });
        print('Error: $e');
      }
    }
  }

  Future<void> fetchAlamat() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://citrakosmetik.my.id/get_alamat_user.php?id_user=$id',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          alamatList = jsonDecode(response.body);
        });
      }
    } catch (e) {
      // Optional: tampilkan error
    }
  }

  String formatHarga(int harga) {
    final formatCurrency = NumberFormat(
      '#,###',
      'id_ID',
    ); // Format dengan pemisah ribuan
    return 'Rp. ${formatCurrency.format(harga)}';
  }

  @override
  Widget build(BuildContext context) {
    final int subtotal = widget.harga * widget.quantity;
    final int ongkir = 10000;
    // ignore: unused_local_variable
    final String formattedOngkir = NumberFormat(
      '#,###',
      'id_ID',
    ).format(ongkir);
    final int biayaLayanan = 1000;
    final int totalPembayaran = subtotal + ongkir + biayaLayanan;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(top: 3.0, left: 20.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          'Pembayaran',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Informasi Pengguna
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$nama ($noTelp)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Alamat
                      Text(
                        alamatList.isNotEmpty
                            ? alamatList[0]['jalan'] ?? 'Alamat tidak tersedia'
                            : 'Alamat tidak tersedia',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        ',',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alamatList.isNotEmpty
                            ? alamatList[0]['detail'] ?? 'Detail tidak tersedia'
                            : 'Detail tidak tersedia',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    alamatList.isNotEmpty
                        ? alamatList[0]['alamat'] ?? 'Alamat tidak tersedia'
                        : 'Alamat tidak tersedia',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Produk
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Produk Detail
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        color: Colors.white,
                        child: Image.network(
                          widget.gambar,
                          width: 80,
                          height: 80,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.merek,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatHarga(widget.harga),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "x ${widget.quantity}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Pengiriman
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Opsi Pengiriman"),
                        Text("Pilih >"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Metode Pembayaran
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Metode Pembayaran"),
                        Text("Pilih >"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rincian Pembayaran
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _rincianRow("Subtotal Produk", subtotal),
                        _rincianRow("Subtotal Pengiriman", ongkir),
                        _rincianRow("Biaya Layanan", biayaLayanan),
                        const Divider(),
                        _rincianRow(
                          "Total Pembayaran",
                          totalPembayaran,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
        decoration: const BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Pesanan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatHarga(totalPembayaran),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Tambahkan aksi di sini
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Pesan Sekarang",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rincianRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "Rp. ${NumberFormat('#,###', 'id_ID').format(value)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
