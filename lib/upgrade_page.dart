import 'package:flutter/material.dart';

class UpgradePage extends StatelessWidget {
  const UpgradePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Premium Plans',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a plan to access advanced workout programs',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF71757F),
                  ),
                ),
                const SizedBox(height: 24),
                _buildPlanCard(
                  title: 'Beginner Plan - Single Muscle',
                  price: 'Free',
                  features: [
                    'Basic single muscle workouts',
                    'Basic exercise library',
                    'Progress tracking',
                    'Basic workout routines',
                  ],
                  isPremium: false,
                ),
                _buildPlanCard(
                  title: 'Beginner Plan - PPL',
                  price: 'Free',
                  features: [
                    'Basic PPL workout plans',
                    'Basic form guidance',
                    'Progress tracking',
                    'Basic PPL routines',
                  ],
                  isPremium: false,
                ),
                _buildPlanCard(
                  title: 'Intermediate Plan - Single Muscle',
                  price: '₹149',
                  features: [
                    'Intermediate muscle workouts',
                    'Advanced exercise library',
                    'Detailed progress tracking',
                    'Custom workout routines',
                  ],
                  isPremium: true,
                ),
                _buildPlanCard(
                  title: 'Intermediate Plan - PPL',
                  price: '₹149',
                  features: [
                    'Intermediate PPL workouts',
                    'Form guidance videos',
                    'Progressive overload tracking',
                    'Custom PPL routines',
                  ],
                  isPremium: true,
                ),
                _buildPlanCard(
                  title: 'Advanced Plan - Single Muscle',
                  price: '₹199',
                  features: [
                    'Advanced muscle workouts',
                    'Premium exercise library',
                    'Advanced progress analytics',
                    'Personalized routines',
                  ],
                  isPremium: true,
                ),
                _buildPlanCard(
                  title: 'Advanced Plan - PPL',
                  price: '₹199',
                  features: [
                    'Advanced PPL programs',
                    'Expert form guidance',
                    'Advanced progress tracking',
                    'Professional PPL routines',
                  ],
                  isPremium: true,
                ),
                _buildPlanCard(
                  title: 'Complete Access',
                  price: '₹599',
                  features: [
                    'Access to all workout plans',
                    'Premium features',
                    'Priority support',
                    'Exclusive content',
                  ],
                  isPremium: true,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> features,
    required bool isPremium,
    bool isHighlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF4285F4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : const Color(0xFF1A2138),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price + (isPremium ? '/month' : ''),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : const Color(0xFF4285F4),
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: isHighlighted ? Colors.white70 : const Color(0xFF4285F4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    feature,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHighlighted ? Colors.white70 : const Color(0xFF71757F),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle subscription
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHighlighted ? Colors.white : const Color(0xFF4285F4),
                  foregroundColor: isHighlighted ? const Color(0xFF4285F4) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isPremium ? 'Subscribe Now' : 'Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}