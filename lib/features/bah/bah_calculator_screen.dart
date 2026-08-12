import 'package:flutter/material.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/bah_service.dart';
import '../search/housing_search_screen.dart';

class BahCalculatorScreen extends StatefulWidget {
  const BahCalculatorScreen({super.key});

  @override
  State<BahCalculatorScreen> createState() =>
      _BahCalculatorScreenState();
}

class _BahCalculatorScreenState extends State<BahCalculatorScreen> {
  final BahService _bahService = BahService();

  List<Map<String, dynamic>> _installations = [];

  Map<String, dynamic>? _selectedInstallation;
  String? _selectedPayGrade;
  bool _hasDependents = false;

  bool _isLoadingInstallations = true;
  bool _isCalculating = false;

  double? _bahRate;

 final ProfileService _profileService = ProfileService(); 

  final List<String> _payGrades = const [
    'E5',
    'E6',
    'E7',
    'O3',
    'O3E',
  ];

  @override
void initState() {
  super.initState();
  _loadInitialData();
}

  Future<void> _loadInitialData() async {
  try {
    final results = await Future.wait([
      _bahService.getInstallations(),
      _profileService.getProfile(),
    ]);

    final installations =
        List<Map<String, dynamic>>.from(results[0] as List);

    final profile =
        results[1] as Map<String, dynamic>?;

    String? savedRank;
    bool savedDependents = false;
    String? savedNextDutyStation;

    if (profile != null) {
      savedRank = profile['rank']?.toString();
      savedDependents =
          profile['has_dependents'] as bool? ?? false;
      savedNextDutyStation =
          profile['next_duty_station']?.toString();
    }

    Map<String, dynamic>? matchingInstallation;

    if (savedNextDutyStation != null &&
        savedNextDutyStation.isNotEmpty) {
      for (final installation in installations) {
        if (installation['name']?.toString().toLowerCase() ==
            savedNextDutyStation.toLowerCase()) {
          matchingInstallation = installation;
          break;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _installations = installations;

      if (savedRank != null &&
          _payGrades.contains(savedRank)) {
        _selectedPayGrade = savedRank;
      }

      _hasDependents = savedDependents;
      _selectedInstallation = matchingInstallation;

      _isLoadingInstallations = false;
    });
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _isLoadingInstallations = false;
    });

    _showMessage(
      'Unable to load BAH information: $error',
    );
  }
}

  Future<void> _calculateBah() async {
    if (_selectedInstallation == null) {
      _showMessage('Please select a duty station.');
      return;
    }

    if (_selectedPayGrade == null) {
      _showMessage('Please select a pay grade.');
      return;
    }

    final militaryHousingArea =
        _selectedInstallation!['military_housing_area']?.toString();

    if (militaryHousingArea == null ||
        militaryHousingArea.isEmpty) {
      _showMessage(
        'This duty station does not have a Military Housing Area assigned.',
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _bahRate = null;
    });

    try {
      final rate = await _bahService.getBahRate(
        militaryHousingArea: militaryHousingArea,
        payGrade: _selectedPayGrade!,
        hasDependents: _hasDependents,
        year: 2026,
      );

      if (!mounted) return;

      setState(() {
        _bahRate = rate;
      });

      if (rate == null) {
        _showMessage(
          'No BAH rate was found for this selection.',
        );
      }
    } catch (error) {
      _showMessage(
        'Unable to calculate BAH: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCalculating = false;
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
  return Scaffold(
    appBar: AppBar(
      title: const Text('BAH Calculator'),
    ),
    body: SafeArea(
      child: _isLoadingInstallations
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Estimate your monthly BAH',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your gaining duty station, pay grade, and dependent status.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _selectedInstallation,
                  decoration: const InputDecoration(
                    labelText: 'Duty Station',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _installations
                      .map(
                        (installation) =>
                            DropdownMenuItem<Map<String, dynamic>>(
                          value: installation,
                          child: Text(
                            installation['name']?.toString() ??
                                'Unknown Installation',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInstallation = value;
                      _bahRate = null;
                    });
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedPayGrade,
                  decoration: const InputDecoration(
                    labelText: 'Pay Grade',
                    prefixIcon: Icon(Icons.military_tech_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: _payGrades
                      .map(
                        (payGrade) => DropdownMenuItem<String>(
                          value: payGrade,
                          child: Text(payGrade),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPayGrade = value;
                      _bahRate = null;
                    });
                  },
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('With Dependents'),
                  subtitle: const Text(
                    'Use the BAH rate for members with dependents.',
                  ),
                  value: _hasDependents,
                  onChanged: (value) {
                    setState(() {
                      _hasDependents = value;
                      _bahRate = null;
                    });
                  },
                ),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: _isCalculating ? null : _calculateBah,
                  icon: const Icon(Icons.calculate_outlined),
                  label: _isCalculating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Calculate BAH'),
                ),

                const SizedBox(height: 28),

                if (_bahRate != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Estimated Monthly BAH',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '\$${_bahRate!.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedInstallation?['name']
                                    ?.toString() ??
                                '',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedPayGrade ?? ''} • ${_hasDependents ? 'With Dependents' : 'Without Dependents'}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Development test rate only. Official DoD BAH data will replace this test data before release.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HousingSearchScreen(
                                      bahRate: _bahRate!,
                                      dutyStation:
                                          _selectedInstallation?[
                                                      'name']
                                                  ?.toString() ??
                                              '',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.home_work_outlined,
                              ),
                              label: const Text(
                                'Find Housing Within BAH',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    ),
  );
}
}