import '../backend-api/dtos.dart';

class CartItem {
  final ProductRes product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.salePrice * quantity;
  double get profit => (product.salePrice - product.costPrice) * quantity;
}
