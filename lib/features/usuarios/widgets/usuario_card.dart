import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/tema.dart';
import '../../../core/modelo/usuario_admin.dart';
import '../../comun/widgets_comunes.dart';

/// Tarjeta de usuario para vista lista
class UsuarioCard extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onTap;

  const UsuarioCard({
    super.key,
    required this.usuario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              AvatarConFallback(url: usuario.fotoPrincipal, radius: 28),
              const SizedBox(width: 16),
              // Info principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            usuario.nombre.isNotEmpty ? usuario.nombre : 'Sin nombre',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (usuario.verificadoStatus)
                          ChipEstado(
                            texto: 'Verificado',
                            color: Colors.blue,
                            icono: Icons.verified_rounded,
                          ),
                        if (usuario.suspendido)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChipEstado(
                              texto: 'Suspendido',
                              color: Colors.red,
                              icono: Icons.block_rounded,
                            ),
                          ),
                        if (usuario.isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChipEstado(
                              texto: 'Admin',
                              color: Colors.orange,
                              icono: Icons.admin_panel_settings_rounded,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Email
                    if (usuario.email.isNotEmpty)
                      Text(
                        usuario.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    // Ubicación, género, edad
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (usuario.ciudad.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on_rounded,
                            text: usuario.ciudad,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        if (usuario.genero.isNotEmpty)
                          _InfoChip(
                            icon: Icons.person_rounded,
                            text: usuario.genero,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        if (usuario.edad != null)
                          _InfoChip(
                            icon: Icons.cake_rounded,
                            text: '${usuario.edad} años',
                            color: colorScheme.onSurfaceVariant,
                          ),
                        if (usuario.scorePopularidad != null && usuario.scorePopularidad! > 0)
                          _InfoChip(
                            icon: Icons.trending_up_rounded,
                            text: 'Score: ${usuario.scorePopularidad}',
                            color: Tema.marca,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Columna derecha: última conexión + flecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (usuario.ultimaConexion != null)
                    _buildUltimaConexion(context),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltimaConexion(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ahora = DateTime.now();
    final diff = ahora.difference(usuario.ultimaConexion!);
    String texto;
    Color color;

    if (diff.inMinutes < 5) {
      texto = 'En línea';
      color = Colors.green;
    } else if (diff.inHours < 1) {
      texto = 'Hace ${diff.inMinutes} min';
      color = Colors.blue;
    } else if (diff.inHours < 24) {
      texto = 'Hace ${diff.inHours} h';
      color = Colors.orange;
    } else if (diff.inDays < 7) {
      texto = 'Hace ${diff.inDays} d';
      color = Colors.grey;
    } else {
      texto = DateFormat('dd/MM/yyyy').format(usuario.ultimaConexion!);
      color = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            diff.inMinutes < 5 ? Icons.circle : Icons.access_time_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de usuario para vista cuadrícula
class UsuarioCardGrid extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onTap;

  const UsuarioCardGrid({
    super.key,
    required this.usuario,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar centrado
              Center(
                child: AvatarConFallback(url: usuario.fotoPrincipal, radius: 36),
              ),
              const SizedBox(height: 12),
              // Nombre
              Text(
                usuario.nombre.isNotEmpty ? usuario.nombre : 'Sin nombre',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Badges
              Center(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    if (usuario.verificadoStatus)
                      ChipEstado(
                        texto: 'Verificado',
                        color: Colors.blue,
                        icono: Icons.verified_rounded,
                      ),
                    if (usuario.suspendido)
                      ChipEstado(
                        texto: 'Suspendido',
                        color: Colors.red,
                        icono: Icons.block_rounded,
                      ),
                    if (usuario.isAdmin)
                      ChipEstado(
                        texto: 'Admin',
                        color: Colors.orange,
                        icono: Icons.admin_panel_settings_rounded,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Info secundaria
              if (usuario.ciudad.isNotEmpty || usuario.genero.isNotEmpty)
                Center(
                  child: Text(
                    [usuario.ciudad, usuario.genero].where((s) => s.isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              // Footer: edad + última conexión
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (usuario.edad != null)
                    _InfoChip(
                      icon: Icons.cake_rounded,
                      text: '${usuario.edad} años',
                      color: colorScheme.onSurfaceVariant,
                      small: true,
                    ),
                  if (usuario.ultimaConexion != null)
                    _buildUltimaConexionGrid(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltimaConexionGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ahora = DateTime.now();
    final diff = ahora.difference(usuario.ultimaConexion!);
    String texto;
    Color color;

    if (diff.inMinutes < 5) {
      texto = 'En línea';
      color = Colors.green;
    } else if (diff.inHours < 1) {
      texto = '${diff.inMinutes}m';
      color = Colors.blue;
    } else if (diff.inHours < 24) {
      texto = '${diff.inHours}h';
      color = Colors.orange;
    } else if (diff.inDays < 7) {
      texto = '${diff.inDays}d';
      color = Colors.grey;
    } else {
      texto = '${diff.inDays}d';
      color = colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            diff.inMinutes < 5 ? Icons.circle : Icons.access_time_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool small;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(small ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}