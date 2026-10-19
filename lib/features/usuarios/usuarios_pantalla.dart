import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import '../../core/modelo/usuario_admin.dart';
import 'usuario_detalle_pantalla.dart';
import 'usuarios_servicio.dart';
import 'widgets.dart';

class UsuariosPantalla extends StatefulWidget {
  const UsuariosPantalla({super.key});

  @override
  State<UsuariosPantalla> createState() => _UsuariosPantallaState();
}

class _UsuariosPantallaState extends State<UsuariosPantalla>
    with TickerProviderStateMixin {
  final _servicio = UsuariosServicio(Supabase.instance.client);
  final _busquedaCtrl = TextEditingController();
  final List<UsuarioAdmin> _usuarios = [];

  int _pagina = 0;
  bool _cargando = false;
  bool _cargandoInicial = true;
  bool _hayMas = true;
  static const int _porPagina = 20;

  String _filtroActivo = 'todos';
  String _ordenActivo = 'recientes';
  bool _vistaGrid = false;

  late final AnimationController _fadeController;
  late final AnimationController _staggerController;
  late final Animation<double> _fadeAnimation;

  DateTime? _ultimaActualizacion;

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
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _cargar(reiniciar: true);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool reiniciar = false}) async {
    if (_cargando) return;
    if (reiniciar) {
      _pagina = 0;
      _usuarios.clear();
      _hayMas = true;
    }
    setState(() {
      _cargando = true;
      if (reiniciar) _cargandoInicial = true;
    });
    try {
      final lista = await _servicio.listar(
        pagina: _pagina,
        porPagina: _porPagina,
        busqueda: _busquedaCtrl.text,
        filtro: _filtroActivo,
        orden: _ordenActivo,
      );
      if (!mounted) return;
      final filtrados = lista.where((u) => !_esUsuarioSistema(u)).toList();
      setState(() {
        _usuarios.addAll(filtrados);
        _hayMas = filtrados.length >= _porPagina;
        _pagina++;
        _ultimaActualizacion = DateTime.now();
      });
      if (reiniciar) {
        _fadeController.forward();
        _staggerController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
          _cargandoInicial = false;
        });
      }
    }
  }

  bool _esUsuarioSistema(UsuarioAdmin u) {
    return u.isAdmin ||
        u.nombre.toLowerCase().contains('flumi') ||
        u.nombre.toLowerCase().contains('administrador') ||
        u.nombre.toLowerCase().contains('admin') ||
        u.email.toLowerCase().contains('flumi') ||
        u.email.toLowerCase().contains('admin@');
  }

  void _onBusquedaChanged(String value) {
    if (value.isEmpty) {
      _cargar(reiniciar: true);
    }
  }

  void _onBusquedaSubmitted(String value) {
    _cargar(reiniciar: true);
  }

  void _cambiarFiltro(String filtro) {
    setState(() => _filtroActivo = filtro);
    _cargar(reiniciar: true);
  }

  void _cambiarOrden(String orden) {
    setState(() => _ordenActivo = orden);
    _cargar(reiniciar: true);
  }

  void _alternarVista() {
    setState(() => _vistaGrid = !_vistaGrid);
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
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Usuarios',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_ultimaActualizacion != null)
                Text(
                  'Actualizado ${_formatTime(_ultimaActualizacion!)} · ${_usuarios.length} usuarios',
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
          tooltip: _vistaGrid ? 'Ver lista' : 'Ver cuadrícula',
          onPressed: _alternarVista,
          icon: Icon(_vistaGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
        ),
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
      return const UsuariosSkeleton(vistaGrid: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsChips(colorScheme),
        const SizedBox(height: 16),
        _buildSearchAndFilters(colorScheme),
        const SizedBox(height: 16),
        _buildUserList(colorScheme),
      ],
    );
  }

  Widget _buildStatsChips(ColorScheme colorScheme) {
    final verificados = _usuarios.where((u) => u.verificadoStatus).length;
    final suspendidos = _usuarios.where((u) => u.suspendido).length;
    final admins = _usuarios.where((u) => u.isAdmin).length;
    final conFoto = _usuarios.where((u) => u.fotoPrincipal.isNotEmpty).length;

    final stats = [
      _StatChip('Total', _usuarios.length, Icons.people_rounded, Tema.marca),
      _StatChip('Verificados', verificados, Icons.verified_rounded, Colors.blue),
      _StatChip('Suspendidos', suspendidos, Icons.block_rounded, Colors.red),
      _StatChip('Con foto', conFoto, Icons.image_rounded, Colors.green),
      if (admins > 0)
        _StatChip('Admins', admins, Icons.admin_panel_settings_rounded, Colors.orange),
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stats.map((stat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildStatChip(stat, colorScheme),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildStatChip(_StatChip stat, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stat.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat.icon, size: 16, color: stat.color),
          const SizedBox(width: 6),
          Text(
            '${stat.label} ${stat.value}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: stat.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ColorScheme colorScheme) {
    return Column(
      children: [
        // Search field
        TextField(
          controller: _busquedaCtrl,
          decoration: InputDecoration(
            labelText: 'Buscar por nombre, email, ciudad...',
            hintText: 'Escribe para filtrar',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _busquedaCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _busquedaCtrl.clear();
                      _cargar(reiniciar: true);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          onChanged: _onBusquedaChanged,
          onSubmitted: _onBusquedaSubmitted,
        ),
        const SizedBox(height: 12),
        // Filter chips
        UsuariosFilters(
          filtroActivo: _filtroActivo,
          ordenActivo: _ordenActivo,
          onFiltroChanged: _cambiarFiltro,
          onOrdenChanged: _cambiarOrden,
        ),
      ],
    );
  }

  Widget _buildUserList(ColorScheme colorScheme) {
    if (_usuarios.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    if (_vistaGrid) {
      return _buildGridView(colorScheme);
    } else {
      return _buildListView(colorScheme);
    }
  }

  Widget _buildListView(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _usuarios.length + (_hayMas && !_cargando ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i >= _usuarios.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.tonal(
                    onPressed: _cargar,
                    child: const Text('Cargar más'),
                  ),
                ),
              );
            }
            final usuario = _usuarios[i];
            final animationIndex = i % 10;
            final animation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  animationIndex * 0.05,
                  0.5 + animationIndex * 0.05,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - animation.value)),
                  child: Opacity(
                    opacity: animation.value,
                    child: UsuarioCard(
                      usuario: usuario,
                      onTap: () => _abrirDetalle(usuario),
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

  Widget _buildGridView(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _usuarios.length + (_hayMas && !_cargando ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= _usuarios.length) {
              return Center(
                child: FilledButton.tonal(
                  onPressed: _cargar,
                  child: const Text('Cargar más'),
                ),
              );
            }
            final usuario = _usuarios[i];
            final animationIndex = i % 10;
            final animation = Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  animationIndex * 0.05,
                  0.5 + animationIndex * 0.05,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - animation.value)),
                  child: Opacity(
                    opacity: animation.value,
                    child: UsuarioCardGrid(
                      usuario: usuario,
                      onTap: () => _abrirDetalle(usuario),
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _busquedaCtrl.text.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _busquedaCtrl.text.isNotEmpty ? 'Sin resultados' : 'No hay usuarios',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _busquedaCtrl.text.isNotEmpty
                  ? 'No se encontraron usuarios para "${_busquedaCtrl.text}"'
                  : 'No hay usuarios registrados en el sistema',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            if (_busquedaCtrl.text.isNotEmpty)
              FilledButton.icon(
                onPressed: () {
                  _busquedaCtrl.clear();
                  _cargar(reiniciar: true);
                },
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Limpiar búsqueda'),
              ),
          ],
        ),
      ),
    );
  }

  void _abrirDetalle(UsuarioAdmin usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsuarioDetallePantalla(id: usuario.id),
      ),
    ).then((_) => _cargar(reiniciar: true));
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

class _StatChip {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatChip(this.label, this.value, this.icon, this.color);
}