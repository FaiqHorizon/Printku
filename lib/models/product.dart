import 'dart:convert';
import 'dart:typed_data';

class Product {
  final int id;
  final int? categoryId;
  final String name;
  final String? description;
  final double price;
  final Uint8List? imageBytes;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageBytes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.parse(json['id'].toString()),
      categoryId: json['category_id'] != null ? int.parse(json['category_id'].toString()) : null,
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      imageBytes: json['image'] != null ? base64Decode(json['image']) : null,
    );
  }
}