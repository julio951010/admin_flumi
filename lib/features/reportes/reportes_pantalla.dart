import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import '../../core/modelo/reporte.dart';
import '../comun/widgets_comunes.dart';
import '../usuarios/usuario_detalle_pantalla.dart';
import 'reportes_servicio.dart';

/// Pantalla de moderación de reportes con filtros por estado.
class ReportesPantalla extends StatefulWidget {
  const ReportesPantalla({super.key});

  @override
  State<ReportesPantalla> createState() => _ReportesPantallaEstado();
}

class _ReportesPantallaEstado extends State<ReportesPantalla> {
  final _servicio = ReportesServicio(Supabase.instance.client);
  List<Reporte> _reportes = [];
  bool _cargando = true;
  String? _filtro;

  static const List<String> _estados = [
    'pendiente',
    'revisado',
    'desestimado',
    'resuelto',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _servicio.listar(estado: _filtro);
      if (!mounted) return;
      setState(() => _reportes = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Color _colorEstado(String e) => switch (e) {
        'pendiente' => Colors.orange,
        'revisado' => Colors.blue,
        'desestimado' => Colors.grey,
        'resuelto' => Colors.green,
        _ => Colors.grey,
      };

  String _capitalizar(String e) =>
      e.isEmpty ? e : e[0].toUpperCase() + e.substring(1);

  Future<void> _cambiarEstado(Reporte r, String nuevo) async {
    try {
      await _servicio.cambiarEstado(r.id, nuevo);
      if (!mounted) return;
      setState(() {
        final i = _reportes.indexOf(r);
        if (i != -1) {
          _reportes[i] = r.copyCon(
            estado: nuevo,
            resueltoEn: nuevo == 'pendiente' ? null : DateTime.now(),
          );
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Estado actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _suspender(Reporte r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Suspender usuario'),
        content: const Text('¿Suspender al usuario reportado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Suspender'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _servicio.suspenderReportado(r.reportadoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario suspendido')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reportes',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_reportes.length} mostrados',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          _filtros(),
          const SizedBox(height: 16),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _reportes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag_outlined,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Sin reportes'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _reportes.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _tarjeta(_reportes[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() => Wrap(
        spacing: 8,
        children: [
          _chipFiltro(null, 'Todos'),
          for (final e in _estados) _chipFiltro(e, _capitalizar(e)),
        ],
      );

  Widget _chipFiltro(String? valor, String etiqueta) {
    final activo = _filtro == valor;
    return FilterChip(
      label: Text(etiqueta),
      selected: activo,
      selectedColor: Tema.marca.withValues(alpha: 0.2),
      onSelected: (_) {
        setState(() => _filtro = valor);
        _cargar();
      },
    );
  }

  Widget _tarjeta(Reporte r) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ChipEstado(
                    texto: _capitalizar(r.estado),
                    color: _colorEstado(r.estado),
                    icono: Icons.flag,
                  ),
                  const Spacer(),
                  if (r.creadoEn != null)
                    Text(_formatoFecha(r.creadoEn!),
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Text('Motivo: ${r.motivo}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (r.descripcion != null && r.descripcion!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(r.descripcion!),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UsuarioDetallePantalla(id: r.reportadoId),
                      ),
                    ),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Ver perfil'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _suspender(r),
                    icon: const Icon(Icons.block),
                    label: const Text('Suspender'),
                  ),
                  _menuEstado(r),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _menuEstado(Reporte r) => PopupMenuButton<String>(
        onSelected: (nuevo) => _cambiarEstado(r, nuevo),
        itemBuilder: (_) => _estados
            .where((e) => e != r.estado)
            .map((e) => PopupMenuItem(
                  value: e,
                  child: Text('Marcar ${_capitalizar(e)}'),
                ))
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 6),
              Text('Cambiar estado'),
            ],
          ),
        ),
      );

  String _formatoFecha(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
