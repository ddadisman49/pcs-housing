import 'package:flutter/material.dart';
import '../maps/housing_map_screen.dart';
import 'listing_detail_screen.dart';
import '../../core/services/housing_service.dart';

class HousingSearchScreen extends StatefulWidget {
  final double bahRate;
  final String dutyStation;

  const HousingSearchScreen({
    super.key,
    required this.bahRate,
    required this.dutyStation,
  });

  @override
  State<HousingSearchScreen> createState() =>
      _HousingSearchScreenState();
}

class _HousingSearchScreenState extends State<HousingSearchScreen> {
  final HousingService _housingService = HousingService();

  late double _maxHousingBudget;

  bool _isLoading = false;
  List<Map<String, dynamic>> _listings = [];

  @override
  void initState() {
    super.initState();
    _maxHousingBudget = widget.bahRate;
  }

  Future<void> _searchHousing() async {
    setState(() {
      _isLoading = true;
      _listings = [];
    });

    try {
      final listings = await _housingService.getListings(
        maxRent: _maxHousingBudget,
        militaryHousingArea: 'VA298',
      );

      if (!mounted) return;

      setState(() {
        _listings = listings;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load housing listings: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Housing Search'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Search within your BAH',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.dutyStation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Housing Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${_maxHousingBudget.toStringAsFixed(0)}',
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
                    Slider(
                      value: _maxHousingBudget,
                      min: 500,
                      max: widget.bahRate * 1.25,
                      divisions: 30,
                      label:
                          '\$${_maxHousingBudget.toStringAsFixed(0)}',
                      onChanged: (value) {
                        setState(() {
                          _maxHousingBudget = value;
                        });
                      },
                    ),
                    Text(
                      'Your current BAH is \$${widget.bahRate.toStringAsFixed(0)} per month.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _isLoading ? null : _searchHousing,
              icon: const Icon(Icons.search),
              label: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Search Housing'),
            ),

            const SizedBox(height: 28),

            if (_listings.isNotEmpty)
              Text(
                '${_listings.length} homes found',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

if (_listings.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 16),
    child: OutlinedButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HousingMapScreen(
              listings: _listings,
            ),
          ),
        );
      },
      icon: const Icon(Icons.map_outlined),
      label: const Text('View on Map'),
    ),
  ),

            if (_listings.isNotEmpty)
              const SizedBox(height: 16),

            ..._listings.map(
              (listing) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
               child: _HousingListingCard(
  listing: listing,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          listing: listing,
        ),
      ),
    );
  },
),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HousingListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  const _HousingListingCard({
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final monthlyRent =
        (listing['monthly_rent'] as num?)?.toDouble() ?? 0;

    final bedrooms = listing['bedrooms']?.toString() ?? '-';
    final bathrooms =
        listing['bathrooms']?.toString() ?? '-';
    final squareFeet =
        listing['square_feet']?.toString() ?? '-';

   return Card(
  clipBehavior: Clip.antiAlias,
  child: InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Container(
            height: 150,
            width: double.infinity,
            color: Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: Icon(
              Icons.home_work_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title']?.toString() ??
                      'Housing Listing',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${listing['address'] ?? ''}, '
                  '${listing['city'] ?? ''}, '
                  '${listing['state'] ?? ''}',
                ),
                const SizedBox(height: 14),
                Text(
                  '\$${monthlyRent.toStringAsFixed(0)}/month',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _ListingDetail(
                      icon: Icons.bed_outlined,
                      text: '$bedrooms beds',
                    ),
                    _ListingDetail(
                      icon: Icons.bathtub_outlined,
                      text: '$bathrooms baths',
                    ),
                    _ListingDetail(
                      icon: Icons.square_foot,
                      text: '$squareFeet sq ft',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (listing['military_friendly'] == true)
                      const Chip(
                        label: Text('Military Friendly'),
                        avatar: Icon(
                          Icons.military_tech_outlined,
                          size: 18,
                        ),
                      ),
                    if (listing['pet_friendly'] == true)
                      const Chip(
                        label: Text('Pet Friendly'),
                        avatar: Icon(
                          Icons.pets_outlined,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
  )
    );
  }
}

class _ListingDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ListingDetail({
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
          size: 18,
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}