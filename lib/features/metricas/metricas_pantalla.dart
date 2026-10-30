import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import '../dashboard/dashboard_servicio.dart';
import '../dashboard/widgets/stat_card.dart';
import '../dashboard/widgets/stat_config.dart';
import 'chart_instalaciones_30d.dart';
import 'metricas_servicio.dart';

/// Página de métricas: instalaciones anónimas + registros de usuarios.
class MetricasPantalla extends StatefulWidget {
  const MetricasPantalla({super.key});

  @override
  State<MetricasPantalla> createState() => _MetricasPantallaState();
}

class _MetricasPantallaState extends State<MetricasPantalla> {
  final _servicioMetricas = MetricasServicio(Supabase.instance.client);
  final _servicioDashboard = DashboardServicio(Supabase.instance.client);

  MetricasInstalaciones? _metricas;
  DashboardStats? _stats;
  String? _errorMetricas;
  String? _errorStats;
  bool _cargando = true;
  DateTime? _actualizado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    MetricasInstalaciones? metricas;
    DashboardStats? stats;
    String? errorMetricas;
    String? errorStats;

    await Future.wait([
      () async {
        try {
          metricas = await _servicioMetricas.obtener();
        } catch (e) {
          errorMetricas = _mensaje(e);
        }
      }(),
      () async {
        try {
          stats = await _servicioDashboard.obtener();
        } catch (e) {
          errorStats = _mensaje(e);
        }
      }(),
    ]);

    if (!mounted) return;
    setState(() {
      _metricas = metricas;
      _stats = stats;
      _errorMetricas = errorMetricas;
      _errorStats = errorStats;
      _actualizado = DateTime.now();
      _cargando = false;
    });
  }

  String _mensaje(Object e) {
    final texto = e.toString();
    return texto.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: Tema.marca,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (_cargando && _metricas == null && _stats == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverToBoxAdapter(child: _buildContenido()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Métricas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
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
          onPressed: _cargando ? null : _cargar,
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

  Widget _buildContenido() {
    final metricas = _metricas;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_actualizado != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Actualizado ${_hora(_actualizado!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          if (metricas == null)
            _buildAvisoInstalaciones()
          else ...[
            _buildStatsGrid(metricas),
            const SizedBox(height: 20),
            _buildRegistrosCard(metricas),
            const SizedBox(height: 20),
            ChartInstalaciones30d(serie: metricas.serie30d),
            const SizedBox(height: 20),
            _buildVersionesCard(metricas),
          ],
          if (_errorStats != null) ...[
            const SizedBox(height: 16),
            _buildAviso(
              icono: Icons.people_outline_rounded,
              titulo: 'No se pudieron cargar los registros',
              detalle: _errorStats!,
            ),
          ],
          const SizedBox(height: 20),
          _buildNotaFirebase(),
        ],
      ),
    );
  }

  Widget _buildAvisoInstalaciones() {
    return _buildAviso(
      icono: Icons.cloud_off_rounded,
      titulo: 'Sin datos de instalaciones',
      detalle: _errorMetricas ??
          'Aplica supabase/metricas.sql en Supabase para habilitar las '
              'estadísticas de instalaciones.',
      accion: FilledButton.icon(
        onPressed: _cargando ? null : _cargar,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    );
  }

  Widget _buildAviso({
    required IconData icono,
    required String titulo,
    required String detalle,
    Widget? accion,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(icono, size: 40, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (accion != null) ...[
            const SizedBox(height: 16),
            accion,
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MetricasInstalaciones metricas) {
    final cards = [
      StatConfig(
        'Instalaciones',
        metricas.total,
        Icons.download_rounded,
        Tema.marca,
        trend: metricas.nuevasHoy > 0 ? '+${metricas.nuevasHoy} hoy' : null,
        trendPositive: true,
      ),
      StatConfig(
        'Activas 7d',
        metricas.activas7d,
        Icons.bolt_rounded,
        Colors.blue,
        trend: '${_pct(metricas.activas7d, metricas.total)}% del total',
        trendPositive: true,
      ),
      StatConfig(
        'Activas 30d',
        metricas.activas30d,
        Icons.calendar_month_rounded,
        Colors.teal,
        trend: '${_pct(metricas.activas30d, metricas.total)}% del total',
        trendPositive: true,
      ),
      StatConfig(
        'Nuevas 7d',
        metricas.nuevas7d,
        Icons.person_add_alt_1_rounded,
        Colors.green,
        trend: metricas.nuevasHoy > 0 ? '+${metricas.nuevasHoy} hoy' : 'esta semana',
        trendPositive: true,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.2,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => StatCard(config: cards[index]),
        );
      },
    );
  }

  Widget _buildRegistrosCard(MetricasInstalaciones metricas) {
    final stats = _stats;
    final colorScheme = Theme.of(context).colorScheme;

    if (stats == null) {
      return _buildAviso(
        icono: Icons.people_outline_rounded,
        titulo: 'Registros no disponibles',
        detalle: _errorStats ?? 'No se pudieron cargar los registros.',
      );
    }

    final conversion = _pct(stats.usuariosTotal, metricas.total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_rounded, size: 18, color: Tema.marca),
              const SizedBox(width: 8),
              Text(
                'Registros de usuarios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _miniStat('Usuarios totales', stats.usuariosTotal),
              _miniStat('Nuevos hoy', stats.usuariosHoy),
              _miniStat('Nuevos 7d', stats.usuarios7d),
              _miniStat('En línea', stats.enLinea),
              _miniStat('Conversión', conversion, sufijo: '%'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (conversion / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    color: Tema.marca,
                    backgroundColor:
                        colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${stats.usuariosTotal} registros / ${metricas.total} instalaciones',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String titulo, int valor, {String sufijo = ''}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$valor$sufijo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
        ),
        Text(
          titulo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildVersionesCard(MetricasInstalaciones metricas) {
    final colorScheme = Theme.of(context).colorScheme;
    final versiones = metricas.porVersion;
    final maxTotal = versiones.isEmpty
        ? 1
        : versiones.map((v) => v.total).reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_rounded, size: 18, color: Tema.marca),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Instalaciones por versión',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '${versiones.length} ${versiones.length == 1 ? 'versión' : 'versiones'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (versiones.isEmpty)
            Text(
              'Sin versiones registradas todavía.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ...versiones.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            v.version,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          '${v.total} · ${_pct(v.total, metricas.total)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: v.total / maxTotal,
                        minHeight: 8,
                        color: Tema.marca,
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotaFirebase() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Analytics y Crashlytics (sesiones, eventos y errores) se '
              'consultan en Firebase Console. Aquí se muestran las '
              'instalaciones anónimas registradas por la app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  int _pct(int parte, int total) {
    if (total <= 0) return 0;
    return ((parte / total) * 100).round();
  }

  String _hora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
