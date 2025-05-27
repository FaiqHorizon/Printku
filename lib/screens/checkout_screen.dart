import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import '../config/pengaturan_url.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  File? _paymentProof;
  Uint8List? _webPaymentProof;
  String? _fileName;
  bool _isLoading = false;
  double _shippingCost = 10000;

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web platform image picking
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
          allowMultiple: false,
        );

        if (result != null) {
          setState(() {
            _webPaymentProof = result.files.first.bytes;
            _fileName = result.files.first.name;
          });
        }
      } else {
        // Mobile platform image picking
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          final bytes = await image.readAsBytes();
          setState(() {
            _paymentProof = File(image.path);
            _webPaymentProof = bytes;
            _fileName = image.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Widget _buildOrderSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                final price = double.tryParse(item['product_price']?.toString() ?? '0') ?? 0.0;
                final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                final total = price * quantity;
                
                return ListTile(
                  title: Text(item['name'] ?? 'Unnamed Product'),
                  subtitle: Text('${quantity}x  Rp ${price.toStringAsFixed(0)}'),
                  trailing: Text(
                    'Rp ${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            const Divider(),
            _buildPriceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final totalWithShipping = widget.totalPrice + _shippingCost;
    return Column(
      children: [
        ListTile(
          title: const Text('Subtotal'),
          trailing: Text('Rp ${widget.totalPrice.toStringAsFixed(0)}'),
        ),
        ListTile(
          title: const Text('Biaya Pengiriman'),
          trailing: Text('Rp ${_shippingCost.toStringAsFixed(0)}'),
        ),
        ListTile(
          title: const Text(
            'Total',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            'Rp ${totalWithShipping.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentProofSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bukti Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_webPaymentProof != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.memory(_webPaymentProof!, fit: BoxFit.cover),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _paymentProof = null;
                  _webPaymentProof = null;
                  _fileName = null;
                }),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48),
                  Text('Upload Bukti Pembayaran'),
                ],
              ),
            ),
          ),
        if (_fileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'File: $_fileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || _webPaymentProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(ApiUrl.createOrder));
      final totalWithShipping = widget.totalPrice + _shippingCost;

      request.fields.addAll({
        'shipping_address': _addressController.text,
        'total_amount': totalWithShipping.toString(),
        'shipping_cost': _shippingCost.toString(),
      });

      // Add payment proof for both platforms
      request.files.add(
        http.MultipartFile.fromBytes(
          'payment_proof',
          _webPaymentProof!,
          filename: _fileName ?? 'payment_proof.jpg',
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat!')),
        );
      } else {
        throw Exception(jsonResponse['message'] ?? 'Gagal membuat pesanan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ringkasan Pesanan',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Rekening Pembayaran:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'BCA - 12345678 - Ardi Herdiana',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: widget.cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = widget.cartItems[index];
                                  final price = double.tryParse(item['product_price']?.toString() ?? '0') ?? 0.0;
                                  final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                                  final total = price * quantity;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['name'] ?? 'Unnamed Product',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '${quantity}x  Rp ${price.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Rp ${total.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 24),
                              _buildPriceSummary(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _addressController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Alamat Pengiriman',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Mohon masukkan alamat pengiriman';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              _buildPaymentProofSection(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Buat Pesanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}