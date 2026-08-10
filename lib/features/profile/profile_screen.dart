import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();

  final _fullNameController = TextEditingController();
  final _rankController = TextEditingController();
  final _currentDutyStationController = TextEditingController();
  final _nextDutyStationController = TextEditingController();

  final List<String> _branches = const [
    'Air Force',
    'Army',
    'Coast Guard',
    'Marine Corps',
    'Navy',
    'Space Force',
  ];

  String? _selectedBranch;
  bool _hasDependents = false;
  DateTime? _pcsDate;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getProfile();

      if (profile != null) {
        _fullNameController.text =
            profile['full_name']?.toString() ?? '';

        _rankController.text =
            profile['rank']?.toString() ?? '';

        _currentDutyStationController.text =
            profile['current_duty_station']?.toString() ?? '';

        _nextDutyStationController.text =
            profile['next_duty_station']?.toString() ?? '';

        final branch = profile['branch']?.toString();

        if (branch != null && _branches.contains(branch)) {
          _selectedBranch = branch;
        }

        _hasDependents =
            profile['has_dependents'] as bool? ?? false;

        final pcsDateValue = profile['pcs_date']?.toString();

        if (pcsDateValue != null && pcsDateValue.isNotEmpty) {
          _pcsDate = DateTime.tryParse(pcsDateValue);
        }
      }
    } catch (error) {
      _showMessage('Unable to load profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    final rank = _rankController.text.trim();
    final currentDutyStation =
        _currentDutyStationController.text.trim();
    final nextDutyStation =
        _nextDutyStationController.text.trim();

    if (fullName.isEmpty) {
      _showMessage('Please enter your full name.');
      return;
    }

    if (_selectedBranch == null) {
      _showMessage('Please select your military branch.');
      return;
    }

    if (rank.isEmpty) {
      _showMessage('Please enter your rank.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.updateProfile(
        fullName: fullName,
        branch: _selectedBranch!,
        rank: rank,
        hasDependents: _hasDependents,
        currentDutyStation: currentDutyStation,
        nextDutyStation: nextDutyStation,
        pcsDate: _pcsDate,
      );

      _showMessage('Profile saved successfully.');
    } catch (error) {
      _showMessage('Unable to save profile: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectPcsDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _pcsDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate != null) {
      setState(() {
        _pcsDate = selectedDate;
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
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
  void dispose() {
    _fullNameController.dispose();
    _rankController.dispose();
    _currentDutyStationController.dispose();
    _nextDutyStationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PCS Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Military profile',
              style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
            const SizedBox(height: 8),
            Text(
              'This information will eventually help PCS Housing calculate BAH and personalize housing recommendations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedBranch,
              decoration: const InputDecoration(
                labelText: 'Military Branch',
                prefixIcon: Icon(Icons.military_tech_outlined),
                border: OutlineInputBorder(),
              ),
              items: _branches
                  .map(
                    (branch) => DropdownMenuItem(
                      value: branch,
                      child: Text(branch),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBranch = value;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _rankController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Rank',
                hintText: 'Example: E6, O3, O3E',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dependents'),
              subtitle: const Text(
                'Turn this on if your BAH should use the with-dependents rate.',
              ),
              value: _hasDependents,
              onChanged: (value) {
                setState(() {
                  _hasDependents = value;
                });
              },
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _currentDutyStationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Current Duty Station',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nextDutyStationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Next Duty Station',
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _selectPcsDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _pcsDate == null
                    ? 'Select PCS Date'
                    : 'PCS Date: ${_pcsDate!.month}/${_pcsDate!.day}/${_pcsDate!.year}',
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Profile'),
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}