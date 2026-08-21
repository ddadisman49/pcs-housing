import 'package:flutter/material.dart';

import '../../core/services/favorites_service.dart';

class ListingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingDetailScreen({
    super.key,
    required this.listing,
  });

  @override
  State<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState
    extends State<ListingDetailScreen> {
  final FavoritesService _favoritesService =
      FavoritesService();

  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isSavingFavorite = false;

  int? get _listingId {
    final value = widget.listing['id'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final listingId = _listingId;

    if (listingId == null) {
      setState(() {
        _isLoadingFavorite = false;
      });
      return;
    }

    try {
      final isFavorite =
          await _favoritesService.isFavorite(listingId);

      if (!mounted) return;

      setState(() {
        _isFavorite = isFavorite;
        _isLoadingFavorite = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingFavorite = false;
      });

      _showMessage(
        'Unable to check favorite status: $error',
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final listingId = _listingId;

    if (listingId == null) {
      _showMessage('This listing is missing an ID.');
      return;
    }

    setState(() {
      _isSavingFavorite = true;
    });

    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(
          listingId,
        );
      } else {
        await _favoritesService.addFavorite(
          listingId,
        );
      }

      if (!mounted) return;

      setState(() {
        _isFavorite = !_isFavorite;
      });

      _showMessage(
        _isFavorite
            ? 'Saved to favorites.'
            : 'Removed from favorites.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update favorite: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingFavorite = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;

    final monthlyRent =
        (listing['monthly_rent'] as num?)?.toDouble() ?? 0;

    final bedrooms =
        listing['bedrooms']?.toString() ?? '-';

    final bathrooms =
        listing['bathrooms']?.toString() ?? '-';

    final squareFeet =
        listing['square_feet']?.toString() ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        actions: [
          if (!_isLoadingFavorite)
            IconButton(
              onPressed:
                  _isSavingFavorite ? null : _toggleFavorite,
              icon: Icon(
                _isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
              ),
              tooltip: _isFavorite
                  ? 'Remove Favorite'
                  : 'Save Favorite',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.home_work_outlined,
              size: 90,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            listing['title']?.toString() ??
                'Housing Listing',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${listing['address'] ?? ''}, '
            '${listing['city'] ?? ''}, '
            '${listing['state'] ?? ''} '
            '${listing['zip_code'] ?? ''}',
          ),
          const SizedBox(height: 20),
          Text(
            '\$${monthlyRent.toStringAsFixed(0)}/month',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _DetailItem(
                icon: Icons.bed_outlined,
                text: '$bedrooms beds',
              ),
              _DetailItem(
                icon: Icons.bathtub_outlined,
                text: '$bathrooms baths',
              ),
              _DetailItem(
                icon: Icons.square_foot,
                text: '$squareFeet sq ft',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (listing['military_friendly'] == true)
            const Chip(
              avatar:
                  Icon(Icons.military_tech_outlined),
              label: Text('Military Friendly'),
            ),
          if (listing['pet_friendly'] == true)
            const Chip(
              avatar: Icon(Icons.pets_outlined),
              label: Text('Pet Friendly'),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed:
                _isSavingFavorite || _isLoadingFavorite
                    ? null
                    : _toggleFavorite,
            icon: Icon(
              _isFavorite
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
            label: Text(
              _isFavorite
                  ? 'Remove from Favorites'
                  : 'Save to Favorites',
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}