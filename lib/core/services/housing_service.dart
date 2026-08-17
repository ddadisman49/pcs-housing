import 'package:supabase_flutter/supabase_flutter.dart';

class HousingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getListings({
    required double maxRent,
    String? militaryHousingArea,
  }) async {
    var query = _supabase
        .from('housing_listings')
        .select()
        .eq('is_active', true)
        .lte('monthly_rent', maxRent);

    if (militaryHousingArea != null &&
        militaryHousingArea.isNotEmpty) {
      query = query.eq(
        'military_housing_area',
        militaryHousingArea,
      );
    }

    final data = await query.order(
      'monthly_rent',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(data);
  }
}