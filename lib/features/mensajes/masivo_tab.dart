import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/tema.dart';
import 'mensajes_comunes.dart';
import 'mensajes_servicio.dart';

/// Pestaña para enviar un mensaje a un segmento de usuarios.
class MasivoTab extends StatefulWidget {
  final MensajesServicio servicio;
  final VoidCallback onEnviado;

  const MasivoTab({
    super.key,
    required this.servicio,
    required this.onEnviado,
  });

  @override
  State<MasivoTab> createState() => _MasivoTabState();
}

class _MasivoTabState extends State<MasivoTab> {
  final _limiteCtrl = TextEditingController(text: '200');
  final _mensajeCtrl = TextEditingController();

  String _remitente = remitenteAdminClave;
  String _segmento = 'todos';
  bool _soloSinMensaje = false;
  List<PlantillaMensaje> _plantillas = const [];

  bool _contando = false;
  bool _enviando = false;
  int? _conteo;
  ResultadoMasivo? _resultado;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPlantillas();
  }

  @override
  void dispose() {
    _limiteCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPlantillas() async {
    try {
      final lista = await widget.servicio.plantillas();
      if (!mounted) return;
      setState(() => _plantillas = lista);
    } catch (_) {
      // Opcional: se puede escribir el mensaje a mano.
    }
  }

  int? get _limite {
    final valor = int.tryParse(_limiteCtrl.text.trim());
    if (valor == null) return null;
    return valor.clamp(1, 500);
  }

  void _invalidar() {
    setState(() {
      _conteo = null;
      _resultado = null;
      _error = null;
    });
  }

  Future<void> _contar() async {
    final limite = _limite;
    if (limite == null) {
      setState(() => _error = 'Escribe un límite entre 1 y 500.');
      return;
    }

    setState(() {
      _contando = true;
      _error = null;
      _resultado = null;
    });

    try {
      final total = await widget.servicio.contarMasivo(
        remitente: _remitente,
        segmento: _segmento,
        soloSinMensaje: _soloSinMensaje,
        limite: limite,
      );
      if (!mounted) return;
      setState(() => _conteo = total);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _contando = false);
    }
  }

  Future<void> _enviar() async {
    final limite = _limite;
    final total = _conteo;
    if (limite == null || total == null || total == 0) return;
    if (_mensajeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el mensaje antes de enviar.');
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar envío masivo'),
        content: Text(
          'Se enviará el mensaje a $total '
          '${total == 1 ? 'usuario' : 'usuarios'} como '
          '${nombreDeRemitente(_remitente)}.\n\n'
          'Cada envío genera una notificación push. Esta acción no se puede '
          'deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Enviar a $total'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() {
      _enviando = true;
      _error = null;
      _resultado = null;
    });

    try {
      final resultado = await widget.servicio.enviarMasivo(
        remitente: _remitente,
        segmento: _segmento,
        contenido: _mensajeCtrl.text,
        soloSinMensaje: _soloSinMensaje,
        limite: limite,
      );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _conteo = null;
      });
      widget.onEnviado();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _conteo;
    final puedeEnviar = total != null &&
        total > 0 &&
        _mensajeCtrl.text.trim().isNotEmpty &&
        !_enviando;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      children: [
        AvisoCard(
          icono: Icons.campaign_outlined,
          titulo: 'Envío por segmento',
          detalle:
              'Se excluyen administradores, cuentas suspendidas y las cuentas '
              'del sistema. Cada mensaje genera una notificación push.',
          color: Colors.deepOrange.shade700,
        ),
        const SizedBox(height: 18),
        _Titulo('Enviar como'),
        const SizedBox(height: 8),
        RemitenteSelector(
          valor: _remitente,
          onChanged: (valor) {
            setState(() => _remitente = valor);
            _invalidar();
          },
        ),
        const SizedBox(height: 18),
        _Titulo('Segmento'),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _segmento,
              isExpanded: true,
              isDense: true,
              items: [
                for (final segmento in SegmentoMasivo.todos)
                  DropdownMenuItem(
                    value: segmento.clave,
                    child: Text(
                      segmento.etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (valor) {
                if (valor == null) return;
                setState(() => _segmento = valor);
                _invalidar();
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _soloSinMensaje,
          onChanged: (valor) {
            setState(() => _soloSinMensaje = valor);
            _invalidar();
          },
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Solo quienes aún no recibieron mensajes',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Evita repetir el mensaje a usuarios que ya lo recibieron de esta '
            'cuenta.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          activeThumbColor: Tema.marca,
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('mensajes-limite'),
          controller: _limiteCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _invalidar(),
          decoration: const InputDecoration(
            labelText: 'Máximo de destinatarios',
            helperText: 'Entre 1 y 500 por envío.',
            prefixIcon: Icon(Icons.group_outlined),
          ),
        ),
        const SizedBox(height: 18),
        _Titulo('Plantillas'),
        const SizedBox(height: 8),
        PlantillaChips(
          plantillas: _plantillas,
          onSeleccionada: (p) {
            setState(() {
              _mensajeCtrl.text = p.contenido;
              _mensajeCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _mensajeCtrl.text.length),
              );
            });
          },
        ),
        const SizedBox(height: 18),
        _Titulo('Mensaje'),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('mensajes-contenido'),
          controller: _mensajeCtrl,
          minLines: 4,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Escribe el mensaje…\nPuedes usar {nombre} para '
                'personalizarlo.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _contando ? null : _contar,
            icon: _contando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate_outlined, size: 18),
            label: Text(
              _contando ? 'Calculando…' : 'Calcular destinatarios',
            ),
          ),
        ),
        if (total != null) ...[
          const SizedBox(height: 12),
          AvisoCard(
            icono: total == 0
                ? Icons.info_outline_rounded
                : Icons.people_alt_rounded,
            titulo: total == 0
                ? 'No hay destinatarios'
                : 'Se enviará a $total ${total == 1 ? 'usuario' : 'usuarios'}',
            detalle: total == 0
                ? 'Prueba con otro segmento o quita el filtro de "solo '
                    'quienes aún no recibieron".'
                : 'Máximo configurado: ${_limite ?? 0}.',
            color: total == 0 ? Colors.grey.shade700 : Tema.marca,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          AvisoCard(
            icono: Icons.error_outline_rounded,
            titulo: 'Revisa los datos',
            detalle: _error!,
            color: Colors.red.shade700,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: puedeEnviar ? _enviar : null,
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _enviando
                  ? 'Enviando…'
                  : total == null
                      ? 'Calcula los destinatarios primero'
                      : 'Enviar a $total usuarios',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorRemitente(_remitente),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_resultado != null) ...[
          const SizedBox(height: 14),
          AvisoCard(
            icono: Icons.check_circle_rounded,
            titulo: 'Envío completado',
            detalle: '${_resultado!.enviados} mensajes enviados'
                '${_resultado!.omitidos > 0 ? ' · ${_resultado!.omitidos} omitidos' : ''}.',
            color: Colors.green.shade700,
          ),
        ],
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}
