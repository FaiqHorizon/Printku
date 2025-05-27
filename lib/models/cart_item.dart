class CartItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double price;
  final String? fileUpload;
  int quantity;

  CartItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    this.fileUpload,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      price: double.parse(json['price'].toString()),
      fileUpload: json['file_upload'],
      quantity: json['quantity'],
    );
  }

  double get total => price * quantity;
}