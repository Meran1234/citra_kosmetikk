import 'package:citra_kosmetik/dashboard/detail_produk.dart';
import 'package:citra_kosmetik/dashboard/favorite_screen.dart';
import 'package:citra_kosmetik/dashboard/keranjang_screen.dart';
import 'package:citra_kosmetik/dashboard/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Product {
  final String id;
  final String merek;
  final String harga;
  final List<String> gambar;
  final String kategori;
  final String deskripsi;
  final String stok;

  Product({
    required this.id,
    required this.merek,
    required this.harga,
    required this.gambar,
    required this.kategori,
    required this.deskripsi,
    required this.stok,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var gambarList = List<String>.from(json['gambar'] ?? []);
    return Product(
      id: json['id_produk'] ?? '',
      merek: json['merek'] ?? '',
      harga: json['harga'] ?? '',
      gambar: gambarList,
      kategori: json['kategori'] ?? '',
      deskripsi: json['deskripsi'],
      stok: json['stok'] ?? '',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String id = 'id_user';
  final List<Map<String, String>> categories = [
    {"name": "Skincare", "image": "assets/icons/sunscreen.png"},
    {"name": "Perawatan Wajah", "image": "assets/icons/cleanser.png"},
    {"name": "Makeup Wajah", "image": "assets/icons/makeup.png"},
    {"name": "Makeup Mata", "image": "assets/icons/mata.png"},
    {"name": "Haircare", "image": "assets/icons/body_skincare.png"},
  ];

  List<Product> products = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  bool isError = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchProducts();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      id =
          prefs.getInt('id_user')?.toString() ??
          'id_user'; // Optional: convert to string if needed
    });
  }

  Future<void> fetchProducts() async {
    try {
      final response = await Dio().get(
        'https://citrakosmetik.my.id/get_produk.php',
      );
      List data = response.data;
      setState(() {
        products = data.map((json) => Product.fromJson(json)).toList();
        filteredProducts = products;
        isLoading = false;
        isError = false;
      });
    } catch (e) {
      print('Gagal mengambil data produk: $e');
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  void filterProductsByCategory(String category) {
    setState(() {
      filteredProducts =
          products
              .where(
                (product) => product.kategori.toLowerCase().contains(
                  category.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  void filterProducts(String query) {
    setState(() {
      searchQuery = query;
      filteredProducts =
          products
              .where(
                (product) =>
                    product.merek.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  Future<void> launchWhatsApp([String phoneNumber = '6289617833718']) async {
    final Uri url = Uri.parse('https://wa.me/$phoneNumber');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Gagal membuka WhatsApp");
      throw 'Tidak bisa membuka WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: 40,
          child: TextField(
            onChanged: filterProducts,
            decoration: InputDecoration(
              hintText: "Cari produk...",
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
            ),
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
          IconButton(
            icon: const Icon(Icons.chat_bubble_rounded),
            onPressed: () {
              launchWhatsApp('6289617833718');
            },
          ),
          SizedBox(width: 5),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : isError
              ? const Center(
                child: Text(
                  'Gagal memuat produk. Silakan coba lagi.',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kategori",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            categories
                                .map(
                                  (category) => CategoryItem(
                                    name: category["name"]!,
                                    image: category["image"]!,
                                    onTap: () {
                                      filterProductsByCategory(
                                        category["name"]!,
                                      );
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.7,
                            ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return ProductItem(product: filteredProducts[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
          } else if (index == 1) {
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoriteScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
        selectedItemColor: Color.fromARGB(255, 54, 171, 244),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String name;
  final String image;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.name,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Image.asset(image, width: 50, height: 50, fit: BoxFit.contain),
            const SizedBox(height: 5),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductItem extends StatelessWidget {
  String formatRupiah(String nominal) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp.', // Tambahkan titik di sini
      decimalDigits: 0,
    );
    return formatter.format(int.tryParse(nominal) ?? 0);
  }

  final Product product;

  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailProduk(product: product),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Image.network(
                  product.gambar.isNotEmpty
                      ? product.gambar[0]
                      : '', // Menampilkan gambar pertama
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 60);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.merek,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        formatRupiah(product.harga),
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: const [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('4.8 | 10k terjual', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
