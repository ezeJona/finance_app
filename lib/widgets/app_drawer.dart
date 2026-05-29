import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_user.dart';
import '../providers/business.dart';
import '../providers/auth_user.dart';
import '../providers/businesses.dart';
import '../providers/destroy_session.dart';
import '../backend-api/api_service.dart';
import '../backend-api/dtos.dart';

class AppDrawer extends HookConsumerWidget {
  const AppDrawer({super.key});

  // Paleta de Colores (Consistente con BalancePage)
  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color emeraldGreen = Color(0xFF2ECC71);
  static const Color expenseRed = Color(0xFFFF2D55);
  static const Color textGray = Color(0xFF7F8C8D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final authUser = ref.watch(authUserProvider);
    final business = ref.watch(businessProvider);
    final businessesAsync = ref.watch(businessesProvider);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryYellow),
            currentAccountPicture: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 40,
                  child: Text(
                    appUser?.firstName.isNotEmpty == true
                        ? appUser!.firstName.substring(0, 1).toUpperCase()
                        : "U",
                    style: const TextStyle(
                        color: primaryYellow,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Navegar a la página de edición de perfil
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: darkNavy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            accountName: Text(
              '${appUser?.firstName ?? "Usuario"} ${appUser?.firstLastName ?? ""}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(authUser?.email ?? "sin-email@hospired.com"),
                const SizedBox(height: 2),
              ],
            ),
          ),
          Expanded(
            child: businessesAsync.when(
              data: (businesses) => ListView(
                padding: EdgeInsets.zero,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      "MIS NEGOCIOS",
                      style: TextStyle(
                          color: textGray,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2),
                    ),
                  ),
                  ...businesses.map((b) => ListTile(
                        leading: const Icon(Icons.storefront, color: darkNavy),
                        title: Text(b.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${b.businessType} | ${b.currencyCode}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (b.id == business?.id)
                              const Icon(Icons.check_circle,
                                  color: incomeGreen, size: 20),
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: textGray),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'edit':
                                    _showAddBusinessModal(context, ref, authUser!.id, business: b);
                                    break;
                                  case 'delete':
                                    _confirmDeleteBusiness(context, ref, b);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('Editar negocio'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: expenseRed.withOpacity(0.8),
                                          size: 20),
                                      const SizedBox(width: 8),
                                      const Text('Borrar negocio',
                                          style:
                                              TextStyle(color: expenseRed)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          ref.read(businessProvider.notifier).set(b);
                          if (context.mounted) Navigator.pop(context);
                        },
                      )),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.add_circle_outline, color: emeraldGreen),
                    title: const Text('Añadir nuevo negocio',
                        style: TextStyle(
                            color: emeraldGreen, fontWeight: FontWeight.bold)),
                    onTap: () {
                      if (authUser != null) {
                        _showAddBusinessModal(context, ref, authUser.id);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: expenseRed),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cerrar Sesión'),
                          content: const Text('¿Estás seguro de que deseas salir?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('CANCELAR', style: TextStyle(color: textGray)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('SALIR', style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ApiService.signOutUser();
                        destroySession(ref);
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        }
                      }
                    },
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBusinessModal(BuildContext context, WidgetRef ref, String userId, {BusinessRes? business}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => _AddBusinessForm(userId: userId, ref: ref, business: business),
    );
  }

  Future<void> _confirmDeleteBusiness(BuildContext context, WidgetRef ref, BusinessRes business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar ${business.name}?'),
        content: const Text('Esta acción no se puede deshacer. ¿Estás seguro de que deseas eliminar este negocio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR', style: TextStyle(color: textGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteBusiness(business.id);
        ref.invalidate(businessesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Negocio eliminado correctamente'), backgroundColor: incomeGreen),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: expenseRed),
          );
        }
      }
    }
  }
}

class _AddBusinessForm extends StatefulWidget {
  final String userId;
  final WidgetRef ref;
  final BusinessRes? business;

  const _AddBusinessForm({required this.userId, required this.ref, this.business});

  @override
  State<_AddBusinessForm> createState() => _AddBusinessFormState();
}

class _AddBusinessFormState extends State<_AddBusinessForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _businessType;
  late String _currencyCode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.business?.name);
    _businessType = widget.business?.businessType ?? 'Personal';
    _currencyCode = widget.business?.currencyCode ?? 'NIO';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final req = CreateBusinessReq(
        userId: widget.userId,
        name: _nameController.text,
        businessType: _businessType,
        currencyCode: _currencyCode,
      );

      if (widget.business == null) {
        await ApiService.createBusiness(req);
      } else {
        await ApiService.updateBusiness(widget.business!.id, req);
      }

      widget.ref.invalidate(businessesProvider);

      if (mounted) {
        Navigator.pop(context); // Cerrar Modal
        Navigator.pop(context); // Cerrar Drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.business == null ? 'Negocio creado exitosamente' : 'Cambios guardados exitosamente'),
            backgroundColor: AppDrawer.incomeGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar: $e'),
            backgroundColor: AppDrawer.expenseRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.business == null ? 'Añadir nuevo negocio' : 'Editar negocio',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppDrawer.darkNavy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Negocio',
                hintText: 'Ej. Mi Empresa S.A.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Por favor ingrese un nombre' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _businessType,
              decoration: InputDecoration(
                labelText: 'Tipo de Negocio',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: ['Personal', 'Comercial', 'Servicios', 'Otro']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _businessType = val!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currencyCode,
              decoration: InputDecoration(
                labelText: 'Moneda Principal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: [
                {'code': 'NIO', 'name': 'Córdoba (NIO)'},
                {'code': 'USD', 'name': 'Dólar (USD)'},
              ].map((c) => DropdownMenuItem(value: c['code']!, child: Text(c['name']!)))
                  .toList(),
              onChanged: (val) => setState(() => _currencyCode = val!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppDrawer.emeraldGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.business == null ? 'GUARDAR' : 'GUARDAR CAMBIOS',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
