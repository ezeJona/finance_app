import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import 'product_form_page.dart';
import '../../providers/inventory.dart';
import '../../backend-api/dtos.dart';

class InventoryView extends HookConsumerWidget {
  const InventoryView({super.key});

  // Colores de la línea gráfica moved to class level constants
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color backgroundGray = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final totalArticles = ref.watch(totalArticlesProvider);
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);

    return Scaffold(
      backgroundColor: backgroundGray,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.read(productCategoriesProvider.notifier).refresh();
                ref.read(productsProvider.notifier).refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 1. Tarjetas de Resumen
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard("Total de artículos", totalArticles.toStringAsFixed(0)),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildSummaryCard("Ventas totales", "C\$ 6,000"), // Estático como se solicitó
                          ),
                        ],
                      ),
                    ),

                    // 2. Barra de Búsqueda y Acción
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: const TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar ...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                            child: const Icon(Icons.file_download_outlined, color: InventoryView.darkNavy),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Filtros de Categorías (Chips Horizontales)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: InventoryView.darkNavy,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.mode_edit_outline, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showAddCategoryDialog(context, ref),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black12),
                              ),
                              child: const Icon(Icons.add, color: InventoryView.darkNavy, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildCategoryChip(
                            "Ver todas las categorías",
                            isSelected: selectedCategoryId == null,
                            color: selectedCategoryId == null ? InventoryView.darkNavy : Colors.white,
                            onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = null,
                          ),
                          ...categoriesAsync.maybeWhen(
                            data: (categories) => categories.map((cat) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _buildCategoryChip(
                                    cat.name,
                                    isSelected: selectedCategoryId == cat.id,
                                    color: selectedCategoryId == cat.id ? InventoryView.darkNavy : InventoryView.primaryYellow,
                                    onTap: () => ref.read(selectedCategoryIdProvider.notifier).state = cat.id,
                                  ),
                                )),
                            orElse: () => [],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Listado de Artículos
                    if (filteredProducts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          "No tienes productos en tu inventario",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredProducts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(
                              context,
                              ref,
                              product: product,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductFormPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: InventoryView.incomeGreen,
              shape: const StadiumBorder(),
              elevation: 4,
            ),
            child: const Text(
              "CREAR PRODUCTO",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Categoría"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Nombre de la categoría",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final name = controller.text;
                Navigator.pop(context);
                try {
                  await ref.read(productCategoriesProvider.notifier).addCategory(name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Categoría "$name" agregada'),
                        backgroundColor: InventoryView.incomeGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text("GUARDAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, {required bool isSelected, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.black12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, {required ProductRes product}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "${product.stock.toInt()} Disponibles",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  "C\$ ${product.salePrice.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) async {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
                );
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("¿Eliminar producto?"),
                    content: const Text("Esta acción ocultará el producto de tu inventario."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(productsProvider.notifier).deleteProduct(product.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto eliminado correctamente'),
                          backgroundColor: InventoryView.incomeGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al eliminar: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
