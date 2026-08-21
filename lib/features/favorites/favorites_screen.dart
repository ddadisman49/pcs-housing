import 'package:flutter/material.dart';

import '../../core/services/favorites_service.dart';
import '../search/listing_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() =>
      _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService =
      FavoritesService();

  late Future<List<Map<String, dynamic>>>
      _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture =
        _favoritesService.getFavoriteListings();
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _loadFavorites();
    });

    await _favoritesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Homes'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load favorites.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final favorites = snapshot.data ?? [];

          if (favorites.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 72,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No saved homes yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Homes and apartments you save will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshFavorites,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
             separatorBuilder: (context, index) =>
    const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final favorite = favorites[index];

                final listing =
                    favorite['housing_listings'];

                if (listing
                    is! Map<String, dynamic>) {
                  return const SizedBox.shrink();
                }

                final monthlyRent =
                    (listing['monthly_rent'] as num?)
                            ?.toDouble() ??
                        0;

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.favorite,
                    ),
                    title: Text(
                      listing['title']?.toString() ??
                          'Housing Listing',
                    ),
                    subtitle: Text(
                      '${listing['address'] ?? ''}\n'
                      '\$${monthlyRent.toStringAsFixed(0)}/month',
                    ),
                    isThreeLine: true,
                    trailing:
                        const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailScreen(
                            listing: listing,
                          ),
                        ),
                      );

                      if (!mounted) return;

                      setState(() {
                        _loadFavorites();
                      });
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}