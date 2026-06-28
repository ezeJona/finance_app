import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../backend-api/api_service.dart';
import '../../backend-api/dtos.dart';
import '../../providers/app_user.dart';
import '../../providers/auth_user.dart';
import '../../providers/businesses.dart';
import '../../providers/business.dart';
import '../../providers/inventory.dart';
import '../../providers/achievements.dart';
import '../../providers/destroy_session.dart';
import '../../widgets/app_drawer.dart';

class ProfilePage extends HookConsumerWidget {
  const ProfilePage({super.key});

  static const Color primaryYellow = Color(0xFFF1C40F);
  static const Color darkNavy = Color(0xFF2C3E50);
  static const Color incomeGreen = Color(0xFF00A86B);
  static const Color expenseRed = Color(0xFFFF2D55);
  static const Color textGray = Color(0xFF7F8C8D);
  static const Color backgroundColor = Color(0xFFF5F6F8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUser = ref.watch(appUserProvider);
    final authUser = ref.watch(authUserProvider);
    final businessesAsync = ref.watch(businessesProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryYellow,
          onRefresh: () async {
            try {
              // Refrescar perfil de usuario desde red
              await ref.read(appUserProvider.notifier).fetch();
            } catch (_) {}
            
            ref.invalidate(businessesProvider);
            ref.invalidate(achievementsProvider);
            ref.invalidate(businessProductsProvider);
            
            // Pequeña espera para que la animación se vea fluida
            await Future.delayed(const Duration(milliseconds: 800));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: darkNavy,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [darkNavy, Color(0xFF34495E)],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _buildProfileAvatar(context, ref, appUser),
                      const SizedBox(height: 12),
                      Text(
                        '${appUser?.firstName ?? "Usuario"} ${appUser?.firstLastName ?? ""}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        authUser?.email ?? "",
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => _showEditProfileModal(context, ref, appUser),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAchievementsSection(ref),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Mis Negocios & Catálogos"),
                  const SizedBox(height: 16),
                  
                  businessesAsync.when(
                    data: (businesses) => businesses.isEmpty 
                      ? _buildEmptyState()
                      : Column(
                          children: businesses.map((b) => _BusinessCatalogCard(business: b)).toList(),
                        ),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (err, _) => Center(child: Text("Error: $err")),
                  ),

                  const SizedBox(height: 40),

                  OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout, color: expenseRed),
                    label: const Text(
                      "CERRAR SESIÓN",
                      style: TextStyle(color: expenseRed, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: expenseRed, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, WidgetRef ref, AppUserRes? appUser) {
    return GestureDetector(
      onTap: () => _updateAvatar(context, ref, appUser),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: primaryYellow,
              backgroundImage: appUser?.avatar != null && appUser!.avatar!.isNotEmpty
                  ? CachedNetworkImageProvider(appUser.avatar!)
                  : null,
              child: appUser?.avatar == null || appUser!.avatar!.isEmpty
                  ? Text(
                      appUser?.firstName.isNotEmpty == true ? appUser!.firstName[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: primaryYellow, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: darkNavy, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAvatar(BuildContext context, WidgetRef ref, AppUserRes? appUser) async {
    if (appUser == null) return;
    
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);
      if (pickedFile != null) {
        try {
          final imageUrl = await ApiService.uploadUserAvatar(appUser.id, File(pickedFile.path));
          
          final req = CreateAppUserReq(
            id: appUser.id,
            firstName: appUser.firstName,
            secondName: appUser.secondName,
            firstLastName: appUser.firstLastName,
            secondLastName: appUser.secondLastName,
            dateOfBirth: appUser.dateOfBirth,
            avatar: imageUrl,
          );

          final updatedUser = await ApiService.updateAppUser(appUser.id, req);
          ref.read(appUserProvider.notifier).set(updatedUser);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto de perfil actualizada'), backgroundColor: incomeGreen),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: expenseRed),
            );
          }
        }
      }
    }
  }

  void _showEditProfileModal(BuildContext context, WidgetRef ref, AppUserRes? appUser) {
    if (appUser == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => _EditProfileForm(appUser: appUser, ref: ref),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(color: primaryYellow, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkNavy),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.storefront_outlined, size: 64, color: Colors.black12),
          SizedBox(height: 16),
          Text("No tienes negocios registrados aún.", style: TextStyle(color: textGray)),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
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
  }

  Widget _buildAchievementsSection(WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Logros"),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: achievements.map((a) => _AchievementBadge(achievement: a)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    final color = isUnlocked ? const Color(0xFFF1C40F) : Colors.grey.shade300;
    final iconColor = isUnlocked ? Colors.white : Colors.grey.shade500;

    return Tooltip(
      message: achievement.description,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUnlocked ? color : Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: isUnlocked ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Icon(
                achievement.icon,
                color: iconColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? const Color(0xFF2C3E50) : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileForm extends HookConsumerWidget {
  final AppUserRes appUser;
  final WidgetRef ref;

  const _EditProfileForm({required this.appUser, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final firstNameController = useTextEditingController(text: appUser.firstName);
    final secondNameController = useTextEditingController(text: appUser.secondName);
    final firstLastNameController = useTextEditingController(text: appUser.firstLastName);
    final secondLastNameController = useTextEditingController(text: appUser.secondLastName);
    final isLoading = useState(false);

    Future<void> save() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;

      try {
        final req = CreateAppUserReq(
          id: appUser.id,
          firstName: firstNameController.text,
          secondName: secondNameController.text,
          firstLastName: firstLastNameController.text,
          secondLastName: secondLastNameController.text,
          dateOfBirth: appUser.dateOfBirth,
          avatar: appUser.avatar,
        );

        final updatedUser = await ApiService.updateAppUser(appUser.id, req);
        ref.read(appUserProvider.notifier).set(updatedUser);

        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado'), backgroundColor: ProfilePage.incomeGreen),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: ProfilePage.expenseRed),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "EDITAR PERFIL",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ProfilePage.darkNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'Primer Nombre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: secondNameController,
                decoration: InputDecoration(
                  labelText: 'Segundo Nombre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: firstLastNameController,
                decoration: InputDecoration(
                  labelText: 'Primer Apellido',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: secondLastNameController,
                decoration: InputDecoration(
                  labelText: 'Segundo Apellido',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isLoading.value ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: ProfilePage.darkNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessCatalogCard extends HookConsumerWidget {
  final BusinessRes business;
  const _BusinessCatalogCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(businessProductsProvider(business.id));
    final isExpanded = useState(false);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ProfilePage.darkNavy.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: ProfilePage.darkNavy),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ProfilePage.darkNavy),
                      ),
                      Text(
                        "${business.businessType} • ${business.currencyCode}",
                        style: const TextStyle(color: ProfilePage.textGray, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ProfilePage.textGray),
                  onPressed: () => _goToInventory(context, ref),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              "CATÁLOGO DE PRODUCTOS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: ProfilePage.textGray,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Lista horizontal siempre visible (resumen)
          if (!isExpanded.value)
            SizedBox(
              height: 130,
              child: productsAsync.when(
                data: (products) => products.isEmpty
                  ? const Center(child: Text("Sin productos aún", style: TextStyle(fontSize: 12, color: ProfilePage.textGray)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length > 6 ? 7 : products.length,
                      itemBuilder: (context, index) {
                        if (index == 6) {
                          return _buildViewMoreItem(context, ref, () => isExpanded.value = true);
                        }
                        return _buildProductItem(products[index]);
                      },
                    ),
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const Center(child: Icon(Icons.error_outline, color: Colors.red)),
              ),
            ),

          // Sección expandida: Grid de todos los productos
          if (isExpanded.value)
            productsAsync.when(
              data: (products) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _buildProductItem(products[index]),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () {
                      if (productsAsync.hasValue && productsAsync.value!.length > 3) {
                        isExpanded.value = !isExpanded.value;
                      } else {
                         _goToInventory(context, ref);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: ProfilePage.primaryYellow.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isExpanded.value ? "VER MENOS" : "VER CATÁLOGO COMPLETO",
                      style: const TextStyle(color: ProfilePage.darkNavy, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("En proceso pronto se habilitara esta opción"),
                          backgroundColor: ProfilePage.darkNavy,
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18, color: ProfilePage.darkNavy),
                    label: const Text(
                      "Compartir catálogo",
                      style: TextStyle(color: ProfilePage.darkNavy, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ProfilePage.darkNavy.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductRes product) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 4),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined, size: 20, color: Colors.grey),
                      )
                    : const Icon(Icons.inventory_2_outlined, color: Colors.black12, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ProfilePage.darkNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMoreItem(BuildContext context, WidgetRef ref, VoidCallback onExpand) {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: ProfilePage.darkNavy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ProfilePage.darkNavy.withOpacity(0.1)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: ProfilePage.darkNavy),
            SizedBox(height: 4),
            Text("Ver más", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ProfilePage.darkNavy)),
          ],
        ),
      ),
    );
  }

  void _goToInventory(BuildContext context, WidgetRef ref) {
    ref.read(businessProvider.notifier).set(business);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }
}
