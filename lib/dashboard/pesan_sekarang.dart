import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:midtrans_sdk/midtrans_sdk_config.dart';

class PesanSekarang extends StatefulWidget {
  final List<Map<String, dynamic>> selectedProducts;

  const PesanSekarang({super.key, required this.selectedProducts});

  @override
  State<PesanSekarang> createState() => _PesanSekarangState();
}

class _PesanSekarangState extends State<PesanSekarang> {
  String id = 'id_user';
  String nama = 'Nama';
  String noTelp = 'No. Telepon';
  String email = 'Email';
  late MidtransSDK _midtrans;
  List<dynamic> alamatList = [];

  @override
  void initState() {
    super.initState();
    _initMidtrans();
    _loadUserId();
    _loadNama();
  }

  void _initMidtrans() {
    _midtrans = MidtransSDK(
      config: MidtransSDKConfig(
        clientKey: 'SB-Mid-client-6NQoukLlipWjPKHi',
        merchantBaseUrl: 'https://citrakosmetik.my.id/create_payment.php',
        enableLog: true,
        environment: MidtransEnvironment.sandbox,
      ),
    );
    _midtrans.setTransactionFinishedCallback((result) {
      print('Transaction finished: ${result.toJson()}');
    });
  }

  void _startPayment(String snapToken) async {
    try {
      await _midtrans.startPaymentUiFlow(token: snapToken);
    } catch (e) {
      print("Error launching payment: $e");
    }
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
            noTelp = response.data['pembeli'][0]['no_telp'] ??
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
      print('Gagal mengambil alamat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int ongkir = 10000;
    final int biayaLayanan = 1000;
    double totalPrice = widget.selectedProducts.fold(
      0.0,
      (sum, item) =>
          sum +
          (double.tryParse(item['harga'].toString()) ?? 0.0) *
              (int.tryParse(item['quantity'].toString()) ?? 0),
    );

    double totalPembayaran = totalPrice + ongkir + biayaLayanan;
    String formattedPrice = NumberFormat('#,###', 'id_ID').format(totalPrice);
    String formattedTotalPembayaran = NumberFormat(
      '#,###',
      'id_ID',
    ).format(totalPembayaran);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(top: 3.0, left: 20.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
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
                      Text(
                        alamatList.isNotEmpty
                            ? alamatList[0]['jalan'] ?? 'Alamat tidak tersedia'
                            : 'Alamat tidak tersedia',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const Text(', ', style: TextStyle(color: Colors.white)),
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

            // Produk dan Pembayaran
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
                  widget.selectedProducts.isEmpty
                      ? const Center(
                          child: Text('Tidak ada produk yang dipilih'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.selectedProducts.length,
                          itemBuilder: (context, index) {
                            final item = widget.selectedProducts[index];
                            final imageUrl = item['gambar'].isNotEmpty
                                ? item['gambar'][0]
                                : '';
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: imageUrl.isNotEmpty
                                  ? Container(
                                      width: 60, // Ukuran gambar
                                      height: 150, // Ukuran gambar
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      color: Colors.white,
                                    ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['merek'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Rp. ${NumberFormat('#,###', 'id_ID').format(item['harga'])}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "x ${item['quantity']}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 12),

                  // Pengiriman
                  _pilihanItem("Opsi Pengiriman"),
                  const SizedBox(height: 10),

                  // Metode Pembayaran
                  _pilihanItem("Metode Pembayaran"),
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
                        _rincianRow("Subtotal Produk", 'Rp. $formattedPrice'),
                        _rincianRow(
                          "Subtotal Pengiriman",
                          'Rp. ${NumberFormat('#,###', 'id_ID').format(ongkir)}',
                        ),
                        _rincianRow(
                          "Biaya Layanan",
                          'Rp. ${NumberFormat('#,###', 'id_ID').format(biayaLayanan)}',
                        ),
                        const Divider(),
                        _rincianRow(
                          "Total Pembayaran",
                          'Rp. $formattedTotalPembayaran',
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
                  'Rp. $formattedTotalPembayaran',
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
                  onPressed: () async {
                    try {
                      final idUser = id;
                      final namaPembeli = nama;
                      final noTelpPembeli = noTelp;
                      final emailPembeli = email; // Jika ada, ambil dari DB
                      final alamatPembeli = alamatList.isNotEmpty
                          ? alamatList[0]['alamat'] ?? ''
                          : '';

                      final produk = widget.selectedProducts
                          .map((item) => {
                                'id_produk':
                                    item['id_produk'] ?? item['id'] ?? '',
                                'jumlah': item['quantity'],
                              })
                          .toList();

                      final totalPembayaran =
                          widget.selectedProducts.fold<double>(
                        0,
                        (total, item) =>
                            total +
                            (double.tryParse(item['harga'].toString()) ?? 0.0) *
                                (item['quantity'] ?? 1),
                      );

                      final body = {
                        'id_user': idUser,
                        'total': totalPembayaran,
                        'nama': namaPembeli,
                        'email': emailPembeli,
                        'no_telp': noTelpPembeli,
                        'alamat': alamatPembeli,
                        'produk': produk,
                      };

                      final response = await http.post(
                        Uri.parse(
                            'https://citrakosmetik.my.id/create_payment.php'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(body),
                      );

                      if (response.statusCode == 200) {
                        final data = jsonDecode(response.body);
                        if (data['status'] == 'success') {
                          final snapToken = data['snap_token'];
                          if (snapToken != null && snapToken.isNotEmpty) {
                            _startPayment(snapToken);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Gagal mendapatkan Snap Token")),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(data['message'] ?? 'Error transaksi')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("Server error: ${response.statusCode}")),
                        );
                      }
                    } catch (e) {
                      print("Error: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Terjadi kesalahan saat proses pembayaran")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
                  ),
                  child: const Text(
                    "Bayar Sekarang",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _rincianRow(String label, String value, {bool isBold = false}) {
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
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihanItem(String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), const Text("Pilih >")],
      ),
    );
  }
}
