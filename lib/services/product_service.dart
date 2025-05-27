import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/pengaturan_url.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductService {
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('${ApiUrl.baseUrl}/get_categories.php'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getProducts({int? categoryId}) async {
    try {
      final url = categoryId != null 
          ? '${ApiUrl.baseUrl}/get_products.php?category_id=$categoryId'
          : '${ApiUrl.baseUrl}/get_products.php';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}