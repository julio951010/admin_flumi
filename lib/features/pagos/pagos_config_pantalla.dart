import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';

class PagosConfigPantalla extends StatefulWidget {
  const PagosConfigPantalla({super.key});

  @override
  State<PagosConfigPantalla> createState() => _PagosConfigPantallaState();
}

class _PagosConfigPantallaState extends State<PagosConfigPantalla> {
  bool _cargando = true;
  String? _error;
  List<_PagoConfig> _configs = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await Supabase.instance.client
          .from('pagos_config')
          .select()
          .order('metodo');
      setState(() {
        _configs = (res as List).map((e) => _PagoConfig.fromMap(Map<String, dynamic>.from(e))).toList();
        for (final m in ['transfermovil', 'enzona']) {
          if (!_configs.any((c) => c.metodo == m)) {
            _configs.add(_PagoConfig(metodo: m, tarjetaDestino: '', movilConfirmar: '', qrUrl: '', concepto: m == 'enzona' ? 'Flumi EnZona' : 'Flumi', activo: true));
          }
        }
        _configs.sort((a, b) => a.metodo.compareTo(b.metodo));
        _cargando = false;
      });
    } catch (e) {
      setState(() { _error = 'Error cargando: $e'; _cargando = false; });
    }
  }

  Future<void> _guardar(_PagoConfig c) async {
    try {
      await Supabase.instance.client.from('pagos_config').upsert({
        'metodo': c.metodo,
        'tarjeta_destino': c.tarjetaDestino,
        'movil_confirmar': c.movilConfirmar,
        'qr_url': c.qrUrl,
        'concepto': c.concepto,
        'activo': c.activo,
        'actualizado_en': DateTime.now().toIso8601String(),
      }, onConflict: 'metodo');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.metodo} guardado'), behavior: SnackBarBehavior.floating));
      await _cargar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método de pago'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargando ? null : _cargar)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: _cargar, child: const Text('Reintentar'))])))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [const Icon(Icons.info_outline, color: Color(0xFF1565C0)), const SizedBox(width: 10), Expanded(child: Text('Datos comunes para ambos métodos: Tarjeta destino, Móvil a confirmar, Monto (del plan) + Imagen QR. Cada método puede tener datos distintos. El QR se guarda en Supabase Storage (bucket pagos_qr).', style: TextStyle(fontSize: 12, color: Colors.grey[800])))]),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 720 && _configs.length > 1) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < _configs.length; i++) ...[
                                if (i > 0) const SizedBox(width: 16),
                                Expanded(
                                  child: _PagoConfigCard(config: _configs[i], onGuardar: _guardar, onRecargar: _cargar),
                                ),
                              ],
                            ],
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _configs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (_, i) => _PagoConfigCard(config: _configs[i], onGuardar: _guardar, onRecargar: _cargar),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}

class _PagoConfigCard extends StatefulWidget {
  final _PagoConfig config;
  final Future<void> Function(_PagoConfig) onGuardar;
  final VoidCallback onRecargar;
  const _PagoConfigCard({required this.config, required this.onGuardar, required this.onRecargar});

  @override
  State<_PagoConfigCard> createState() => _PagoConfigCardState();
}

class _PagoConfigCardState extends State<_PagoConfigCard> {
  late final TextEditingController _ctrlTarjeta;
  late final TextEditingController _ctrlMovil;
  late final TextEditingController _ctrlQr;
  late final TextEditingController _ctrlConcepto;
  bool _subiendo = false;

  @override
  void initState() {
    super.initState();
    _ctrlTarjeta = TextEditingController(text: widget.config.tarjetaDestino);
    _ctrlMovil = TextEditingController(text: widget.config.movilConfirmar);
    _ctrlQr = TextEditingController(text: widget.config.qrUrl);
    _ctrlConcepto = TextEditingController(text: widget.config.concepto);
  }

  @override
  void dispose() {
    _ctrlTarjeta.dispose();
    _ctrlMovil.dispose();
    _ctrlQr.dispose();
    _ctrlConcepto.dispose();
    super.dispose();
  }

  /// El switch Activo/Inactivo se guarda de inmediato (antes solo cambiaba
  /// el estado local y requería pulsar "Guardar": si no se pulsaba, la app
  /// seguía mostrando el método como activo).
  Future<void> _alternarActivo(bool v) async {
    final c = widget.config;
    final anterior = c.activo;
    setState(() => c.activo = v);
    try {
      await Supabase.instance.client.from('pagos_config').upsert({
        'metodo': c.metodo,
        'activo': v,
        'actualizado_en': DateTime.now().toIso8601String(),
      }, onConflict: 'metodo');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${c.metodo == 'transfermovil' ? 'Transfermóvil' : 'EnZona'} ${v ? 'activado' : 'desactivado'}')));
      }
    } catch (e) {
      setState(() => c.activo = anterior);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error guardando: $e')));
      }
    }
  }

  Future<void> _subirQr() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      setState(() => _subiendo = true);
      final bytes = await file.readAsBytes();
      // Ruta fija por método → siempre se reemplaza la anterior (solo 1 QR por método en Storage).
      const path = 'qr.png'; // se antepone el método como carpeta
      final fullPath = '${widget.config.metodo}/$path';
      // Limpia QR anteriores de ese método (por si quedaron archivos con timestamp viejos)
      try {
        final existing = await Supabase.instance.client.storage.from('pagos_qr').list(path: widget.config.metodo);
        for (final f in existing) {
          if (f.name.startsWith('qr_')) {
            await Supabase.instance.client.storage.from('pagos_qr').remove(['${widget.config.metodo}/${f.name}']);
          }
        }
      } catch (_) {}
      await Supabase.instance.client.storage.from('pagos_qr').uploadBinary(
        fullPath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/png', upsert: true, cacheControl: '0'),
      );
      final url = Supabase.instance.client.storage.from('pagos_qr').getPublicUrl(fullPath);
      // Cache-busting para que flumi_app vea la nueva imagen sin esperar CDN
      final urlBusted = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        widget.config.qrUrl = urlBusted;
        _ctrlQr.text = urlBusted;
        _subiendo = false;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR subido (reemplazó al anterior). Guarda para aplicar.')));
    } catch (e) {
      setState(() => _subiendo = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error subiendo QR: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Tema.marca.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(c.metodo == 'transfermovil' ? Icons.phone_android : Icons.qr_code_2, color: Tema.marca),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(c.metodo == 'transfermovil' ? 'Transfermóvil' : 'EnZona', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Switch(value: c.activo, onChanged: (v) => _alternarActivo(v), activeThumbColor: Tema.marca),
                Text(c.activo ? 'Activo' : 'Inactivo', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const Divider(height: 24),
            _field('Tarjeta destino (CUP) *', _ctrlTarjeta, hint: '9225 9598 7143 2108'),
            const SizedBox(height: 12),
            _field('Móvil a confirmar *', _ctrlMovil, hint: '+53 5 123 45 67'),
            const SizedBox(height: 8),
            Text('Monto a transferir: se toma del plan elegido en flumi_app (7/30/90 días). No se configura aquí.', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            _field('Concepto', _ctrlConcepto, hint: 'Flumi'),
            const SizedBox(height: 12),
            _field('QR URL', _ctrlQr, hint: 'https://.../qr.png (se llena al subir)'),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _subiendo ? null : _subirQr,
                  icon: _subiendo ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.upload, size: 18),
                  label: Text(_subiendo ? 'Subiendo...' : (c.qrUrl.isEmpty ? 'Subir QR' : 'Cambiar QR')),
                ),
                const SizedBox(width: 8),
                if (c.qrUrl.isNotEmpty || _ctrlQr.text.isNotEmpty)
                  TextButton(
                    onPressed: _subiendo ? null : () async {
                      // Elimina de Storage y de la BD al guardar
                      try {
                        setState(() => _subiendo = true);
                        // Intenta borrar el archivo fijo y cualquier qr_ antiguo
                        try {
                          await Supabase.instance.client.storage.from('pagos_qr').remove(['${c.metodo}/qr.png']);
                        } catch (_) {}
                        try {
                          final existing = await Supabase.instance.client.storage.from('pagos_qr').list(path: c.metodo);
                          final toRemove = existing.where((f) => f.name.startsWith('qr')).map((f) => '${c.metodo}/${f.name}').toList();
                          if (toRemove.isNotEmpty) {
                            await Supabase.instance.client.storage.from('pagos_qr').remove(toRemove);
                          }
                        } catch (_) {}
                        setState(() {
                          c.qrUrl = '';
                          _ctrlQr.clear();
                          _subiendo = false;
                        });
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QR eliminado. Guarda para aplicar.')));
                      } catch (e) {
                        setState(() => _subiendo = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando QR: $e')));
                      }
                    },
                    child: _subiendo
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Eliminar QR', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            if (_ctrlQr.text.isNotEmpty && _ctrlQr.text.startsWith('http'))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_ctrlQr.text, height: 160, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('No se pudo cargar QR')),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  c.tarjetaDestino = _ctrlTarjeta.text.trim();
                  c.movilConfirmar = _ctrlMovil.text.trim();
                  c.qrUrl = _ctrlQr.text.trim();
                  c.concepto = _ctrlConcepto.text.trim();
                  widget.onGuardar(c);
                },
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Guardar'),
                style: FilledButton.styleFrom(backgroundColor: Tema.marca, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), filled: true, fillColor: Colors.grey[50]),
          ),
        ],
      );
}

class _PagoConfig {
  String metodo;
  String tarjetaDestino;
  String movilConfirmar;
  String qrUrl;
  String concepto;
  bool activo;
  _PagoConfig({required this.metodo, required this.tarjetaDestino, required this.movilConfirmar, required this.qrUrl, required this.concepto, required this.activo});
  factory _PagoConfig.fromMap(Map<String, dynamic> m) => _PagoConfig(
        metodo: (m['metodo'] as String?) ?? 'transfermovil',
        tarjetaDestino: (m['tarjeta_destino'] as String?) ?? '',
        movilConfirmar: (m['movil_confirmar'] as String?) ?? '',
        qrUrl: (m['qr_url'] as String?) ?? '',
        concepto: (m['concepto'] as String?) ?? '',
        activo: (m['activo'] as bool?) ?? true,
      );
}
