import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tema.dart';
import '../../core/auth/admin_sesion.dart';
import 'admin_responsive.dart';
import '../configuracion/feature_flags_pantalla.dart';
import '../contenidos/contenidos_pantalla.dart';
import '../dashboard/dashboard_pantalla.dart';
import '../herramientas/herramientas_pantalla.dart';
import '../metricas/metricas_pantalla.dart';
import '../pagos/pagos_config_pantalla.dart';
import '../pagos/pagos_pendientes_pantalla.dart';
import '../redes/redes_pantalla.dart';
import '../reportes/reportes_pantalla.dart';
import '../sobre/sobre_nosotros_pantalla.dart';
import '../soporte/soporte_pantalla.dart';
import '../verificaciones/verificaciones_pantalla.dart';
import '../usuarios/usuarios_pantalla.dart';
import 'sin_conexion_pantalla.dart';

/// Layout admin: sidebar fijo en web (ancho) o drawer en móvil.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _indice = 0;
  bool _sidebarExpandido = true;

  final List<_Seccion> _secciones = const [
    _Seccion(Icons.dashboard_outlined, 'Dashboard', DashboardPantalla()),
    _Seccion(Icons.insights_rounded, 'Métricas', MetricasPantalla()),
    _Seccion(Icons.people, 'Usuarios', UsuariosPantalla()),
    _Seccion(Icons.flag, 'Reportes', ReportesPantalla()),
    _Seccion(Icons.support_agent, 'Soporte', SoportePantalla()),
    _Seccion(Icons.verified_outlined, 'Verificaciones', VerificacionesPantalla()),
    _Seccion(Icons.payments, 'Método de pago', PagosConfigPantalla()),
    _Seccion(Icons.receipt_long, 'Pagos pendientes', PagosPendientesPantalla()),
    _Seccion(Icons.build_outlined, 'Herramientas', HerramientasPantalla()),
    _Seccion(Icons.article_outlined, 'Contenidos', ContenidosPantalla()),
    _Seccion(Icons.share_outlined, 'Redes sociales', RedesPantalla()),
    _Seccion(Icons.info_outline, 'Sobre nosotros', SobreNosotrosPantalla()),
    _Seccion(Icons.settings, 'Feature Flags', FeatureFlagsPantalla()),
  ];

  void _seleccionar(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900 && !AdminBreakpoints.isMobile(constraints.maxWidth)) {
          return _buildDesktop();
        } else if (constraints.maxWidth >= 600 && constraints.maxWidth < 900) {
          return _buildTablet();
        } else {
          return _buildMobile();
        }
      },
    );
  }

  Widget _buildDesktop() {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _SidebarDesktop(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const BannerSinConexion(),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _secciones[_indice].pantalla,
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

  Widget _buildTablet() {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _sidebarExpandido ? 260 : 72,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _SidebarTablet(),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const BannerSinConexion(),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: _secciones[_indice].pantalla,
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

  Widget _buildMobile() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Flumi'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: _SidebarMobile(),
      ),
      body: Column(
        children: [
          const BannerSinConexion(),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _secciones[_indice].pantalla,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _SidebarDesktop() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _secciones.length + 4,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) return _encabezado(context.read<AdminSesion>());
        if (index == 1) return const Divider(height: 1);
        if (index == _secciones.length + 2) return const Divider(height: 1);
        if (index == _secciones.length + 3) return _cerrarSesion(context.read<AdminSesion>());
        final i = index - 2;
        if (i < 0 || i >= _secciones.length) return const SizedBox.shrink();
        return _item(
          _secciones[i].icono,
          _secciones[i].etiqueta,
          _indice == i,
          () => _seleccionar(i),
        );
      },
    );
  }

  Widget _SidebarTablet() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _secciones.length + 4,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) return _encabezado(context.read<AdminSesion>());
        if (index == 1) return const Divider(height: 1);
        if (index == _secciones.length + 2) return const Divider(height: 1);
        if (index == _secciones.length + 3) return _cerrarSesion(context.read<AdminSesion>());
        final i = index - 2;
        if (i < 0 || i >= _secciones.length) return const SizedBox.shrink();
        return _itemColapsable(
          _secciones[i].icono,
          _secciones[i].etiqueta,
          _indice == i,
          () => _seleccionar(i),
        );
      },
    );
  }

  Widget _SidebarMobile() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _secciones.length + 4,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) return _encabezado(context.read<AdminSesion>());
        if (index == 1) return const Divider(height: 1);
        if (index == _secciones.length + 2) return const Divider(height: 1);
        if (index == _secciones.length + 3) return _cerrarSesion(context.read<AdminSesion>());
        final i = index - 2;
        if (i < 0 || i >= _secciones.length) return const SizedBox.shrink();
        return _item(
          _secciones[i].icono,
          _secciones[i].etiqueta,
          _indice == i,
          () => _seleccionar(i),
        );
      },
    );
  }

  Widget _encabezado(AdminSesion sesion) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Tema.marca.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Tema.marca),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Flumi',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    sesion.perfil?.nombre ?? sesion.user?.email ?? '',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (AdminBreakpoints.isTablet(MediaQuery.of(context).size.width))
              IconButton(
                icon: Icon(_sidebarExpandido ? Icons.chevron_left : Icons.chevron_right),
                onPressed: () => setState(() => _sidebarExpandido = !_sidebarExpandido),
                tooltip: _sidebarExpandido ? 'Colapsar menú' : 'Expandir menú',
              ),
          ],
        ),
      );

  Widget _item(IconData icon, String label, bool activo, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: activo ? Tema.marca : null),
          title: Text(label),
          selected: activo,
          selectedTileColor: Tema.marca.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
        ),
      );

  /// Item colapsable para tablet (solo icono cuando colapsado)
  Widget _itemColapsable(IconData icon, String label, bool activo, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: Tema.marca),
          title: _sidebarExpandido ? Text(label) : null,
          selected: activo,
          selectedTileColor: Tema.marca.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: onTap,
        ),
      );

  Widget _cerrarSesion(AdminSesion sesion) => Material(
        color: Colors.transparent,
        child: ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onTap: () => sesion.logout(),
        ),
      );

  @override
  void dispose() {
    super.dispose();
  }
}

class _Seccion {
  final IconData icono;
  final String etiqueta;
  final Widget pantalla;

  const _Seccion(this.icono, this.etiqueta, this.pantalla);
}