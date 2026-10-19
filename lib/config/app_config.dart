/// Configuración de Supabase para la app admin.
///
/// Pega aquí la misma URL y la `publishableKey` (anon key) que usa flumi_app
/// (las encuentras en el dashboard de Supabase o en su `config/env.dart`).
/// La anon key es pública y segura para el cliente; NUNCA uses la
/// service_role key en una app cliente.
const String supabaseUrl = 'https://gzozmebdrsdcupgvxuiv.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6b3ptZWJkcnNkY3VwZ3Z4dWl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ3NDEwMjAsImV4cCI6MjEwMDMxNzAyMH0.WOVstBsW57idlX0LiceKIYcJOvCVTf5wdGiib20Y5ZY';

/// Identidades de sistema para enviar mensajes desde el panel admin.
/// Deben coincidir con los UUIDs creados en `supabase/admin_setup.sql`.
const String remitenteAdministradorId = '00000000-0000-0000-0000-00000000000a';
const String remitenteFlumiId = '00000000-0000-0000-0000-00000000000f';
