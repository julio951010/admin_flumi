import 'package:flutter/material.dart';

import '../../config/tema.dart';
import 'enviar_mensaje_admin_pantalla.dart';
import 'buscar_email_pantalla.dart';

class HerramientasPantalla extends StatefulWidget {
  const HerramientasPantalla({super.key});

  @override
  State<HerramientasPantalla> createState() => _HerramientasPantallaState();
}

class _HerramientasPantallaState extends State<HerramientasPantalla>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _staggerController;
  late final List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(index * 0.1, (0.6 + index * 0.1).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      ),
    );
    _fadeController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: Tema.marca,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(colorScheme),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _buildContent(colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: FadeTransition(
          opacity: _fadeController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Herramientas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Utilidades de administración y mantenimiento',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Tema.marca.withValues(alpha: 0.08),
                Tema.marca.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categoría: Comunicación
        _buildSectionTitle('Comunicación', colorScheme),
        const SizedBox(height: 12),
        _buildToolCard(
          index: 1,
          icon: Icons.send_outlined,
          title: 'Enviar mensaje como Admin / Flumi',
          subtitle: 'Envía mensajes a usuarios desde el perfil del sistema "Administrador" o "Flumi". Útil para anuncios, bienvenidas o notificaciones.',
          color: Colors.blue,
          colorScheme: colorScheme,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EnviarMensajeAdminPantalla()),
          ),
        ),
        const SizedBox(height: 12),
        _buildToolCard(
          index: 2,
          icon: Icons.email_outlined,
          title: 'Buscar email de usuario',
          subtitle: 'Consulta el email de autenticación de cualquier usuario (solo admins). Requiere UUID del perfil.',
          color: Colors.green,
          colorScheme: colorScheme,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuscarEmailPantalla()),
          ),
        ),
        const SizedBox(height: 24),

        // Categoría: Próximamente
        _buildSectionTitle('Próximamente', colorScheme),
        const SizedBox(height: 12),
        _buildToolCard(
          index: 3,
          icon: Icons.construction_outlined,
          title: 'Más herramientas en desarrollo',
          subtitle: 'Exportar datos, gestión masiva de usuarios, auditoría de acciones, etc.',
          color: Colors.grey,
          disabled: true,
          colorScheme: colorScheme,
          onTap: null,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildToolCard({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool danger = false,
    bool disabled = false,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
  }) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardAnimations[index].value)),
          child: Opacity(
            opacity: _cardAnimations[index].value * (disabled ? 0.5 : 1.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: disabled ? null : onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: danger
                          ? color.withValues(alpha: 0.3)
                          : colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: danger ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: danger ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (danger)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'DESTRUCTIVA',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                if (disabled)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'PRÓXIMO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!disabled)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}