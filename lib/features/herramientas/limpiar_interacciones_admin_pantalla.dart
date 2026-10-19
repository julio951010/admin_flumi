import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LimpiarInteraccionesAdminPantalla extends StatefulWidget {
  const LimpiarInteraccionesAdminPantalla({super.key});

  @override
  State<LimpiarInteraccionesAdminPantalla> createState() => _LimpiarInteraccionesAdminPantallaState();
}

class _LimpiarInteraccionesAdminPantallaState extends State<LimpiarInteraccionesAdminPantalla>
    with TickerProviderStateMixin {
  bool _limpiando = false;
  String? _resultado;
  bool _exito = false;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _limpiar() async {
    final confirmado = await _mostrarConfirmacion();
    if (confirmado != true) return;

    setState(() {
      _limpiando = true;
      _resultado = null;
      _exito = false;
    });
    _progressController.repeat();

    try {
      final res = await Supabase.instance.client.rpc('limpiar_interacciones_pruebas');
      if (!mounted) return;

      final ok = res is Map && res['ok'] == true;
      setState(() {
        _exito = ok;
        _resultado = ok
            ? 'Interacciones de prueba eliminadas correctamente.'
            : (res is Map ? (res['error']?.toString() ?? 'Error desconocido') : 'Error en la respuesta');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exito = false;
        _resultado = e.toString();
      });
    } finally {
      if (mounted) {
        _progressController.stop();
        _progressController.reset();
        setState(() => _limpiando = false);
      }
    }
  }

  Future<bool?> _mostrarConfirmacion() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Confirmar limpieza')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción es IRREVERSIBLE y eliminará permanentemente:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._itemsEliminados.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Colors.red.shade400),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
            const Divider(height: 20),
            const Text(
              'Se CONSERVAN:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
            ),
            const SizedBox(height: 8),
            ..._itemsConservados.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Solo para entornos de prueba. No usar en producción.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpiar todo'),
          ),
        ],
      ),
    );
  }

  static const List<String> _itemsEliminados = [
    'Nopes (rechazos / tabla nopes)',
    'Me Gusta / historial_likes',
    'Visitas de perfiles',
    'Matches entre usuarios',
    'Mensajes de chat',
    'Bloqueos entre usuarios',
    'Reportes de usuarios',
    'Usos diarios / contadores',
    'Pagos pendientes',
  ];

  static const List<String> _itemsConservados = [
    'Perfiles de usuarios (profiles)',
    'Suscripciones (Plus, Premium)',
    'Pagos aprobados y rechazados',
    'Configuración de la app (feature flags)',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
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
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Limpiar interacciones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Mantenimiento · Pruebas',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withValues(alpha: 0.08),
                Colors.red.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Advertencia superior
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acción destructiva e irreversible',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solo para entornos de desarrollo/pruebas. Ejecuta tool/limpiar_remoto.sql en Supabase.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Qué se elimina
        _buildSection(
          title: 'Se ELIMINAN (irreversible)',
          icon: Icons.delete_outline_rounded,
          color: Colors.red,
          items: _itemsEliminados,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),

        // Qué se conserva
        _buildSection(
          title: 'Se CONSERVAN (seguros)',
          icon: Icons.shield_outlined,
          color: Colors.green,
          items: _itemsConservados,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),

        // Botón de acción
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _limpiando
              ? _buildProgressCard(colorScheme)
              : _buildActionCard(colorScheme),
        ),

        if (_resultado != null) ...[
          const SizedBox(height: 16),
          _buildResultadoCard(colorScheme),
        ],

        const SizedBox(height: 16),
        // Referencia técnica
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.code_outlined, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Equivale a ejecutar: tool/limpiar_remoto.sql en Supabase SQL Editor',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                color == Colors.red ? Icons.remove_circle_outline : Icons.check_circle_outline,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionCard(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('action'),
        onPressed: _limpiar,
        icon: const Icon(Icons.delete_forever_rounded, size: 20),
        label: const Text('Limpiar interacciones del servidor'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProgressCard(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          key: const ValueKey('progress'),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Ejecutando limpieza en el servidor...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressController.value,
                      minHeight: 8,
                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultadoCard(ColorScheme colorScheme) {
    final isError = !_exito;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isError ? Colors.red : Colors.green).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isError ? Colors.red : Colors.green).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.red : Colors.green,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _resultado!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!isError)
            IconButton(
              tooltip: 'Limpiar de nuevo',
              onPressed: () => setState(() => _resultado = null),
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}