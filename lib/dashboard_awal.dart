import 'package:citra_kosmetik/profile_awal.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'login_screen.dart'; // Mengimpor LoginScreen

class Product {
  final String id;
  final String merek;
  final String harga;
  final List<String> gambar; // Mengubah tipe gambar menjadi List<String>
  final String kategori;

  Product({
    required this.id,
    required this.merek,
    required this.harga,
    required this.gambar,
    required this.kategori,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Ambil array gambar dari JSON
    var gambarList = List<String>.from(json['gambar'] ?? []);

    return Product(
      id: json['id_produk'] ?? '',
      merek: json['merek'] ?? '',
      harga: json['harga'] ?? '',
      gambar: gambarList,
      kategori: json['kategori'] ?? '',
    );
  }
}

class DashboardAwal extends StatefulWidget {
  const DashboardAwal({super.key});

  @override
  State<DashboardAwal> createState() => _DashboardAwalState();
}

class _DashboardAwalState extends State<DashboardAwal> {
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
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      final response = await Dio().get(
        'https://citrakosmetik.my.id/get_produk.php',
      );
      List data = response.data;
      setState(() {
        products = data.map((json) => Product.fromJson(json)).toList();
        filteredProducts = products; // Menampilkan semua produk awalnya
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // HILANGKAN PANAH KEMBALI
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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
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
            // Tetap di Home
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileAwal()),
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
  String formatRupiah(String harga) {
    final number = int.tryParse(harga) ?? 0;
    String result = '';
    String angka = number.toString();
    int count = 0;

    for (int i = angka.length - 1; i >= 0; i--) {
      result = angka[i] + result;
      count++;
      if (count % 3 == 0 && i != 0) {
        result = '.' + result;
      }
    }
    return result;
  }

  final Product product;

  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
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
                        'Rp ${formatRupiah(product.harga)}',
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
