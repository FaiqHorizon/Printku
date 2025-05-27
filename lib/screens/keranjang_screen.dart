import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/pengaturan_url.dart';
import 'checkout_screen.dart';

class KeranjangScreen extends StatefulWidget {
  const KeranjangScreen({Key? key}) : super(key: key);

  @override
  State<KeranjangScreen> createState() => _KeranjangScreenState();
}

class _KeranjangScreenState extends State<KeranjangScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    try {
      final response = await http.get(Uri.parse(ApiUrl.getCartItems));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Cart Response: $data'); // For debugging
        
        if (data['items'] != null) {
          setState(() {
            cartItems = List<Map<String, dynamic>>.from(data['items']);
            calculateTotal();
            isLoading = false;
          });
        } else {
          setState(() {
            cartItems = [];
            totalPrice = 0;
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load cart items: ${response.body}');
      }
    } catch (e) {
      print('Error fetching cart: $e'); // For debugging
      setState(() {
        isLoading = false;
        cartItems = [];
        totalPrice = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void calculateTotal() {
    totalPrice = cartItems.fold(0, (sum, item) {
      final price = item['item_price'] ?? item['product_price'] ?? 0.0;
      final quantity = item['quantity'] ?? 1;
      return sum + (double.tryParse(price.toString()) ?? 0.0) * quantity;
    });
  }

  Future<void> updateQuantity(int itemId, int newQuantity) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrl.updateCartQuantity),
        body: {
          'item_id': itemId.toString(),
          'quantity': newQuantity.toString(),
        },
      );

      if (response.statusCode == 200) {
        fetchCartItems();
      } else {
        throw Exception('Failed to update quantity');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrl.removeCartItem),
        body: {
          'item_id': itemId.toString(),
        },
      );

      if (response.statusCode == 200) {
        fetchCartItems();
      } else {
        throw Exception('Failed to remove item');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await fetchCartItems();
              final response = await http.get(Uri.parse(ApiUrl.getCartItems));
              print('Raw response: ${response.body}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () async {
              try {
                final response = await http.post(Uri.parse(ApiUrl.clearCart));
                if (response.statusCode == 200) {
                  fetchCartItems();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Keranjang kosong',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[200],
                                    ),
                                    child: item['image'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.memory(
                                              base64Decode(item['image']),
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(Icons.image, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rp ${((double.tryParse(item['item_price']?.toString() ?? '0') ?? 
                                              double.tryParse(item['product_price']?.toString() ?? '0') ?? 
                                              0.0) * (item['quantity'] ?? 1)).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                                        onPressed: () {
                                          if (item['quantity'] > 1) {
                                            updateQuantity(item['id'], item['quantity'] - 1);
                                          }
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        child: Text(
                                          '${item['quantity']}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                                        onPressed: () {
                                          updateQuantity(item['id'], item['quantity'] + 1);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => removeItem(item['id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total Harga',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Rp ${totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: cartItems.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CheckoutScreen(
                                          cartItems: cartItems,
                                          totalPrice: totalPrice,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,  // Add this line
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
  // Add this method in _KeranjangScreenState class
  Future<void> addToCart(int productId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse(ApiUrl.addToCart),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );
  
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success']) {
        await fetchCartItems(); // Refresh cart after adding
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Item added to cart')),
          );
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}