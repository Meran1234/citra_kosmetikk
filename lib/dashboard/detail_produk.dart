import 'dart:convert';

import 'package:citra_kosmetik/dashboard/beli_sekarang.dart';
import 'package:citra_kosmetik/dashboard/dashboard_screen.dart';
import 'package:citra_kosmetik/dashboard/favorite_screen.dart';
import 'package:citra_kosmetik/dashboard/keranjang_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailProduk extends StatefulWidget {
  final Product product;

  const DetailProduk({super.key, required this.product});

  @override
  State<DetailProduk> createState() => _DetailProdukState();
}

class _DetailProdukState extends State<DetailProduk> {
  bool isFavorited = false;
  String formatRupiah(String nominal) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp.',
      decimalDigits: 0,
    );
    return formatter.format(int.tryParse(nominal) ?? 0);
  }

  String id = 'id_user';
  final List<Product> favoriteProducts = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _checkIfInFavorites();
    _saveLastViewedProduct(widget.product);
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getInt('id_user')?.toString() ?? 'id_user';

    if (userId != 'id_user') {
      setState(() {
        id = userId;
      });
      await _checkIfInFavorites(); // Pastikan dipanggil setelah ID pasti valid
    }
  }

  Future<void> _saveLastViewedProduct(Product product) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> lastViewedProducts =
        prefs.getStringList('lastViewedProducts') ?? [];

    // Encode produk yang baru
    Map<String, String> productMap = {
      'id': product.id,
      'name': product.merek,
      'image': product.gambar.isNotEmpty ? product.gambar[0] : '',
      'price': product.harga,
    };
    String productJson = jsonEncode(productMap);

    // Hapus jika produk ini sudah ada di daftar sebelumnya
    lastViewedProducts.removeWhere((item) {
      final existing = jsonDecode(item);
      return existing['id'] == product.id;
    });

    // Tambahkan produk baru di awal list
    lastViewedProducts.insert(0, productJson);

    // Simpan ulang
    await prefs.setStringList('lastViewedProducts', lastViewedProducts);
  }

  Future<void> _checkIfInFavorites() async {
    try {
      final dio = Dio();

      final response = await dio.get(
        'https://citrakosmetik.my.id/check_favorite.php',
        queryParameters: {'id_produk': widget.product.id, 'id_user': id},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print("Produk sudah ada di favorit"); // Log untuk debugging
        setState(() {
          isFavorited = true;
        });
      } else {
        print("Produk tidak ada di favorit"); // Log untuk debugging
        setState(() {
          isFavorited = false;
        });
      }
    } catch (e) {
      print("Terjadi kesalahan: $e");
    }
  }

  Future<void> _tambahKeKeranjangDio({
    required int id,
    required String merek,
    required int quantity,
    required int idUser,
  }) async {
    try {
      final dio = Dio();

      final response = await dio.post(
        'https://citrakosmetik.my.id/insert_keranjang.php',
        data: {
          'id_produk': id.toString(),
          'merek': merek,
          'quantity': quantity.toString(),
          'id_user': idUser.toString(),
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk ditambahkan ke keranjang')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan: ${response.data['message']}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> _tambahKeFavorite({
    required int id,
    required String merek,
    required int harga,
    required int idUser,
  }) async {
    try {
      final dio = Dio();

      final response = await dio.post(
        'https://citrakosmetik.my.id/insert_favorite.php',
        data: {
          'id_produk': id.toString(),
          'merek': merek,
          'harga': harga.toString(),
          'id_user': idUser.toString(),
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk dimasukkan ke favorite')),
        );
        // Refresh favorite status after adding to favorites
        _checkIfInFavorites();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan: ${response.data['message']}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }

  Future<void> launchWhatsApp({
    String phoneNumber = '6289617833718',
    required String gambar,
    required String harga,
    required String merek,
  }) async {
    final String message = Uri.encodeFull(
      'Halo, saya tertarik pada produk berikut:\n\n'
      'Merek: $merek\n'
      'Harga: $harga\n\n'
      'Gambar produk: $gambar\n\n'
      'Terima kasih!',
    );

    final Uri url = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Gagal membuka WhatsApp");
      throw 'Tidak bisa membuka WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => KeranjangScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                child: SizedBox(
                  height: 400,
                  child: PageView.builder(
                    itemCount: widget.product.gambar.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.product.gambar[index],
                        width: 400,
                        height: 400,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 80),
                      );
                    },
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text('Harga', style: TextStyle(color: Colors.grey[700])),
                      Row(
                        children: [
                          Text(
                            formatRupiah(widget.product.harga),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.product.merek,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.orange, size: 18),
                          Text(' 4.9'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Deskripsi',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          text: widget.product.deskripsi,
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(
                        isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_border,
                        color: Colors.pink,
                      ),
                      onPressed: () {
                        if (id != 'id_user') {
                          setState(() {
                            isFavorited = !isFavorited; // langsung ubah status
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoriteScreen(),
                            ),
                          );
                          _tambahKeFavorite(
                            id: int.parse(widget.product.id),
                            merek: widget.product.merek,
                            harga: int.parse(widget.product.harga),
                            idUser: int.parse(id),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User belum login')),
                          );
                        }
                      },
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                launchWhatsApp(
                  phoneNumber: '6289617833718',
                  gambar:
                      widget.product.gambar.isNotEmpty
                          ? widget.product.gambar[0]
                          : '',
                  harga: formatRupiah(
                    widget.product.harga,
                  ), // Harga produk yang diformat
                  merek: widget.product.merek, // Merek produk
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 5),
            // Tombol keranjang bawah - show bottom sheet
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  builder: (BuildContext context) {
                    int quantity = 1;
                    return StatefulBuilder(
                      builder: (context, setModalState) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      widget.product.gambar.isNotEmpty
                                          ? widget.product.gambar[0]
                                          : '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatRupiah(widget.product.harga),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stok: ${widget.product.stok}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Text(
                                    'Jumlah',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setModalState(() => quantity--);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (quantity <
                                          int.parse(widget.product.stok)) {
                                        setModalState(() => quantity++);
                                      }
                                    },

                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    if (id != 'id_user') {
                                      _tambahKeKeranjangDio(
                                        id: int.parse(widget.product.id),
                                        merek: widget.product.merek,
                                        quantity: quantity,
                                        idUser: int.parse(id),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'User ID tidak ditemukan',
                                          ),
                                        ),
                                      );
                                    }
                                  },

                                  child: const Text(
                                    'Masukan Keranjang',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25.0),
                    ),
                  ),
                  builder: (BuildContext context) {
                    int quantity = 1;
                    return StatefulBuilder(
                      builder: (context, setModalState) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.lightBlue,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      widget.product.gambar.isNotEmpty
                                          ? widget.product.gambar[0]
                                          : '',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatRupiah(widget.product.harga),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stok: ${widget.product.stok}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Text(
                                    'Jumlah',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      if (quantity > 1) {
                                        setModalState(() => quantity--);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (quantity <
                                          int.parse(widget.product.stok)) {
                                        setModalState(() => quantity++);
                                      }
                                    },

                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => BeliScreen(
                                              merek: widget.product.merek,
                                              gambar:
                                                  widget
                                                          .product
                                                          .gambar
                                                          .isNotEmpty
                                                      ? widget.product.gambar[0]
                                                      : '',
                                              harga: int.parse(
                                                widget.product.harga,
                                              ),
                                              quantity: quantity,
                                            ),
                                      ),
                                    );
                                  },

                                  child: const Text(
                                    'Beli sekarang',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                child: Text(
                  'Beli Sekarang',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
