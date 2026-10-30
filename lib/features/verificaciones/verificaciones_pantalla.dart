import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

/// Revisión manual de verificaciones de cuenta: compara la selfie enviada
/// con las fotos del perfil y aprueba o rechaza.
class VerificacionesPantalla extends StatefulWidget {
  const VerificacionesPantalla({super.key});
  @override
  State<VerificacionesPantalla> createState() => _VerificacionesPantallaState();
}

class _VerificacionesPantallaState extends State<VerificacionesPantalla>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _pendientes = [];
  bool _cargando = true;
  bool _cargandoInicial = true;
  String? _error;
  RealtimeChannel? _chan;

  late final AnimationController _fadeController;
  late final AnimationController _staggerController;

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
    _cargar();
    _suscribirRealtime();
  }

  @override
  void dispose() {
    if (_chan != null) Supabase.instance.client.removeChannel(_chan!);
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _suscribirRealtime() {
    try {
      _chan = Supabase.instance.client
          .channel('verificaciones-admin')
          .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'profiles',
              callback: (_) => _cargar())
          .subscribe();
    } catch (_) {}
  }

  Future<void> _cargar({bool reiniciar = false}) async {
    if (reiniciar) {
      setState(() {
        _cargando = true;
        _cargandoInicial = true;
        _error = null;
      });
    } else {
      setState(() => _cargando = true);
    }
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id,nombre,edad,foto_verificacion,gesto_verificacion,fotos_urls')
          .neq('foto_verificacion', '')
          .eq('verificado_status', false)
          .order('creado_en', ascending: true)
          .limit(100);
      if (!mounted) return;
      setState(() {
        _pendientes = List<Map<String, dynamic>>.from(res as List);
        _cargando = false;
        _cargandoInicial = false;
      });
      _fadeController.forward();
      _staggerController.forward();
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _cargando = false; _cargandoInicial = false; });
    }
  }

  /// Borra la selfie del Storage tras la revisión (aprobada o rechazada).
  Future<void> _borrarSelfie(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final idx = uri.pathSegments.indexOf('profile-photos');
      if (idx < 0 || idx + 1 >= uri.pathSegments.length) return;
      final ruta = uri.pathSegments.sublist(idx + 1).join('/');
      if (ruta.isEmpty) return;
      await Supabase.instance.client.storage
          .from('profile-photos')
          .remove([ruta]);
    } catch (_) {}
  }

  Future<void> _resolver(Map<String, dynamic> p, bool aprobar) async {
    final id = p['id'] as String;
    final selfie = p['foto_verificacion'] as String?;
    try {
      await Supabase.instance.client.from('profiles').update({
        'verificado_status': aprobar,
        'foto_verificacion': '',
        'gesto_verificacion': '',
      }).eq('id', id);
      await _borrarSelfie(selfie);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(aprobar ? 'Perfil verificado' : 'Verificación rechazada'),
          backgroundColor: aprobar ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
      await _cargar(reiniciar: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _confirmarRechazo(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar verificación'),
        content: Text(
            'La selfie de ${p['nombre'] ?? 'este perfil'} no coincide con sus fotos. Podrá intentarlo de nuevo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (ok == true) await _resolver(p, false);
  }

  void _abrirImagen(String url, String titulo, {bool isAsset = false}) {
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _VisorImagen(url: url, titulo: titulo, isAsset: isAsset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _cargar(reiniciar: true),
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
                'Verificaciones',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${_pendientes.length} pendientes · Arrastra para actualizar',
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
          onPressed: _cargando ? null : () => _cargar(reiniciar: true),
          icon: _cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (_cargandoInicial) {
      return _buildSkeleton(colorScheme);
    }

    if (_error != null) {
      return _buildError(colorScheme);
    }

    if (_pendientes.isEmpty) {
      return _buildEmpty(colorScheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats header
        _buildStatsChips(colorScheme),
        const SizedBox(height: 16),
        // Cards list
        _buildCardsList(colorScheme),
      ],
    );
  }

  Widget _buildStatsChips(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _fadeController,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _StatChip('Pendientes', _pendientes.length, Icons.verified_outlined, Tema.marca),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Column(
      children: [
        // Stats skeleton
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            1,
            (index) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Cards skeleton
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCardSkeleton(baseColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSkeleton(Color baseColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 20,
                      color: baseColor,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 14,
                      color: baseColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Three images skeleton
          Row(
            children: List.generate(
              3,
              (i) => Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Actions skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error al cargar', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colorScheme.error)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: () => _cargar(reiniciar: true), icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_outlined, size: 64, color: Colors.green[300]),
            const SizedBox(height: 12),
            Text('Sin verificaciones pendientes', style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Todos los usuarios están verificados', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsList(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pendientes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, i) {
            final animIndex = i % 8;
            final animation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  animIndex * 0.08,
                  (0.4 + animIndex * 0.08).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ),
            );
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - animation.value)),
                  child: Opacity(
                    opacity: animation.value,
                    child: _TarjetaVerificacion(
                      p: _pendientes[i],
                      onAprobar: () => _resolver(_pendientes[i], true),
                      onRechazar: () => _confirmarRechazo(_pendientes[i]),
                      onImagenTap: _abrirImagen,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Tarjeta individual de verificación
class _TarjetaVerificacion extends StatelessWidget {
  final Map<String, dynamic> p;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;
  final Function(String, String, {bool isAsset}) onImagenTap;

  const _TarjetaVerificacion({
    required this.p,
    required this.onAprobar,
    required this.onRechazar,
    required this.onImagenTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selfie = (p['foto_verificacion'] as String?) ?? '';
    final gesto = (p['gesto_verificacion'] as String?) ?? '';
    final fotos = ((p['fotos_urls'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final fotoPrincipal = fotos.isNotEmpty ? fotos.first : '';
    final nombre = (p['nombre'] as String?) ?? 'Sin nombre';
    final edad = p['edad']?.toString() ?? '?';
    final userId = p['id'] as String;

    final gestoAsset = gesto.isNotEmpty
        ? 'assets/images/gestos/${gesto.split('/').last}'
        : '';

    void mostrarDetalle() {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _DetalleVerificacionSheet(
              nombre: nombre,
              edad: edad,
              fotoPrincipal: fotoPrincipal,
              gesto: gesto,
              gestoAsset: gestoAsset,
              selfie: selfie,
              onImagenTap: onImagenTap,
              onAprobar: () {
                Navigator.pop(dialogCtx);
                onAprobar();
              },
              onRechazar: () {
                Navigator.pop(dialogCtx);
                onRechazar();
              },
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: mostrarDetalle,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Nombre + Edad + ID
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar con foto principal del perfil (sin iniciales)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Tema.marca.withValues(alpha: 0.12),
                      backgroundImage: fotoPrincipal.isNotEmpty ? NetworkImage(fotoPrincipal) : null,
                      child: fotoPrincipal.isEmpty
                          ? Icon(Icons.person_rounded, color: Tema.marca, size: 28)
                          : null,
                    ),
                  const SizedBox(width: 14),
                  // Nombre + Edad
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$edad años',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ID del usuario (copiable)
                  Tooltip(
                    message: 'Copiar ID',
                    child: InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: userId));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('ID copiado: $userId'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fingerprint_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              userId.substring(0, 8).toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.content_copy_rounded, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// Modal con las 3 imágenes y las acciones de aprobar / rechazar
class _DetalleVerificacionSheet extends StatelessWidget {
  final String nombre;
  final String edad;
  final String fotoPrincipal;
  final String gesto;
  final String gestoAsset;
  final String selfie;
  final Function(String, String, {bool isAsset}) onImagenTap;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _DetalleVerificacionSheet({
    required this.nombre,
    required this.edad,
    required this.fotoPrincipal,
    required this.gesto,
    required this.gestoAsset,
    required this.selfie,
    required this.onImagenTap,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Tema.marca.withValues(alpha: 0.12),
                  backgroundImage: fotoPrincipal.isNotEmpty ? NetworkImage(fotoPrincipal) : null,
                  child: fotoPrincipal.isEmpty
                      ? Icon(Icons.person_rounded, color: Tema.marca, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$nombre · $edad años',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tres imágenes: apiladas en móvil, lado a lado en tablet+
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 500;
                if (isNarrow) {
                  return Column(
                    children: [
                      _ImagenComparacion(
                        titulo: 'Foto perfil',
                        subtitulo: 'Principal',
                        url: fotoPrincipal,
                        assetFallback: null,
                        onTap: () => onImagenTap(fotoPrincipal, 'Foto de perfil de $nombre'),
                      ),
                      const SizedBox(height: 12),
                      _ImagenComparacion(
                        titulo: 'Gesto',
                        subtitulo: 'A imitar',
                        url: '',
                        assetFallback: gestoAsset,
                        onTap: () => onImagenTap(gestoAsset, 'Gesto solicitado: ${gesto.split('/').last}', isAsset: true),
                      ),
                      const SizedBox(height: 12),
                      _ImagenComparacion(
                        titulo: 'Selfie',
                        subtitulo: 'Enviada',
                        url: selfie,
                        assetFallback: null,
                        onTap: () => onImagenTap(selfie, 'Selfie de verificación de $nombre'),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    // 1. Foto principal del perfil
                    Expanded(
                      child: _ImagenComparacion(
                        titulo: 'Foto perfil',
                        subtitulo: 'Principal',
                        url: fotoPrincipal,
                        assetFallback: null,
                        onTap: () => onImagenTap(fotoPrincipal, 'Foto de perfil de $nombre'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 2. Gesto a imitar
                    Expanded(
                      child: _ImagenComparacion(
                        titulo: 'Gesto',
                        subtitulo: 'A imitar',
                        url: '',
                        assetFallback: gestoAsset,
                        onTap: () => onImagenTap(gestoAsset, 'Gesto solicitado: ${gesto.split('/').last}', isAsset: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 3. Selfie enviada
                    Expanded(
                      child: _ImagenComparacion(
                        titulo: 'Selfie',
                        subtitulo: 'Enviada',
                        url: selfie,
                        assetFallback: null,
                        onTap: () => onImagenTap(selfie, 'Selfie de verificación de $nombre'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // Acciones
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: OutlinedButton.icon(
                    onPressed: onRechazar,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: FilledButton.icon(
                    onPressed: onAprobar,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Aprobar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
  }
}

/// Widget para cada imagen de comparación (perfil, gesto, selfie)
class _ImagenComparacion extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String url;
  final String? assetFallback;
  final VoidCallback onTap;

  const _ImagenComparacion({
    required this.titulo,
    required this.subtitulo,
    required this.url,
    this.assetFallback,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = url.isNotEmpty || assetFallback != null;
    final isAsset = assetFallback != null && assetFallback!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasImage ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Etiquetas arriba
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Imagen
              _buildImageWidget(context, hasImage, isAsset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, bool hasImage, bool isAsset) {
    if (!hasImage) {
      return _buildPlaceholder(context, 'Sin imagen');
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          isAsset
              ? Image.asset(
                  assetFallback!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(context, 'Gesto no encontrado'),
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _buildPlaceholder(context, 'No se pudo cargar'),
                ),
          // Overlay indicador de zoom
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String texto) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_rounded, size: 32, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Visor de imagen a pantalla completa con zoom
class _VisorImagen extends StatelessWidget {
  final String url;
  final String titulo;
  final bool isAsset;

  const _VisorImagen({
    required this.url,
    required this.titulo,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: isAsset
              ? Image.asset(url, fit: BoxFit.contain)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Chip de estadística
class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatChip(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


