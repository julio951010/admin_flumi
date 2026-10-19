import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

/// Gestión de las redes sociales oficiales (Nuestras redes en flumi_app >
/// Configuración > Sobre nosotros). Crear, editar, activar/desactivar,
/// reordenar y eliminar. El icono es una clave que la app mapea a
/// IconData+color (ver estiloRed en flumi_app).
class RedesPantalla extends StatefulWidget {
  const RedesPantalla({super.key});

  @override
  State<RedesPantalla> createState() => _RedesPantallaState();
}

class _Red {
  final String id;
  String nombre;
  String usuario;
  String url;
  String icono;
  int orden;
  bool activo;

  _Red({
    required this.id,
    required this.nombre,
    required this.usuario,
    required this.url,
    required this.icono,
    required this.orden,
    required this.activo,
  });

  factory _Red.fromMap(Map<String, dynamic> m) => _Red(
        id: (m['id'] as String?) ?? '',
        nombre: (m['nombre'] as String?) ?? '',
        usuario: (m['usuario'] as String?) ?? '',
        url: (m['url'] as String?) ?? '',
        icono: (m['icono'] as String?) ?? 'web',
        orden: (m['orden'] as int?) ?? 0,
        activo: (m['activo'] as bool?) ?? true,
      );
}

class _RedesPantallaState extends State<RedesPantalla> {
  /// Claves de icono válidas (deben coincidir con estiloRed en flumi_app).
  static const _iconos = [
    'telegram',
    'whatsapp',
    'instagram',
    'facebook',
    'x',
    'tiktok',
    'youtube',
    'web',
  ];

  List<_Red> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('redes_sociales')
          .select('id,nombre,usuario,url,icono,orden,activo')
          .order('orden')
          .order('nombre');
      final items = (res as List)
          .map((e) => _Red.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      if (mounted) {
        setState(() {
          _items = items;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando: $e';
          _cargando = false;
        });
      }
    }
  }

  void _aviso(String texto, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? Colors.red.shade700 : null,
    ));
  }

  Future<void> _alternarActivo(_Red r, bool valor) async {
    final anterior = r.activo;
    setState(() => r.activo = valor);
    try {
      await Supabase.instance.client.from('redes_sociales').update({
        'activo': valor,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', r.id);
    } catch (e) {
      setState(() => r.activo = anterior);
      _aviso('Error guardando: $e', error: true);
    }
  }

  Future<void> _editar([_Red? existente]) async {
    final esNuevo = existente == null;
    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final usuarioCtrl =
        TextEditingController(text: existente?.usuario ?? '');
    final urlCtrl = TextEditingController(text: existente?.url ?? '');
    final ordenCtrl = TextEditingController(
        text: (existente?.orden ?? (_items.length + 1)).toString());
    String icono = existente?.icono ?? 'web';
    bool activo = existente?.activo ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(esNuevo ? 'Agregar red' : 'Editar red'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nombre (ej. Telegram)'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usuarioCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Usuario visible (ej. @flumi)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                        labelText: 'URL (ej. https://t.me/flumi)'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _iconos.contains(icono) ? icono : 'web',
                    decoration:
                        const InputDecoration(labelText: 'Icono'),
                    items: _iconos
                        .map((k) => DropdownMenuItem(
                            value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) =>
                        setDialog(() => icono = v ?? 'web'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ordenCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Orden (menor sale primero)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: activo,
                    onChanged: (v) => setDialog(() => activo = v),
                    title: const Text('Activa (visible en la app)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Tema.marca),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final nombre = nombreCtrl.text.trim();
    final url = urlCtrl.text.trim();
    if (nombre.isEmpty || url.isEmpty) {
      _aviso('Nombre y URL son obligatorios.', error: true);
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      _aviso('La URL debe empezar con http(s)://', error: true);
      return;
    }

    try {
      final fila = {
        'nombre': nombre,
        'usuario': usuarioCtrl.text.trim(),
        'url': url,
        'icono': icono,
        'orden': int.tryParse(ordenCtrl.text.trim()) ?? 0,
        'activo': activo,
        'actualizado_en': DateTime.now().toIso8601String(),
      };
      if (esNuevo) {
        await Supabase.instance.client.from('redes_sociales').insert(fila);
      } else {
        await Supabase.instance.client
            .from('redes_sociales')
            .update(fila)
            .eq('id', existente.id);
      }
      _aviso('Red guardada');
      await _cargar();
    } catch (e) {
      _aviso('Error guardando: $e', error: true);
    }
  }

  Future<void> _eliminar(_Red r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar red'),
        content: Text(
            '¿Eliminar "${r.nombre}"? Desaparecerá de la app. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await Supabase.instance.client
          .from('redes_sociales')
          .delete()
          .eq('id', r.id);
      _aviso('Red eliminada');
      await _cargar();
    } catch (e) {
      _aviso('Error eliminando: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redes sociales'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargando ? null : _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        backgroundColor: Tema.marca,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
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
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: _cargar,
                            child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                          'Sin redes. Usa "Agregar" para publicar la primera.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _items[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Tema.marca.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.share_outlined,
                                  color: Tema.marca),
                            ),
                            title: Text(r.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${r.usuario.isEmpty ? "—" : r.usuario}  ·  orden ${r.orden}  ·  ${r.activo ? "activa" : "oculta"}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: r.activo
                                      ? Colors.grey[600]
                                      : Colors.orange[800]),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: r.activo,
                                  onChanged: (v) =>
                                      _alternarActivo(r, v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Editar',
                                  onPressed: () => _editar(r),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Eliminar',
                                  onPressed: () => _eliminar(r),
                                ),
                              ],
                            ),
                            onTap: () => _editar(r),
                          ),
                        );
                      },
                    ),
    );
  }
}
