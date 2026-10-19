import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import '../../core/conectividad/conectividad_servicio.dart';
import '../comun/sin_conexion_pantalla.dart';

class FeatureFlagsPantalla extends StatefulWidget {
  const FeatureFlagsPantalla({super.key});

  @override
  State<FeatureFlagsPantalla> createState() => _FeatureFlagsPantallaState();
}

class _FeatureFlagsPantallaState extends State<FeatureFlagsPantalla> {
  List<_Flag> _flags = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Claves booleanas (se editan con Switch y se guardan como
  /// 'true'/'false', que es como las lee flumi_app). El resto son texto.
  /// (La tabla viva solo tiene clave/valor/tipo; no hay columnas de
  /// descripción ni auditoría.)
  static const _boolKeys = {'suscripciones_habilitadas', 'mantenimiento'};

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('clave,valor,tipo')
          .order('clave');
      setState(() {
        _flags = (res as List)
            .map((e) => _Flag.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando flags: $e';
        _cargando = false;
      });
    }
  }

  Future<void> _toggleBool(_Flag flag, bool nuevo) async {
    final anterior = flag.valor;
    setState(() => flag.valor = nuevo ? 'true' : 'false');
    try {
      await Supabase.instance.client.from('app_config').upsert({
        'clave': flag.clave,
        'valor': nuevo ? 'true' : 'false',
        'tipo': flag.tipo,
      }, onConflict: 'clave');
      await _cargar();
    } catch (e) {
      setState(() => flag.valor = anterior);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    }
  }

  Future<void> _editarString(_Flag flag) async {
    final ctrl = TextEditingController(text: flag.valorString);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar ${flag.clave}'),
        content: TextField(
          controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Valor',
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _guardarString(flag, ctrl.text.trim());
  }

  Future<void> _guardarString(_Flag flag, String nuevo) async {
    final anterior = flag.valorString;
    setState(() => flag.valor = nuevo);
    try {
      await Supabase.instance.client.from('app_config').upsert({
        'clave': flag.clave,
        'valor': nuevo,
        'tipo': flag.tipo,
      }, onConflict: 'clave');
      await _cargar();
    } catch (e) {
      setState(() => flag.valor = anterior); // revertir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enLinea = context.watch<ConectividadServicio>().enLinea;
    if (!enLinea && _flags.isEmpty) {
      return const SinConexionPantalla();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargar,
            tooltip: 'Recargar',
          ),
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
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _flags.isEmpty
                  ? const Center(child: Text('Sin flags configurados'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flags.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final flag = _flags[i];
                        final esBool =
                            _boolKeys.contains(flag.clave);
                        return _FlagTile(
                          flag: flag,
                          onToggle: esBool
                              ? (v) => _toggleBool(flag, v)
                              : null,
                          onEditarString: !esBool
                              ? () => _editarString(flag)
                              : null,
                        );
                      },
                    ),
    );
  }
}

class _Flag {
  final String clave;
  dynamic valor;
  final String tipo;

  _Flag({
    required this.clave,
    required this.valor,
    required this.tipo,
  });

  factory _Flag.fromMap(Map<String, dynamic> m) => _Flag(
        clave: m['clave'] as String,
        valor: m['valor'],
        tipo: m['tipo'] as String? ?? 'config',
      );

  bool get valorBool => valor == true || valor == 'true';
  String get valorString => valor?.toString() ?? '';
}

class _FlagTile extends StatelessWidget {
  final _Flag flag;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onEditarString;

  const _FlagTile({
    required this.flag,
    this.onToggle,
    this.onEditarString,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Tema.marca.withValues(alpha: 0.12),
        child: Icon(
          onToggle != null ? Icons.toggle_on : Icons.code,
          color: Tema.marca,
        ),
      ),
      title: Text(
        flag.clave,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flag.valorString.isEmpty ? '(vacío)' : flag.valorString,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: onToggle != null
          ? Switch(
              value: flag.valorBool,
              onChanged: onToggle,
              activeColor: Tema.marca,
            )
          : onEditarString != null
              ? IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEditarString,
                  tooltip: 'Editar valor',
                )
              : null,
      isThreeLine: true,
    );
  }
}