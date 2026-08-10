import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> ensureProfileExists() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    await _supabase.from('profiles').upsert(
      {
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return data;
  }

  Future<void> updateProfile({
    required String fullName,
    required String branch,
    required String rank,
    required bool hasDependents,
    required String currentDutyStation,
    required String nextDutyStation,
    DateTime? pcsDate,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _supabase
        .from('profiles')
        .update({
          'full_name': fullName,
          'branch': branch,
          'rank': rank,
          'has_dependents': hasDependents,
          'current_duty_station': currentDutyStation,
          'next_duty_station': nextDutyStation,
          'pcs_date': pcsDate?.toIso8601String().split('T').first,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  }
}