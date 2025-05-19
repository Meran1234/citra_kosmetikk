import 'package:citra_kosmetik/dashboard/pesan_sekarang.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({super.key});

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  List<Map<String, dynamic>> keranjangItems = [];
  String idUser = '';
  int totalItems = 0;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('id_user')?.toString() ?? '';
    });

    if (idUser.isNotEmpty) {
      _fetchKeranjang();
    }
  }

  Future<void> _fetchKeranjang() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://citrakosmetik.my.id/get_keranjang.php',
        data: {'id_user': idUser},
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        List<Map<String, dynamic>> originalItems =
            List<Map<String, dynamic>>.from(response.data['keranjang']);

        // Kelompokkan berdasarkan merek dan jumlahkan quantity
        Map<String, Map<String, dynamic>> grouped = {};

        for (var item in originalItems) {
          String merek = item['merek'];
          int quantity = int.tryParse(item['quantity'].toString()) ?? 0;
          double harga = double.tryParse(item['harga'].toString()) ?? 0.0;

          if (grouped.containsKey(merek)) {
            grouped[merek]!['quantity'] += quantity;
          } else {
            grouped[merek] = {
              'merek': merek,
              'harga': harga,
              'quantity': quantity,
              'isChecked': false, // default: dicentang
              'gambar': item['gambar'], // add gambar field
            };
          }
        }

        setState(() {
          keranjangItems = grouped.values.toList();
          _updateTotal(); // Hitung berdasarkan yang dicentang
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${response.data['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  void _updateTotal() {
    final checkedItems =
        keranjangItems.where((item) => item['isChecked'] == true).toList();

    if (checkedItems.isEmpty) {
      totalItems = 0;
      totalPrice = 0.0;
    } else {
      totalItems = checkedItems.fold(
        0,
        (sum, item) => sum + (int.tryParse(item['quantity'].toString()) ?? 0),
      );

      totalPrice = checkedItems.fold(
        0.0,
        (sum, item) =>
            sum +
            ((double.tryParse(item['harga'].toString()) ?? 0.0) *
                (int.tryParse(item['quantity'].toString()) ?? 0)),
      );
    }

    setState(() {});
  }

  String formatRupiah(double harga) {
    final formatCurrency = NumberFormat('#,###', 'id_ID');
    return 'Rp. ${formatCurrency.format(harga)}';
  }

  @override
  Widget build(BuildContext context) {
    String formattedPrice = NumberFormat('#,###', 'id_ID').format(totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keranjang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          keranjangItems.isEmpty
              ? const Center(
                child: Text(
                  'Keranjang Kosong',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: keranjangItems.length,
                      itemBuilder: (context, index) {
                        final item = keranjangItems[index];
                        return cartItem(
                          index,
                          item['merek'],
                          formatRupiah(
                            double.tryParse(item['harga'].toString()) ?? 0.0,
                          ),
                          item['quantity'],
                          item['isChecked'],
                          item['gambar'],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.lightBlue,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jumlah Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$totalItems Item',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pesanan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp. $formattedPrice',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            List<Map<String, dynamic>> selectedItems =
                                keranjangItems
                                    .where((item) => item['isChecked'] == true)
                                    .toList();

                            if (selectedItems.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PesanSekarang(
                                        selectedProducts: selectedItems,
                                      ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pilih produk terlebih dahulu!',
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            minimumSize: const Size(450, 50),
                          ),
                          child: const Text('Buat Pesanan'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget cartItem(
    int index,
    String title,
    String price,
    int quantity,
    bool isChecked,
    List gambar,
  ) {
    final imageUrl = gambar.isNotEmpty ? gambar[0] : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          gambar.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Placeholder(
                        fallbackWidth: 80,
                        fallbackHeight: 80,
                      ),
                ),
              )
              : const Placeholder(fallbackWidth: 80, fallbackHeight: 80),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(price, style: const TextStyle(color: Colors.white)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        int currentQuantity =
                            keranjangItems[index]['quantity'] ?? 0;

                        if (currentQuantity > 1) {
                          int newQuantity = currentQuantity - 1;

                          setState(() {
                            keranjangItems[index]['quantity'] = newQuantity;
                            _updateTotal();
                          });

                          try {
                            final dio = Dio();
                            final response = await dio.post(
                              'https://citrakosmetik.my.id/update_keranjang.php',
                              data: {
                                'id_user': idUser,
                                'merek': keranjangItems[index]['merek'],
                                'quantity': newQuantity.toString(),
                              },
                              options: Options(
                                headers: {
                                  'Content-Type':
                                      'application/x-www-form-urlencoded',
                                },
                              ),
                            );

                            if (response.data['success'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Quantity berhasil diperbarui'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal memperbarui quantity: ${response.data['message']}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Terjadi kesalahan: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.remove, color: Colors.white),
                    ),
                    Text(
                      '${keranjangItems[index]['quantity']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () async {
                        int newQuantity =
                            (keranjangItems[index]['quantity'] ?? 0) + 1;

                        setState(() {
                          keranjangItems[index]['quantity'] = newQuantity;
                          _updateTotal();
                        });

                        try {
                          final dio = Dio();
                          final response = await dio.post(
                            'https://citrakosmetik.my.id/update_keranjang.php',
                            data: {
                              'id_user': idUser,
                              'merek': keranjangItems[index]['merek'],
                              'quantity': newQuantity.toString(),
                            },
                            options: Options(
                              headers: {
                                'Content-Type':
                                    'application/x-www-form-urlencoded',
                              },
                            ),
                          );

                          if (response.data['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Quantity berhasil diperbarui'),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal memperbarui quantity: ${response.data['message']}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Terjadi kesalahan: $e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    keranjangItems[index]['isChecked'] = value;
                    _updateTotal();
                  });
                },
              ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Konfirmasi"),
                        content: const Text("Hapus item dari keranjang?"),
                        actions: [
                          TextButton(
                            child: const Text("Batal"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text("Hapus"),
                            onPressed: () async {
                              try {
                                final dio = Dio();
                                final response = await dio.post(
                                  'https://citrakosmetik.my.id/delete_keranjang.php',
                                  data: {
                                    'id_user': idUser,
                                    'merek': keranjangItems[index]['merek'],
                                  },
                                  options: Options(
                                    headers: {
                                      'Content-Type':
                                          'application/x-www-form-urlencoded',
                                    },
                                  ),
                                );

                                if (response.data['success'] == true) {
                                  setState(() {
                                    keranjangItems.removeAt(index);
                                    _updateTotal();
                                  });
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response.data['message'],
                                      ), // Menampilkan pesan yang sesuai
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response.data['message']),
                                    ),
                                  );
                                }
                              } catch (e) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
