import 'package:supabase_flutter/supabase_flutter.dart';

class BahService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getInstallations() async {
    final data = await _supabase
        .from('installations')
        .select()
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<double?> getBahRate({
    required String militaryHousingArea,
    required String payGrade,
    required bool hasDependents,
    required int year,
  }) async {
    final data = await _supabase
        .from('bah_rates')
        .select('with_dependents, without_dependents')
        .eq('military_housing_area', militaryHousingArea)
        .eq('pay_grade', payGrade)
        .eq('year', year)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    final value = hasDependents
        ? data['with_dependents']
        : data['without_dependents'];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}