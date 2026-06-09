import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/inventory.dart';
import '../../backend-api/dtos.dart';
import 'product_form_page.dart';

class InventoryView extends HookConsumerWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    
    final searchQuery = useState('');
    final selectedCategoryId = useState<int?>(null);

    // Colores
    const Color primaryYellow = Color(0xFFF1C40F);
    const Color darkNavy = Color(0xFF2C3E50);
    const Color expenseRed = Color(0xFFFF2D55);
    const Color incomeGreen = Color(0xFF00A86B);

    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (val) => searchQuery.value = val,
            ),
          ),
          
          // Categorías (Chips)
          categoriesAsync.when(
            data: (categories) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Todos'),
                      selected: selectedCategoryId.value == null,
                      onSelected: (selected) {
                        if (selected) selectedCategoryId.value = null;
                      },
                      selectedColor: primaryYellow,
                      labelStyle: TextStyle(
                        color: selectedCategoryId.value == null ? Colors.white : darkNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.name),
                      selected: selectedCategoryId.value == cat.id,
                      onSelected: (selected) {
                        selectedCategoryId.value = selected ? cat.id : null;
                      },
                      selectedColor: primaryYellow,
                      labelStyle: TextStyle(
                        color: selectedCategoryId.value == cat.id ? Colors.white : darkNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: incomeGreen),
                    onPressed: () => _showAddCategoryDialog(context, ref),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox(height: 48, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),

          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filteredProducts = products.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(searchQuery.value.toLowerCase());
                  final matchesCategory = selectedCategoryId.value == null || p.categoryId == selectedCategoryId.value;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No hay productos en el inventario'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isLowStock = product.stock <= product.minStock;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[100],
                          ),
                          child: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Icon(Icons.image),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                )
                              : const Icon(Icons.inventory_2, color: darkNavy, size: 30),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'C\$ ${product.salePrice.toStringAsFixed(2)}',
                              style: const TextStyle(color: incomeGreen, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Stock: ${product.stock}', style: const TextStyle(fontSize: 13)),
                                if (isLowStock) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: expenseRed,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '¡Bajo Stock!',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: darkNavy),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
                          ),
                        ),
                        onLongPress: () => _confirmDelete(context, ref, product),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryYellow,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductFormPage()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre de la categoría'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(productCategoriesProvider.notifier).addCategory(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ProductRes product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Archivar ${product.name}?'),
        content: const Text('El producto se ocultará pero se mantendrá en el historial de ventas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text('ARCHIVAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
