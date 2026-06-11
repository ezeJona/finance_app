import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_drawer.dart';
import 'product_form_page.dart';

class InventoryView extends HookConsumerWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Colores de la línea gráfica
    const Color primaryYellow = Color(0xFFF1C40F);
    const Color darkNavy = Color(0xFF2C3E50);
    const Color incomeGreen = Color(0xFF00A86B);
    const Color backgroundGray = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundGray,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Tarjetas de Resumen (Ahora integradas secuencialmente)
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard("Total de artículos", "1"),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildSummaryCard("Ventas totales", "C\$ 6,000"),
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
                          child: const Icon(Icons.file_download_outlined, color: darkNavy),
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
                            color: darkNavy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mode_edit_outline, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Ver todas las categorías", isSelected: true, color: darkNavy),
                        const SizedBox(width: 8),
                        _buildCategoryChip("Aseo", isSelected: false, color: primaryYellow),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Listado de Artículos (Tarjetas de Producto)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildProductCard(
                      name: "Jabon",
                      stock: "5 Disponibles",
                      price: "C\$ 1,500",
                    ),
                  ),

                  // Mensaje de estado vacío
                  const SizedBox(height: 40),
                  const Text(
                    "No tienes productos en tu inventario",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 100), // Espacio para no ser tapado por el botón
                ],
              ),
            ),
          ),
        ],
      ),
      // 5. Botón de Acción Inferior (Uso de floatingActionButton para mejor integración)
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
              backgroundColor: incomeGreen,
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

  Widget _buildCategoryChip(String label, {required bool isSelected, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == Colors.white ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildProductCard({required String name, required String stock, required String price}) {
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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  stock,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  price,
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
          const Icon(Icons.more_vert, color: Colors.grey),
        ],
      ),
    );
  }
}
