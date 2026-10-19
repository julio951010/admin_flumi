import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../config/tema.dart';
import '../../core/modelo/usuario_admin.dart';
import '../comun/widgets_comunes.dart';
import 'usuarios_servicio.dart';

enum _Tipo { texto, numero, booleano, lista, fecha, json }

/// (etiqueta visible, valor guardado en BD) — opciones iguales a flumi_app.
class _CampoDef {
  final String columna;
  final String etiqueta;
  final _Tipo tipo;
  final List<(String, String)>? opciones;
  final bool soloLectura;
  const _CampoDef(this.columna, this.etiqueta, this.tipo,
      [this.opciones, this.soloLectura = false]);
}

const _optGenero = <(String, String)>[
  ('Mujer', 'mujer'),
  ('Hombre', 'hombre'),
  ('Mujer trans', 'mujer trans'),
  ('Hombre trans', 'hombre trans'),
  ('No binario', 'no binario'),
  ('Género fluido', 'género fluido'),
  ('Otro', 'otro'),
];

const _optBuscaGenero = <(String, String)>[
  ('Hombres', 'hombres'),
  ('Mujeres', 'mujeres'),
  ('Personas no binarias', 'no_binarias'),
  ('Todos/as', 'todos'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optQueBusca = <(String, String)>[
  ('Busco una relación estable', 'relacion'),
  ('Busco algo casual / sin compromiso', 'casual'),
  ('Busco amistad / conocer gente', 'amistad'),
  ('Abierto a lo que surja', 'abierto_a_lo_que_surja'),
];

const _optOrientacion = <(String, String)>[
  ('Heterosexual', 'heterosexual'),
  ('Gay', 'gay'),
  ('Lesbiana', 'lesbiana'),
  ('Bisexual', 'bisexual'),
  ('Pansexual', 'pansexual'),
  ('Asexual', 'asexual'),
  ('Queer', 'queer'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optSituacion = <(String, String)>[
  ('Soltero/a', 'soltero'),
  ('Separado/a', 'separado'),
  ('En una relación abierta', 'en_relacion_abierta'),
  ('Viudo/a', 'viudo'),
  ('Es complicado', 'complicado'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optEducacion = <(String, String)>[
  ('Educación Primaria', 'primaria'),
  ('Educación Secundaria', 'secundaria'),
  ('Educación Preuniversitaria', 'preuniversitaria'),
  ('Enseñanza Técnica y Profesional', 'tecnica_profesional'),
  ('Educación Superior', 'superior'),
  ('Postgrado', 'postgrado'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optTrabajo = <(String, String)>[
  ('Sector privado', 'sector_privado'),
  ('Sector público', 'sector_publico'),
  ('Trabajo independiente', 'independiente'),
  ('Emprendedor', 'emprendedor'),
  ('Ama de casa', 'ama_de_casa'),
  ('Estudiante', 'estudiante'),
  ('Jubilado', 'jubilado'),
  ('Buscando trabajo', 'buscando_trabajo'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optBebe = <(String, String)>[
  ('No bebo', 'no_bebo'),
  ('Bebo socialmente', 'bebo_social'),
  ('Bebo con moderación', 'bebo_moderacion'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optFuma = <(String, String)>[
  ('No fumo', 'no_fumo'),
  ('Fumo socialmente', 'fumo_social'),
  ('Fumo a diario', 'fumo_diario'),
  ('Dejé de fumar', 'deje_de_fumar'),
  ('Estoy dejando de fumar', 'dejando_de_fumar'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optHijos = <(String, String)>[
  ('No quiero tener hijos', 'no_quiero'),
  ('Me gustaría tener hijos', 'quiero'),
  ('Ya tengo hijos y no quiero más', 'tengo_no_mas'),
  ('Ya tengo hijos y me gustaría tener más', 'tengo_mas'),
  ('Ya tengo hijos y son adultos', 'tengo_adultos'),
  ('No estoy seguro/a de querer hijos', 'no_se'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optSigno = <(String, String)>[
  ('Aries', 'aries'),
  ('Tauro', 'tauro'),
  ('Géminis', 'geminis'),
  ('Cáncer', 'cancer'),
  ('Leo', 'leo'),
  ('Virgo', 'virgo'),
  ('Libra', 'libra'),
  ('Escorpio', 'escorpio'),
  ('Sagitario', 'sagitario'),
  ('Capricornio', 'capricornio'),
  ('Acuario', 'acuario'),
  ('Piscis', 'piscis'),
];

const _optMascotas = <(String, String)>[
  ('Tengo perro(s)', 'perro'),
  ('Tengo gato(s)', 'gato'),
  ('Tengo perros y gatos', 'perros_gatos'),
  ('No tengo mascotas pero me encantan', 'no_tengo_encantan'),
  ('No tengo mascotas y no quiero', 'no_tengo_no_quiero'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optReligion = <(String, String)>[
  ('Católica', 'catolica'),
  ('Cristiana', 'cristiana'),
  ('Judía', 'judia'),
  ('Musulmana', 'musulmana'),
  ('Budista', 'budista'),
  ('Hindú', 'hindu'),
  ('Espiritual pero no religioso/a', 'espiritual'),
  ('Agnóstico/a', 'agnostico'),
  ('Ateo/a', 'ateo'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

const _optTatuajes = <(String, String)>[
  ('No tengo tatuajes', 'no_tengo'),
  ('Tengo algún tatuaje', 'tengo_alguno'),
  ('Tengo varios tatuajes', 'tengo_varios'),
  ('Me encantaría hacerme un tatuaje', 'me_gustaria'),
  ('Prefiero no decirlo', 'prefiero_no_decirlo'),
];

class UsuarioDetallePantalla extends StatefulWidget {
  final String id;
  const UsuarioDetallePantalla({super.key, required this.id});

  @override
  State<UsuarioDetallePantalla> createState() =>
      _UsuarioDetallePantallaState();
}

class _UsuarioDetallePantallaState extends State<UsuarioDetallePantalla> {
  final _servicio = UsuariosServicio(Supabase.instance.client);
  UsuarioAdmin? _usuario;
  String? _email;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _usuario = await _servicio.obtener(widget.id);
      if (!mounted) return;
      try {
        final correo = await Supabase.instance.client.rpc(
          'obtener_email_usuario',
          params: {'p_user_id': widget.id},
        );
        if (mounted) _email = correo as String?;
      } catch (_) {
        // El email no está disponible; se muestra como vacío.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _toggle(String columna, bool valor) async {
    try {
      await _servicio.actualizar(widget.id, {columna: valor});
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _quitarFoto(int i) async {
    final nuevas = List<String>.from(_usuario!.fotosUrls)..removeAt(i);
    try {
      await _servicio.actualizar(widget.id, {'fotos_urls': nuevas});
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _moverFoto(int i, int dir) async {
    final nuevas = List<String>.from(_usuario!.fotosUrls);
    final j = i + dir;
    if (j < 0 || j >= nuevas.length) return;
    final tmp = nuevas[i];
    nuevas[i] = nuevas[j];
    nuevas[j] = tmp;
    try {
      await _servicio.actualizar(widget.id, {'fotos_urls': nuevas});
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _cambiarContrasena() async {
    final ctrl = TextEditingController();
    final nueva = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Nueva contraseña',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nueva == null || nueva.trim().isEmpty) return;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'cambiar_password',
        body: {'user_id': widget.id, 'password': nueva.trim()},
      );
      if (res.status >= 400) {
        final datos = res.data;
        final msg = datos is Map ? datos['error'] : datos;
        throw Exception(msg?.toString() ?? 'Error al cambiar contraseña');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _enviarResetContrasena() async {
    final email = _email ?? _usuario!.email;
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No hay email disponible para este usuario')));
      }
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Correo de restablecimiento enviado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _abrirGaleria(int indice) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GaleriaFotos(
          urls: _usuario!.fotosUrls,
          indiceInicial: indice,
        ),
      ),
    );
  }

  Future<void> _enviarMensaje() async {
    String remitente = remitenteAdministradorId;
    final ctrl = TextEditingController();
    final enviado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Enviar mensaje'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: remitenteAdministradorId,
                      label: Text('Administrador'),
                    ),
                    ButtonSegment(
                      value: remitenteFlumiId,
                      label: Text('Flumi'),
                    ),
                  ],
                  selected: {remitente},
                  onSelectionChanged: (s) => setSt(() => remitente = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    if (enviado != true) {
      ctrl.dispose();
      return;
    }
    final texto = ctrl.text.trim();
    ctrl.dispose();
    try {
      await Supabase.instance.client.rpc(
        'enviar_mensaje_admin',
        params: {
          'p_emisor': remitente,
          'p_receptor': widget.id,
          'p_contenido': texto,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Mensaje enviado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _flecha(IconData icono, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, size: 16, color: Colors.white),
        ),
      );

  Future<void> _borrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Borrar cuenta'),
          ],
        ),
        content: const Text(
            'Eliminará el perfil del usuario de forma permanente. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _servicio.borrar(widget.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  dynamic _procesarValor(_CampoDef c, String texto, DateTime? fecha) {
    switch (c.tipo) {
      case _Tipo.numero:
        return _esEntero(c.columna) ? int.tryParse(texto) : double.tryParse(texto);
      case _Tipo.lista:
        return texto
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      case _Tipo.fecha:
        return fecha?.toIso8601String().split('T').first;
      case _Tipo.json:
        if (texto.trim().isEmpty) return null;
        return jsonDecode(texto);
      case _Tipo.texto:
        return texto;
      case _Tipo.booleano:
        return null;
    }
  }

  bool _esEntero(String columna) =>
      const ['preferencia_edad_min', 'preferencia_edad_max', 'edad', 'score_popularidad']
          .contains(columna);

  Future<void> _editar(_CampoDef c) async {
    final mapa = _usuario!.toMap();
    final actual = mapa[c.columna];
    final ctrl = TextEditingController();
    DateTime? fecha;

    if (c.tipo == _Tipo.fecha) {
      fecha = actual is String ? DateTime.tryParse(actual) : actual as DateTime?;
    } else if (c.tipo == _Tipo.lista) {
      ctrl.text = actual is List
          ? actual.join(', ')
          : (actual?.toString() ?? '');
    } else if (c.tipo == _Tipo.json) {
      ctrl.text = actual == null
          ? ''
          : const JsonEncoder.withIndent('  ').convert(actual);
    } else if (c.tipo != _Tipo.booleano) {
      ctrl.text = actual?.toString() ?? '';
    }

    final resultado = await showDialog<dynamic>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          Widget cuerpo;
          if (c.tipo == _Tipo.fecha) {
            cuerpo = ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(fecha == null
                  ? 'Sin fecha'
                  : fecha!.toIso8601String().split('T').first),
              onTap: () async {
                final p = await showDatePicker(
                  context: ctx,
                  initialDate: fecha ?? DateTime(2000),
                  firstDate: DateTime(1930),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (p != null) setSt(() => fecha = p);
              },
            );
          } else if (c.opciones != null) {
            final opciones = c.opciones!;
            cuerpo = DropdownButtonFormField<String>(
              initialValue:
                  opciones.any((o) => o.$2 == ctrl.text) ? ctrl.text : null,
              items: opciones
                  .map((o) =>
                      DropdownMenuItem(value: o.$2, child: Text(o.$1)))
                  .toList(),
              onChanged: (v) => setSt(() => ctrl.text = v ?? ''),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            );
          } else {
            final multilinea =
                c.tipo == _Tipo.json || c.columna == 'biografia' || c.columna == 'que_busca';
            cuerpo = TextField(
              controller: ctrl,
              maxLines: multilinea ? 4 : 1,
              decoration: InputDecoration(
                labelText: c.etiqueta,
                border: const OutlineInputBorder(),
              ),
            );
          }
          return AlertDialog(
            title: Text(c.etiqueta),
            content: cuerpo,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  try {
                    Navigator.pop(ctx, _procesarValor(c, ctrl.text, fecha));
                  } catch (e) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Valor inválido')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
    if (resultado == null) return;
    dynamic aGuardar = resultado;
    if (c.tipo == _Tipo.lista && actual is! List && resultado is List) {
      aGuardar = resultado.join(', ');
    }
    try {
      await _servicio.actualizar(widget.id, {c.columna: aGuardar});
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatearValor(_CampoDef c, dynamic valor) {
    if (valor == null) return '—';
    if (c.tipo == _Tipo.booleano) return valor == true ? 'Sí' : 'No';
    if (c.tipo == _Tipo.lista) {
      if (valor is List) return valor.join(', ');
      return valor.toString();
    }
    if (c.tipo == _Tipo.fecha) {
      return valor is String ? valor : (valor as DateTime).toIso8601String().split('T').first;
    }
    if (c.tipo == _Tipo.json) return const JsonEncoder().convert(valor);
    if (c.opciones != null && valor is String) {
      final encontrada = c.opciones!.where((o) => o.$2 == valor).firstOrNull;
      if (encontrada != null) return encontrada.$1;
    }
    final texto = valor.toString();
    return texto.isEmpty ? '—' : texto;
  }

  Widget _campoWidget(_CampoDef c) {
    if (c.columna == 'perfil_completado') {
      final completado = _usuario!.toMap()['perfil_completado'] == true;
      return ListTile(
        title: Text(c.etiqueta),
        subtitle: Text(
          completado ? 'Completado' : 'No completado',
          style: const TextStyle(fontSize: 13),
        ),
      );
    }
    if (c.columna == 'preguntas_perfil') {
      final raw = _usuario!.toMap()['preguntas_perfil'];
      List<dynamic> lista = [];
      if (raw is List) {
        lista = raw;
      } else if (raw is String && raw.trim().isNotEmpty) {
        try {
          lista = jsonDecode(raw) as List;
        } catch (_) {}
      }
      return ListTile(
        title: Text(c.etiqueta),
        subtitle: lista.isEmpty
            ? const Text('—')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  ...lista.map((e) {
                    final map = e is Map ? e : <String, dynamic>{};
                    final pregunta = map['pregunta']?.toString() ?? '';
                    final respuesta = map['respuesta']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('P: $pregunta',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('R: $respuesta',
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      );
    }
    final valor = _usuario!.toMap()[c.columna];
    if (c.tipo == _Tipo.booleano) {
      return SwitchListTile(
        title: Text(c.etiqueta),
        value: valor == true,
        onChanged: c.soloLectura ? null : (v) => _toggle(c.columna, v),
      );
    }
    final texto = _formatearValor(c, valor);
    return ListTile(
      title: Text(c.etiqueta),
      subtitle: texto == '—'
          ? null
          : Text(texto, style: const TextStyle(fontSize: 13)),
      trailing: c.soloLectura ? null : const Icon(Icons.edit, size: 18),
      onTap: c.soloLectura ? null : () => _editar(c),
    );
  }

  Widget _seccion(String titulo, List<_CampoDef> campos) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Tema.marca,
              ),
            ),
          ),
          ...campos.map((c) => Column(
                children: [
                  _campoWidget(c),
                  if (c != campos.last) const Divider(height: 1, indent: 16),
                ],
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _usuario;
    return Scaffold(
      appBar: AppBar(title: Text(u?.nombre.isEmpty ?? true ? 'Detalle' : u!.nombre)),
      body: _cargando || u == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AvatarConFallback(
                              url: u.fotoPrincipal, radius: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_email ?? u.email).isNotEmpty
                                      ? (_email ?? u.email)
                                      : '—',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text('ID: ${u.id}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _enviarMensaje,
                            icon: const Icon(Icons.send),
                            label: const Text('Mensaje'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (u.fotosUrls.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: u.fotosUrls.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final url = u.fotosUrls[i];
                              final puedeIzq = i > 0;
                              final puedeDer = i < u.fotosUrls.length - 1;
                              return SizedBox(
                                width: 100,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onTap: () => _abrirGaleria(i),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(url,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: InkWell(
                                        onTap: () => _quitarFoto(i),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 18, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    if (puedeIzq)
                                      Positioned(
                                        bottom: 2,
                                        left: 2,
                                        child: _flecha(Icons.arrow_left,
                                            () => _moverFoto(i, -1)),
                                      ),
                                    if (puedeDer)
                                      Positioned(
                                        bottom: 2,
                                        right: 2,
                                        child: _flecha(Icons.arrow_right,
                                            () => _moverFoto(i, 1)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      _seccion('Cuenta', const [
                        _CampoDef('verificado_status', 'Verificado', _Tipo.booleano),
                        _CampoDef('suspendido', 'Suspendido', _Tipo.booleano),
                        _CampoDef('is_admin', 'Administrador', _Tipo.booleano),
                        _CampoDef('perfil_completado', 'Perfil completado', _Tipo.booleano, null, true),
                        _CampoDef('score_popularidad', 'Score de popularidad', _Tipo.numero, null, true),
                        _CampoDef('creado_en', 'Creado', _Tipo.texto, null, true),
                        _CampoDef('ultima_conexion', 'Última conexión', _Tipo.texto, null, true),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _cambiarContrasena,
                          icon: const Icon(Icons.lock),
                          label: const Text('Cambiar contraseña'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _enviarResetContrasena,
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('Enviar correo de restablecimiento'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _seccion('Identidad', [
                        const _CampoDef('nombre', 'Nombre', _Tipo.texto),
                        const _CampoDef('genero', 'Género', _Tipo.texto, _optGenero),
                        const _CampoDef(
                            'busca_genero', 'Busca', _Tipo.texto, _optBuscaGenero),
                        const _CampoDef('fecha_nacimiento', 'Fecha de nacimiento', _Tipo.fecha),
                        const _CampoDef('edad', 'Edad', _Tipo.numero, null, true),
                        const _CampoDef(
                            'orientacion_sexual', 'Orientación sexual', _Tipo.texto, _optOrientacion),
                        const _CampoDef('situacion_sentimental',
                            'Situación sentimental', _Tipo.texto, _optSituacion),
                        const _CampoDef('ciudad', 'Ciudad', _Tipo.texto),
                      ]),
                      const SizedBox(height: 16),
                      _seccion('Perfil', [
                        const _CampoDef('biografia', 'Biografía', _Tipo.texto),
                        const _CampoDef(
                            'que_busca', 'Qué busca', _Tipo.texto, _optQueBusca),
                        const _CampoDef('altura', 'Altura', _Tipo.texto),
                        const _CampoDef(
                            'educacion', 'Educación', _Tipo.texto, _optEducacion),
                        const _CampoDef(
                            'trabajo', 'Trabajo', _Tipo.texto, _optTrabajo),
                        const _CampoDef('profesion', 'Profesión', _Tipo.texto),
                        const _CampoDef('personalidad', 'Personalidad', _Tipo.texto,
                            [], true),
                        const _CampoDef('signo_zodiaco', 'Signo zodiaco',
                            _Tipo.texto, _optSigno, true),
                        const _CampoDef(
                            'mascotas', 'Mascotas', _Tipo.texto, _optMascotas),
                        const _CampoDef(
                            'religion', 'Religión', _Tipo.texto, _optReligion),
                        const _CampoDef('idiomas', 'Idiomas (separados por coma)', _Tipo.lista),
                        const _CampoDef('intereses', 'Intereses (separados por coma)',
                            _Tipo.lista, [], true),
                        const _CampoDef(
                            'tatuajes', 'Tatuajes', _Tipo.texto, _optTatuajes),
                        const _CampoDef('preguntas_perfil', 'Preguntas de perfil',
                            _Tipo.json, [], true),
                      ]),
                      const SizedBox(height: 16),
                      _seccion('Preferencias de búsqueda', [
                        const _CampoDef('preferencia_edad_min', 'Edad mínima', _Tipo.numero),
                        const _CampoDef('preferencia_edad_max', 'Edad máxima', _Tipo.numero),
                        const _CampoDef('preferencia_relacion', 'Preferencia de relación', _Tipo.texto),
                        const _CampoDef('bebe', 'Bebé', _Tipo.texto, _optBebe),
                        const _CampoDef('fuma', 'Fuma', _Tipo.texto, _optFuma),
                        const _CampoDef('hijos', 'Hijos', _Tipo.texto, _optHijos),
                      ]),
                      const SizedBox(height: 16),
                      _seccion('Privacidad', const [
                        _CampoDef('ocultar_en_linea', 'Ocultar en línea', _Tipo.booleano),
                        _CampoDef('ocultar_edad', 'Ocultar edad', _Tipo.booleano),
                        _CampoDef('ocultar_perfil', 'Ocultar perfil', _Tipo.booleano),
                        _CampoDef('ocultar_visitas', 'Ocultar visitas', _Tipo.booleano),
                      ]),
                      const SizedBox(height: 16),
                      _seccion('Ubicación', const [
                        _CampoDef('ubicacion_lat', 'Latitud', _Tipo.numero),
                        _CampoDef('ubicacion_lon', 'Longitud', _Tipo.numero),
                      ]),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _borrar,
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          label: const Text('Borrar cuenta',
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Visor de fotos a pantalla completa estilo galería (swipe + zoom).
class _GaleriaFotos extends StatelessWidget {
  final List<String> urls;
  final int indiceInicial;

  const _GaleriaFotos({required this.urls, required this.indiceInicial});

  @override
  Widget build(BuildContext context) {
    final pageCtrl = PageController(initialPage: indiceInicial);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: PageView.builder(
        controller: pageCtrl,
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(urls[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
