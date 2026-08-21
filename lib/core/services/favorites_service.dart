import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> isFavorite(int listingId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return false;
    }

    final data = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('listing_id', listingId)
        .maybeSingle();

    return data != null;
  }

  Future<void> addFavorite(int listingId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _supabase.from('favorites').insert({
      'user_id': user.id,
      'listing_id': listingId,
    });
  }

  Future<void> removeFavorite(int listingId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('listing_id', listingId);
  }

  Future<List<Map<String, dynamic>>> getFavoriteListings() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    final data = await _supabase
        .from('favorites')
        .select('''
          id,
          listing_id,
          created_at,
          housing_listings (
            id,
            title,
            address,
            city,
            state,
            zip_code,
            monthly_rent,
            bedrooms,
            bathrooms,
            square_feet,
            latitude,
            longitude,
            military_friendly,
            pet_friendly
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}