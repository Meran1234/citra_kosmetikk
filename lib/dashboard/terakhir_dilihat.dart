import 'dart:convert';
import 'package:citra_kosmetik/dashboard/keranjang_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahkan ini untuk format Rupiah

class TerakhirDilihat extends StatefulWidget {
  const TerakhirDilihat({super.key});

  @override
  State<TerakhirDilihat> createState() => _TerakhirDilihatState();
}

class _TerakhirDilihatState extends State<TerakhirDilihat> {
  List<Map<String, String>> lastViewedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadLastViewedProducts();
  }

  Future<void> _loadLastViewedProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> lastViewedProductsList =
        prefs.getStringList('lastViewedProducts') ?? [];

    setState(() {
      lastViewedProducts =
          lastViewedProductsList.map((productJson) {
            return Map<String, String>.from(jsonDecode(productJson));
          }).toList();
    });
  }

  String formatRupiah(String nominal) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp.',
      decimalDigits: 0,
    );
    return formatter.format(int.tryParse(nominal) ?? 0);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 7.0),
          child: Text(
            'Terakhir Dilihat',
            style: TextStyle(fontWeight: FontWeight.bold),
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
            onPressed: () => launchWhatsApp(),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body:
          lastViewedProducts.isEmpty
              ? const Center(child: Text('Tidak ada produk yang dilihat'))
              : GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.6,
                ),
                itemCount: lastViewedProducts.length,
                itemBuilder: (context, index) {
                  final product = lastViewedProducts[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigasi ke DetailProduk jika sudah tersedia
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (context) => DetailProduk(product: product),
                      // ));
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Image.network(
                                product['image'] ?? '',
                                width: double.infinity,
                                height: 60,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                  );
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
                                  product['name'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRupiah(product['price'] ?? '0'),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    Text(product['rating'] ?? '4.5'),
                                    const SizedBox(width: 6),
                                    const Text('|'),
                                    const SizedBox(width: 6),
                                    Text('${product['sold'] ?? '10k'} terjual'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (product['cod'] == 'true')
                                      const Icon(
                                        Icons.local_shipping,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
