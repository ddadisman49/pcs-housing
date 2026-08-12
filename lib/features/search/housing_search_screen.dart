import 'package:flutter/material.dart';

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
  late double _maxHousingBudget;

  @override
  void initState() {
    super.initState();
    _maxHousingBudget = widget.bahRate;
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

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Housing search will use a max budget of \$${_maxHousingBudget.toStringAsFixed(0)}.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: const Text('Search Housing'),
            ),
          ],
        ),
      ),
    );
  }
}