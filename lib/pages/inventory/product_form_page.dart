import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../providers/inventory.dart';
import '../../providers/business.dart';
import '../../backend-api/dtos.dart';

class ProductFormPage extends StatefulHookConsumerWidget {
  final ProductRes? product;

  const ProductFormPage({super.key, this.product});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  int? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _descriptionController = TextEditingController(text: widget.product?.description);
    _costPriceController = TextEditingController(text: widget.product?.costPrice.toString() ?? '0');
    _salePriceController = TextEditingController(text: widget.product?.salePrice.toString() ?? '0');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '0');
    _minStockController = TextEditingController(text: widget.product?.minStock.toString() ?? '0');
    _selectedCategoryId = widget.product?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final business = ref.read(businessProvider);

    try {
      final req = CreateProductReq(
        businessId: business!.id,
        categoryId: _selectedCategoryId,
        name: _nameController.text,
        description: _descriptionController.text,
        costPrice: double.parse(_costPriceController.text),
        salePrice: double.parse(_salePriceController.text),
        stock: double.parse(_stockController.text),
        minStock: double.parse(_minStockController.text),
      );

      if (widget.product == null) {
        await ref.read(productsProvider.notifier).addProduct(req);
      } else {
        await ref.read(productsProvider.notifier).updateProduct(widget.product!.id, req);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado correctamente'), backgroundColor: Color(0xFF00A86B)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF2D55)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Nuevo Producto' : 'Editar Producto'),
        backgroundColor: const Color(0xFFF1C40F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Producto*',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error al cargar categorías'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      decoration: InputDecoration(
                        labelText: 'Costo Unitario',
                        prefixText: 'C\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      decoration: InputDecoration(
                        labelText: 'Precio de Venta',
                        prefixText: 'C\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock Inicial',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: InputDecoration(
                        labelText: 'Stock Mínimo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('GUARDAR PRODUCTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
