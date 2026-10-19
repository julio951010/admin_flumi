import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

/// Gestión del contenido de "Sobre nosotros" en flumi_app:
/// visibilidad de los botones (Invitar/Valorar/Descargar/Donar) y el
/// contenido de cada uno (mensajes, URLs, cuenta y teléfono de donación).
/// Todo vive en `public.app_config` (tipo 'config') y llega en vivo a la app.
class SobreNosotrosPantalla extends StatefulWidget {
  const SobreNosotrosPantalla({super.key});

  @override
  State<SobreNosotrosPantalla> createState() => _SobreNosotrosPantallaState();
}

class _SobreNosotrosPantallaState extends State<SobreNosotrosPantalla> {
  static const _claves = [
    'invitacion_mensaje',
    'descarga_url',
    'valorar_url',
    'donacion_mensaje',
    'donacion_cuenta',
    'donacion_telefono',
    'mostrar_invitar',
    'mostrar_valorar',
    'mostrar_descargar',
    'mostrar_donar',
  ];

  final Map<String, String> _valores = {};
  bool _cargando = true;
  String? _error;

  final _invitacionCtrl = TextEditingController();
  final _descargaCtrl = TextEditingController();
  final _valorarCtrl = TextEditingController();
  final _donacionMsgCtrl = TextEditingController();
  final _donacionCuentaCtrl = TextEditingController();
  final _donacionTelCtrl = TextEditingController();

  @override
  void dispose() {
    _invitacionCtrl.dispose();
    _descargaCtrl.dispose();
    _valorarCtrl.dispose();
    _donacionMsgCtrl.dispose();
    _donacionCuentaCtrl.dispose();
    _donacionTelCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _v(String clave) => _valores[clave] ?? '';
  bool _vb(String clave) => _v(clave).toLowerCase() == 'true';

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('clave,valor')
          .inFilter('clave', _claves);
      final mapa = <String, String>{};
      for (final f in (res as List)) {
        final m = Map<String, dynamic>.from(f as Map);
        mapa[(m['clave'] as String?) ?? ''] =
            (m['valor'] as String?) ?? '';
      }
      if (!mounted) return;
      setState(() {
        _valores
          ..clear()
          ..addAll(mapa);
        _invitacionCtrl.text = _v('invitacion_mensaje');
        _descargaCtrl.text = _v('descarga_url');
        _valorarCtrl.text = _v('valorar_url');
        _donacionMsgCtrl.text = _v('donacion_mensaje');
        _donacionCuentaCtrl.text = _v('donacion_cuenta');
        _donacionTelCtrl.text = _v('donacion_telefono');
        _cargando = false;
      });
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

  /// Guarda un grupo de claves (upsert; crea las que falten).
  Future<void> _guardarGrupo(Map<String, String> valores) async {
    try {
      await Supabase.instance.client.from('app_config').upsert(
            valores.entries
                .map((e) => {
                      'clave': e.key,
                      'valor': e.value,
                      'tipo': 'config',
                    })
                .toList(),
            onConflict: 'clave',
          );
      if (mounted) {
        setState(() => _valores.addAll(valores));
        _aviso('Guardado. Llega a la app en segundos.');
      }
    } catch (e) {
      _aviso('Error guardando: $e', error: true);
    }
  }

  /// Los switches de visibilidad se guardan de inmediato.
  Future<void> _alternarVisible(String clave, bool v) async {
    final anterior = _v(clave);
    setState(() => _valores[clave] = v ? 'true' : 'false');
    try {
      await Supabase.instance.client.from('app_config').upsert({
        'clave': clave,
        'valor': v ? 'true' : 'false',
        'tipo': 'config',
      }, onConflict: 'clave');
      _aviso(v ? 'Botón visible en la app' : 'Botón oculto en la app');
    } catch (e) {
      setState(() => _valores[clave] = anterior);
      _aviso('Error guardando: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre nosotros'),
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _grupo(
                      'Botones visibles',
                      'Elige qué botones muestra la app. Se aplica de inmediato.',
                      [
                        _switchFila('Invitar personas', 'mostrar_invitar'),
                        _switchFila('Valorar', 'mostrar_valorar'),
                        _switchFila('Descargar', 'mostrar_descargar'),
                        _switchFila('Donar', 'mostrar_donar'),
                      ],
                      null,
                    ),
                    _grupo(
                      'Invitación',
                      'Mensaje que se comparte al invitar (más el enlace de descarga).',
                      [
                        _campo(_invitacionCtrl, 'Mensaje de invitación',
                            maxLines: 3),
                      ],
                      () => _guardarGrupo({
                        'invitacion_mensaje':
                            _invitacionCtrl.text.trim(),
                      }),
                    ),
                    _grupo(
                      'Descarga',
                      'Enlace del APK (botón Descargar e invitaciones). Vacío: la app usa actualizar_url.',
                      [
                        _campo(_descargaCtrl, 'URL de descarga',
                            url: true),
                      ],
                      () => _guardarGrupo({
                        'descarga_url': _descargaCtrl.text.trim(),
                      }),
                    ),
                    _grupo(
                      'Valoración',
                      'Ficha de Flumi en Play Store (botón Valorar). Vacío: la app avisa "no disponible".',
                      [
                        _campo(_valorarCtrl, 'URL de Play Store',
                            url: true),
                      ],
                      () => _guardarGrupo({
                        'valorar_url': _valorarCtrl.text.trim(),
                      }),
                    ),
                    _grupo(
                      'Donación',
                      'Ventana de Donar: mensaje + datos con botón copiar.',
                      [
                        _campo(_donacionMsgCtrl, 'Mensaje',
                            maxLines: 3),
                        const SizedBox(height: 12),
                        _campo(_donacionCuentaCtrl, 'Cuenta'),
                        const SizedBox(height: 12),
                        _campo(_donacionTelCtrl, 'Teléfono'),
                      ],
                      () => _guardarGrupo({
                        'donacion_mensaje':
                            _donacionMsgCtrl.text.trim(),
                        'donacion_cuenta':
                            _donacionCuentaCtrl.text.trim(),
                        'donacion_telefono':
                            _donacionTelCtrl.text.trim(),
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _grupo(String titulo, String descripcion, List<Widget> hijos,
      VoidCallback? onGuardar) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(descripcion,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            ...hijos,
            if (onGuardar != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onGuardar,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Tema.marca),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchFila(String titulo, String clave) {
    return SwitchListTile(
      value: _vb(clave),
      onChanged: (v) => _alternarVisible(clave, v),
      title: Text(titulo, style: const TextStyle(fontSize: 15)),
      contentPadding: EdgeInsets.zero,
      activeThumbColor: Tema.marca,
    );
  }

  Widget _campo(TextEditingController ctrl, String etiqueta,
      {bool url = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: url ? TextInputType.url : TextInputType.text,
      decoration: InputDecoration(labelText: etiqueta),
    );
  }
}
