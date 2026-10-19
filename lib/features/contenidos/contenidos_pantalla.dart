import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

/// Edición de los contenidos de Sobre Nosotros (términos, privacidad,
/// contactos...). Se muestran en flumi_app > Configuración > Sobre nosotros.
/// Los párrafos se separan con una línea en blanco.
class ContenidosPantalla extends StatefulWidget {
  const ContenidosPantalla({super.key});

  @override
  State<ContenidosPantalla> createState() => _ContenidosPantallaState();
}

class _Contenido {
  final String clave;
  final String titulo;
  String cuerpo;

  _Contenido({required this.clave, required this.titulo, required this.cuerpo});

  factory _Contenido.fromMap(Map<String, dynamic> m) => _Contenido(
        clave: (m['clave'] as String?) ?? '',
        titulo: (m['titulo'] as String?) ?? '',
        cuerpo: (m['cuerpo'] as String?) ?? '',
      );
}

class _ContenidosPantallaState extends State<ContenidosPantalla> {
  static const _orden = [
    'terminos',
    'privacidad',
    'seguridad_infantil',
    'licencias',
    'contactos',
    'sobre_flumi',
  ];

  List<_Contenido> _items = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await Supabase.instance.client
          .from('contenidos_legales')
          .select('clave,titulo,cuerpo')
          .order('clave');
      final todos = (res as List)
          .map((e) => _Contenido.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      todos.sort((a, b) =>
          _orden.indexOf(a.clave).compareTo(_orden.indexOf(b.clave)));
      setState(() { _items = todos; _cargando = false; });
    } catch (e) {
      setState(() { _error = 'Error cargando: $e'; _cargando = false; });
    }
  }

  Future<void> _editar(_Contenido c) async {
    final ctrl = TextEditingController(text: c.cuerpo);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c.titulo),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: ctrl,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: 'Escribe el contenido. Separa párrafos con una línea en blanco.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Tema.marca),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.from('contenidos_legales').upsert({
        'clave': c.clave,
        'titulo': c.titulo,
        'cuerpo': ctrl.text.trim(),
        'actualizado_en': DateTime.now().toIso8601String(),
      }, onConflict: 'clave');
      setState(() => c.cuerpo = ctrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contenido guardado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error guardando: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contenidos · Sobre Nosotros'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargando ? null : _cargar),
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
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    final preview = c.cuerpo.trim().isEmpty
                        ? 'Sin contenido'
                        : c.cuerpo.trim().split('\n').first;
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
                            color:
                                Tema.marca.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_outlined,
                              color: Tema.marca),
                        ),
                        title: Text(c.titulo,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: c.cuerpo.trim().isEmpty
                                  ? Colors.orange[800]
                                  : Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _editar(c),
                      ),
                    );
                  },
                ),
    );
  }
}
