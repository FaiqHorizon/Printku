class ApiUrl {
  static const String baseUrl = "http://192.168.101.76/auth_api";
  
  // Auth endpoints
  static const String login = "$baseUrl/login.php";
  static const String register = "$baseUrl/register.php";
  static const String logout = "$baseUrl/logout.php";
  
  // Product endpoints
  static const String getProducts = "$baseUrl/get_products.php";
  static const String getCategories = "$baseUrl/get_categories.php";
  static const String getProductDetails = "$baseUrl/get_product_details.php";
  
  // Cart endpoints
  static const String addToCart = "$baseUrl/add_to_cart.php";
  static const String getCartItems = "$baseUrl/get_cart_items.php";
  static const String updateCartQuantity = "$baseUrl/update_cart_quantity.php";
  static const String removeCartItem = "$baseUrl/remove_cart_item.php";
  static const String getCartItemCount = "$baseUrl/get_cart_count.php";
  static const String clearCart = "$baseUrl/clear_cart.php";

  // Order endpoints
  static const String createOrder = "$baseUrl/create_order.php";
  // Order endpoints
  static const String getOrders = "$baseUrl/get_orders.php";
  static const String getOrderDetails = "$baseUrl/get_order_details.php";
  static const String updateOrderStatus = "$baseUrl/update_order_status.php";
  static const String submitReview = "$baseUrl/submit_review.php";
}