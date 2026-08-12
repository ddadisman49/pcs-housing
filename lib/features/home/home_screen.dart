import 'package:flutter/material.dart';
import '../bah/bah_calculator_screen.dart';
import '../../widgets/feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCS Housing'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Plan your next PCS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find housing, compare BAH, and prepare for your next duty station.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),

            FeatureCard(
              icon: Icons.home_work_outlined,
              title: 'Find Housing',
              subtitle: 'Search homes and apartments within your BAH.',
              onTap: () {},
            ),

            const SizedBox(height: 14),

            FeatureCard(
              icon: Icons.calculate_outlined,
              title: 'BAH Calculator',
              subtitle: 'Compare your housing allowance with local costs.',
              onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const BahCalculatorScreen(),
    ),
  );
},
),
            const SizedBox(height: 14),

            FeatureCard(
              icon: Icons.auto_awesome_outlined,
              title: 'AI PCS Assistant',
              subtitle: 'Get personalized relocation recommendations.',
              onTap: () {},
            ),

            const SizedBox(height: 14),

            FeatureCard(
              icon: Icons.favorite_outline,
              title: 'Saved Homes',
              subtitle: 'Review homes and apartments you have saved.',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}