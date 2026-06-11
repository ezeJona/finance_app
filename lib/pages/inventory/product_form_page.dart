import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../providers/inventory.dart';
import '../../providers/business.dart';
import '../../backend-api/dtos.dart';

class ProductFormPage extends HookConsumerWidget {
  final ProductRes? product;

  const ProductFormPage({super.key, this.product});

  // Constantes de diseño extraídas de la aplicación
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    
    // Controladores con Hooks
    final nameController = useTextEditingController(text: product?.name);
    final descriptionController = useTextEditingController(text: product?.description);
    final costPriceController = useTextEditingController(text: product?.costPrice.toString() ?? '0');
    final salePriceController = useTextEditingController(text: product?.salePrice.toString() ?? '0');
    final stockController = useTextEditingController(text: product?.stock.toInt().toString() ?? '0');
    final minStockController = useTextEditingController(text: product?.minStock.toString() ?? '0');
    
    final selectedCategoryId = useState<int?>(product?.categoryId);
    final isLoading = useState(false);

    final categoriesAsync = ref.watch(productCategoriesProvider);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      final business = ref.read(businessProvider);

      try {
        final req = CreateProductReq(
          businessId: business!.id,
          categoryId: selectedCategoryId.value,
          name: nameController.text,
          description: descriptionController.text,
          costPrice: double.parse(costPriceController.text),
          salePrice: double.parse(salePriceController.text),
          stock: double.parse(stockController.text),
          minStock: double.parse(minStockController.text),
        );

        if (product == null) {
          await ref.read(productsProvider.notifier).addProduct(req);
        } else {
          await ref.read(productsProvider.notifier).updateProduct(product!.id, req);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto guardado correctamente'), 
              backgroundColor: incomeGreen,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF2D55)),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        centerTitle: true,
        title: Text(
          product == null ? 'Agregar producto' : 'Editar producto',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bloque Superior: Imagen y Cantidad/Nombre
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de Imagen
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: darkNavy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Nombre y Stock (Sustituyendo el código de barras omitido)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nombre", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: 'Nombre del artículo',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Obligatorio' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text("Cantidad disponible", style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        _buildCounter(stockController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Campo 1: Precio de Venta
              _buildInputCard(
                label: "Precio de venta",
                icon: Icons.payments_outlined,
                child: TextFormField(
                  controller: salePriceController,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkNavy),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'C\$ ',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Campo 2: Costo Unitario
              _buildInputCard(
                label: "Costo unitario",
                icon: Icons.payments_outlined,
                child: TextFormField(
                  controller: costPriceController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'C\$ ',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                ),
              ),
              const SizedBox(height: 12),

              // Campo 3: Categoría
              _buildInputCard(
                label: "Categoría",
                icon: Icons.category_outlined,
                child: categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    value: selectedCategoryId.value,
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    icon: const Icon(Icons.arrow_drop_down, color: darkNavy),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => selectedCategoryId.value = val,
                    validator: (val) => val == null ? 'Obligatorio' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error al cargar categorías'),
                ),
              ),
              const SizedBox(height: 12),

              // Campo 4: Descripción
              _buildInputCard(
                label: "Descripción",
                icon: Icons.assignment_outlined,
                child: TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Descripción (Opcional)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón Principal Inferior
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isLoading.value ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: incomeGreen,
                    shape: const StadiumBorder(),
                  ),
                  child: isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          product == null ? 'CREAR PRODUCTO' : 'GUARDAR CAMBIOS',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para construir las tarjetas de entrada
  Widget _buildInputCard({required String label, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, color: darkNavy, size: 22),
              const SizedBox(width: 12),
              Expanded(child: child),
              const Icon(Icons.info_outline, color: Colors.grey, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  // Helper para el selector de stock
  Widget _buildCounter(TextEditingController controller) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18, color: darkNavy),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              if (val > 0) controller.text = (val - 1).toInt().toString();
            },
          ),
          const VerticalDivider(width: 1, color: Colors.black12),
          Expanded(
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true),
              style: const TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.black12),
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: darkNavy),
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              controller.text = (val + 1).toInt().toString();
            },
          ),
        ],
      ),
    );
  }
}
