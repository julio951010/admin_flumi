import 'package:flutter/material.dart';

import '../../core/modelo/usuario_admin.dart';
import 'mensajes_comunes.dart';
import 'mensajes_servicio.dart';

/// Pestaña para enviar un mensaje puntual como Administrador o Flumi.
class EnviarTab extends StatefulWidget {
  final MensajesServicio servicio;
  final VoidCallback onEnviado;

  const EnviarTab({
    super.key,
    required this.servicio,
    required this.onEnviado,
  });

  @override
  State<EnviarTab> createState() => _EnviarTabState();
}

class _EnviarTabState extends State<EnviarTab> {
  final _destinatarioCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();

  String _remitente = remitenteAdminClave;
  List<UsuarioAdmin> _resultados = const [];
  List<PlantillaMensaje> _plantillas = const [];
  UsuarioAdmin? _destinatario;

  bool _buscando = false;
  bool _enviando = false;
  String? _errorBusqueda;
  String? _errorEnvio;
  String? _exito;

  @override
  void initState() {
    super.initState();
    _cargarPlantillas();
  }

  @override
  void dispose() {
    _destinatarioCtrl.dispose();
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPlantillas() async {
    try {
      final lista = await widget.servicio.plantillas();
      if (!mounted) return;
      setState(() => _plantillas = lista);
    } catch (_) {
      // Las plantillas son opcionales: si fallan, se puede escribir a mano.
    }
  }

  Future<void> _buscar() async {
    final query = _destinatarioCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorBusqueda = 'Escribe un nombre, email o UUID.';
        _resultados = const [];
      });
      return;
    }

    setState(() {
      _buscando = true;
      _errorBusqueda = null;
      _exito = null;
      _errorEnvio = null;
    });

    try {
      final lista = await widget.servicio.buscarUsuarios(query);
      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _destinatario = lista.length == 1 ? lista.first : null;
        _errorBusqueda =
            lista.isEmpty ? 'No se encontró ningún usuario.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBusqueda = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  String get _contenidoFinal {
    final nombre = _destinatario?.nombre.trim() ?? '';
    return aplicarVariables(
      _mensajeCtrl.text.trim(),
      nombre: nombre.isEmpty ? 'amigo/a' : nombre.split(' ').first,
    );
  }

  Future<void> _enviar() async {
    FocusScope.of(context).unfocus();

    if (_destinatario == null) {
      setState(() {
        _exito = null;
        _errorEnvio = 'Selecciona un destinatario válido.';
      });
      return;
    }
    if (_mensajeCtrl.text.trim().isEmpty) {
      setState(() {
        _exito = null;
        _errorEnvio = 'Escribe el mensaje.';
      });
      return;
    }

    setState(() {
      _enviando = true;
      _errorEnvio = null;
      _exito = null;
    });

    try {
      await widget.servicio.enviar(
        remitente: _remitente,
        receptorId: _destinatario!.id,
        contenido: _contenidoFinal,
      );
      if (!mounted) return;
      setState(() {
        _exito = 'Mensaje enviado a ${_destinatario!.nombre} '
            'como ${nombreDeRemitente(_remitente)}.';
        _mensajeCtrl.clear();
        _resultados = const [];
        _destinatario = null;
        _destinatarioCtrl.clear();
      });
      widget.onEnviado();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorEnvio = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 32),
      children: [
        _Titulo('Enviar como'),
        const SizedBox(height: 8),
        RemitenteSelector(
          valor: _remitente,
          onChanged: (valor) => setState(() => _remitente = valor),
        ),
        const SizedBox(height: 20),
        _Titulo('Destinatario'),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final campo = TextField(
              key: const ValueKey('mensajes-destinatario'),
              controller: _destinatarioCtrl,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                hintText: 'Nombre o UUID',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _destinatarioCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () => setState(() {
                          _destinatarioCtrl.clear();
                          _destinatario = null;
                          _resultados = const [];
                          _errorBusqueda = null;
                        }),
                      ),
              ),
            );
            final boton = FilledButton.icon(
              onPressed: _buscando ? null : _buscar,
              icon: _buscando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Buscar'),
            );

            if (constraints.maxWidth < 430) {
              return Column(
                children: [
                  campo,
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: boton),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: campo),
                const SizedBox(width: 8),
                boton,
              ],
            );
          },
        ),
        if (_errorBusqueda != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorBusqueda!,
            style: TextStyle(fontSize: 12, color: Colors.red.shade700),
          ),
        ],
        if (_resultados.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final usuario in _resultados)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ResultadoUsuario(
                usuario: usuario,
                onTap: () => setState(() {
                  _destinatario = usuario;
                  _resultados = const [];
                  _destinatarioCtrl.text = usuario.nombre;
                }),
              ),
            ),
        ],
        if (_destinatario != null) ...[
          const SizedBox(height: 8),
          _DestinatarioSeleccionado(
            usuario: _destinatario!,
            onQuitar: () => setState(() {
              _destinatario = null;
              _destinatarioCtrl.clear();
            }),
          ),
        ],
        const SizedBox(height: 20),
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
        const SizedBox(height: 20),
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
        if (_destinatario != null && _mensajeCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          _VistaPrevia(
            remitente: _remitente,
            destinatario: _destinatario!.nombre,
            contenido: _contenidoFinal,
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
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
            label: Text(_enviando ? 'Enviando…' : 'Enviar mensaje'),
            style: FilledButton.styleFrom(
              backgroundColor: colorRemitente(_remitente),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_exito != null) ...[
          const SizedBox(height: 14),
          AvisoCard(
            icono: Icons.check_circle_rounded,
            titulo: 'Enviado',
            detalle: _exito!,
            color: Colors.green.shade700,
          ),
        ],
        if (_errorEnvio != null) ...[
          const SizedBox(height: 14),
          AvisoCard(
            icono: Icons.error_outline_rounded,
            titulo: 'No se pudo enviar',
            detalle: _errorEnvio!,
            color: Colors.red.shade700,
          ),
        ],
        const SizedBox(height: 18),
        AvisoCard(
          icono: Icons.info_outline_rounded,
          titulo: 'Los usuarios no pueden responder aquí',
          detalle:
              'Administrador y Flumi son cuentas oficiales de solo envío. '
              'Si un usuario necesita ayuda, debe escribir desde la sección '
              'Soporte de la app, y tú lo verás en la pestaña Soporte.',
          color: Colors.blue.shade700,
        ),
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

class _ResultadoUsuario extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onTap;

  const _ResultadoUsuario({required this.usuario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              AvatarIniciales(nombre: usuario.nombre),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombre.isEmpty ? 'Sin nombre' : usuario.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      usuario.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinatarioSeleccionado extends StatelessWidget {
  final UsuarioAdmin usuario;
  final VoidCallback onQuitar;

  const _DestinatarioSeleccionado({
    required this.usuario,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          AvatarIniciales(
            nombre: usuario.nombre,
            claveRemitente: remitenteAdminClave,
            radio: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombre.isEmpty ? 'Sin nombre' : usuario.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  usuario.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onQuitar,
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Quitar destinatario',
          ),
        ],
      ),
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final String remitente;
  final String destinatario;
  final String contenido;

  const _VistaPrevia({
    required this.remitente,
    required this.destinatario,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vista previa para $destinatario',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RemitenteBadge(clave: remitente, compacto: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
