import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/achievement.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
      ),
      body: Consumer<AchievementProvider>(
        builder: (context, provider, _) {
          final achievements = provider.achievements;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: achievement.isUnlocked
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                achievement.icon,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  achievement.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  achievement.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (achievement.isUnlocked)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: achievement.progress / achievement.requirementValue,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          achievement.isUnlocked ? Colors.green : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${((achievement.progress / achievement.requirementValue) * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}