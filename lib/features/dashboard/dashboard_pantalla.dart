import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import '../metricas/chart_instalaciones_30d.dart';
import '../metricas/metricas_servicio.dart';
import 'dashboard_servicio.dart';
import 'widgets.dart';

/// Panel principal: usuarios, actividad, pendientes y serie de 7 días.
class DashboardPantalla extends StatefulWidget {
  const DashboardPantalla({super.key});

  @override
  State<DashboardPantalla> createState() => _DashboardEstado();
}

class _DashboardEstado extends State<DashboardPantalla> with TickerProviderStateMixin {
  late final DashboardServicio _servicio = DashboardServicio(Supabase.instance.client);
  late final MetricasServicio _servicioMetricas = MetricasServicio(Supabase.instance.client);
  DashboardStats? _stats;
  MetricasInstalaciones? _instalaciones;
  String? _error;
  DateTime? _actualizado;
  bool _cargando = true;

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
      16,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            (index * 0.05).clamp(0.0, 0.7),
            ((index * 0.05) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
    _cargar();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<(DashboardStats, MetricasInstalaciones?)> _obtenerTodo() async {
    // Las dos llamadas arrancan en paralelo. Si la RPC de instalaciones aún
    // no existe, `obtenerOpcional` devuelve null y el dashboard sigue igual.
    final statsF = _servicio.obtener();
    final instF = _servicioMetricas.obtenerOpcional();
    final stats = await statsF;
    final instalaciones = await instF;
    return (stats, instalaciones);
  }

  Future<void> _refrescar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final (stats, instalaciones) = await _obtenerTodo();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _instalaciones = instalaciones;
        _actualizado = DateTime.now();
        _error = null;
      });
      _staggerController.reset();
      _staggerController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final (stats, instalaciones) = await _obtenerTodo();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _instalaciones = instalaciones;
        _actualizado = DateTime.now();
        _error = null;
      });
      _fadeController.forward();
      _staggerController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _stats == null) {
      return const Scaffold(body: SkeletonDashboard());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refrescar,
        color: Tema.marca,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: FadeTransition(
          opacity: _fadeController,
          child: Text(
            'Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
          onPressed: _cargando ? null : _refrescar,
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

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildChartSection(),
          if (_instalaciones != null) ...[
            const SizedBox(height: 24),
            _buildInstallChart(),
          ],
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _stats!;
    final inst = _instalaciones;
    final cards = [
      StatConfig(
        'Usuarios totales',
        stats.usuariosTotal,
        Icons.people_rounded,
        Tema.marca,
        trend: stats.usuariosHoy > 0 ? '+${stats.usuariosHoy} hoy' : null,
        trendPositive: true,
      ),
      StatConfig(
        'Nuevos (7d)',
        stats.usuarios7d,
        Icons.person_add_rounded,
        Colors.green,
        trend: '+${stats.usuariosHoy} hoy',
        trendPositive: true,
      ),
      if (inst != null) ...[
        StatConfig(
          'Instalaciones',
          inst.total,
          Icons.download_rounded,
          Colors.indigo,
          trend: inst.nuevasHoy > 0 ? '+${inst.nuevasHoy} hoy' : null,
          trendPositive: true,
        ),
        StatConfig(
          'Instal. activas',
          inst.activas30d,
          Icons.bolt_rounded,
          Colors.teal,
          trend: 'últimos 30d',
          trendPositive: true,
        ),
        StatConfig(
          'Nuevas inst. 7d',
          inst.nuevas7d,
          Icons.person_add_alt_1_rounded,
          Colors.lightGreen,
          trend: inst.nuevasHoy > 0 ? '+${inst.nuevasHoy} hoy' : null,
          trendPositive: true,
        ),
      ],
      StatConfig(
        'En línea',
        stats.enLinea,
        Icons.circle_rounded,
        Colors.blue,
        trend: '${((stats.enLinea / stats.usuariosTotal) * 100).toStringAsFixed(1)}%',
        trendPositive: true,
      ),
      StatConfig(
        'Verificados',
        stats.verificados,
        Icons.verified_rounded,
        Colors.amber,
        trend: '${((stats.verificados / stats.usuariosTotal) * 100).toStringAsFixed(1)}%',
        trendPositive: true,
      ),
      StatConfig(
        'Matches',
        stats.matchesTotal,
        Icons.favorite_rounded,
        Colors.pink,
        trend: '+${stats.likesHoy} likes hoy',
        trendPositive: true,
      ),
      StatConfig(
        'Mensajes',
        stats.mensajesTotal,
        Icons.chat_bubble_rounded,
        Colors.orange,
        trend: '+${stats.mensajesHoy} hoy',
        trendPositive: true,
      ),
      StatConfig(
        'Reportes pend.',
        stats.reportesPendientes,
        Icons.flag_rounded,
        stats.reportesPendientes > 0 ? Colors.red : Colors.green,
        trend: stats.reportesPendientes > 0 ? 'Requiere atención' : 'Todo claro',
        trendPositive: stats.reportesPendientes == 0,
      ),
      StatConfig(
        'Soportes pend.',
        stats.soportesPendientes,
        Icons.support_agent_rounded,
        stats.soportesPendientes > 0 ? Colors.deepOrange : Colors.green,
        trend: stats.soportesPendientes > 0 ? 'Requiere atención' : 'Todo claro',
        trendPositive: stats.soportesPendientes == 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;
        return FadeTransition(
          opacity: _fadeController,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth > 600 ? 1.4 : 1.2,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final config = cards[index];
              return AnimatedBuilder(
                animation: _cardAnimations[index],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - _cardAnimations[index].value)),
                    child: Opacity(
                      opacity: _cardAnimations[index].value,
                      child: StatCard(config: config),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChartSection() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _staggerController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
        )),
        child: Chart7D(serie: _stats!.serie7d),
      ),
    );
  }

  Widget _buildInstallChart() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _staggerController,
          curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
        )),
        child: ChartInstalaciones30d(serie: _instalaciones!.serie30d),
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _fadeController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _staggerController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
        )),
        child: QuickActions(
          reportesPendientes: _stats!.reportesPendientes,
          soportesPendientes: _stats!.soportesPendientes,
          pagosPendientes: _stats!.pagosPendientes,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _refrescar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}