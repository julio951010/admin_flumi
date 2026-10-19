import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

/// Control del estado global de flumi_app: modo mantenimiento y versión
/// mínima obligatoria. Escribe en `public.app_config` (requiere ser admin).
class EstadoAppPantalla extends StatefulWidget {
  const EstadoAppPantalla({super.key});

  @override
  State<EstadoAppPantalla> createState() => _EstadoAppPantallaState();
}

class _EstadoAppPantallaState extends State<EstadoAppPantalla> {
  bool _cargando = true;
  String? _error;
  bool _guardando = false;

  bool _mantenimiento = false;
  final _mensajeMantCtrl = TextEditingController();
  int _versionMinima = 1;
  final _urlCtrl = TextEditingController();
  final _mensajeActCtrl = TextEditingController();

  static const _claves = [
    'mantenimiento',
    'mantenimiento_mensaje',
    'version_minima_build',
    'actualizar_url',
    'actualizar_mensaje',
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _mensajeMantCtrl.dispose();
    _urlCtrl.dispose();
    _mensajeActCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('clave,valor')
          .inFilter('clave', _claves);
      final mapa = {
        for (final r in (res as List).cast<Map<String, dynamic>>())
          (r['clave'] as String?) ?? '': (r['valor'] as String?) ?? ''
      };
      setState(() {
        _mantenimiento = (mapa['mantenimiento'] ?? 'false') == 'true';
        _mensajeMantCtrl.text = mapa['mantenimiento_mensaje'] ?? '';
        _versionMinima = int.tryParse(mapa['version_minima_build'] ?? '1') ?? 1;
        _urlCtrl.text = mapa['actualizar_url'] ?? '';
        _mensajeActCtrl.text = mapa['actualizar_mensaje'] ?? '';
        _cargando = false;
      });
    } catch (e) {
      setState(() { _error = 'Error cargando: $e'; _cargando = false; });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final filas = [
        {'clave': 'mantenimiento', 'valor': _mantenimiento.toString(), 'tipo': 'feature'},
        {'clave': 'mantenimiento_mensaje', 'valor': _mensajeMantCtrl.text.trim(), 'tipo': 'feature'},
        {'clave': 'version_minima_build', 'valor': _versionMinima.toString(), 'tipo': 'feature'},
        {'clave': 'actualizar_url', 'valor': _urlCtrl.text.trim(), 'tipo': 'feature'},
        {'clave': 'actualizar_mensaje', 'valor': _mensajeActCtrl.text.trim(), 'tipo': 'feature'},
      ];
      for (final f in filas) {
        await Supabase.instance.client.from('app_config').upsert(f, onConflict: 'clave');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Estado guardado. Se aplica en vivo.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error guardando: $e')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de la app'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargando ? null : _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _card(
                      titulo: 'Mantenimiento',
                      icono: Icons.build_outlined,
                      descripcion:
                          'Bloquea toda la app con la página de mantenimiento. Al desactivar, la app vuelve sola (en vivo).',
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Modo mantenimiento'),
                            subtitle: Text(_mantenimiento ? 'ACTIVO: la app no se puede usar' : 'Inactivo'),
                            value: _mantenimiento,
                            onChanged: (v) => setState(() => _mantenimiento = v),
                            activeColor: Tema.marca,
                          ),
                          TextField(
                            controller: _mensajeMantCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Mensaje para los usuarios',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      titulo: 'Versión mínima',
                      icono: Icons.system_update_outlined,
                      descripcion:
                          'Builds por debajo de este número ven la página de actualización obligatoria con el botón de descarga. Debe coincidir con el +N del version de pubspec.yaml de la release publicada (hoy: 0.1.0+1 → build 1).',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text('Build mínimo:'),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _versionMinima > 1
                                    ? () => setState(() => _versionMinima--)
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('$_versionMinima',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                onPressed: () => setState(() => _versionMinima++),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _urlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'URL de descarga del APK',
                              hintText: 'https://.../flumi.apk',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _mensajeActCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Mensaje de actualización',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, size: 18),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Tema.marca,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _card({
    required String titulo,
    required IconData icono,
    required String descripcion,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Tema.marca.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, color: Tema.marca),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(descripcion,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
