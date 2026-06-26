import 'package:flutter/material.dart';
import '../../models/educational_content.dart';
import '../../widgets/app_drawer.dart';
import 'module_detail_view.dart';

class EducationalView extends StatelessWidget {
  const EducationalView({super.key});

  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // Header Único de la Academia con Botón de Menú
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: statusBarHeight + 10, 
                left: 16, 
                right: 16, 
                bottom: 24
              ),
              decoration: const BoxDecoration(
                color: darkNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const Text(
                        "Academia del Negocio",
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 18
                        ),
                      ),
                      const SizedBox(width: 48), // Espacio para equilibrar el botón de menú
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "¡Aprende a tu ritmo!",
                    style: TextStyle(
                      color: primaryYellow, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 20
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Consejos clave para que tu negocio crezca seguro.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 14,
                      height: 1.4
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido de las pestañas
            Expanded(
              child: TabBarView(
                children: [
                  _buildModuleList(EducationalCategory.finance),
                  _buildModuleList(EducationalCategory.security),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: const SafeArea(
            child: TabBar(
              labelColor: darkNavy,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryYellow,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              padding: EdgeInsets.symmetric(vertical: 8),
              tabs: [
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                  text: "GESTIÓN",
                ),
                Tab(
                  icon: Icon(Icons.security_outlined),
                  text: "SEGURIDAD",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleList(EducationalCategory category) {
    final modules = educationalModules.where((m) => m.category == category).toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(module.icon, color: darkNavy),
            ),
            title: Text(
              module.title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: darkNavy),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                module.shortDescription,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModuleDetailView(module: module),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
