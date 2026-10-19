import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../modelo/usuario_admin.dart';

/// Sesión del administrador: login, cierre y validación de rol.
class AdminSesion extends ChangeNotifier {
  final SupabaseClient _client;

  User? _user;
  UsuarioAdmin? _perfil;
  bool _cargando = false;
  String? _error;

  AdminSesion(this._client);

  User? get user => _user;
  UsuarioAdmin? get perfil => _perfil;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get autenticado =>
      _user != null && (_perfil?.isAdmin ?? false);

  /// Restaura la sesión persistida al abrir la app.
  Future<void> iniciarDesdeSesion() async {
    final u = _client.auth.currentUser;
    if (u == null) return;
    _user = u;
    await _cargarPerfil();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = res.user;
      if (_user == null) {
        _error = 'Credenciales incorrectas';
        return false;
      }
      await _cargarPerfil();
      if (_perfil == null || !_perfil!.isAdmin) {
        await _client.auth.signOut();
        _user = null;
        _perfil = null;
        _error = 'Este usuario no tiene permisos de administrador';
        return false;
      }
      return true;
    } on AuthException catch (e) {
      if (_esSinConexion(e)) {
        _error = 'Sin conexión. Verifica tu internet y reintenta.';
      } else {
        _error = e.message;
      }
      return false;
    } catch (e) {
      if (_esSinConexion(e)) {
        _error = 'Sin conexión. Verifica tu internet y reintenta.';
      } else {
        _error = 'Error al iniciar sesión';
      }
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  bool _esSinConexion(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection failed') ||
        s.contains('no address associated');
  }

  Future<void> _cargarPerfil() async {
    if (_user == null) return;
    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      if (res != null) {
        _perfil = UsuarioAdmin.desdeMapa(res);
      }
    } catch (e) {
      if (_esSinConexion(e)) {
        _error = 'Sin conexión. No se pudo verificar el perfil.';
        notifyListeners();
        return;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    _user = null;
    _perfil = null;
    notifyListeners();
  }
}
