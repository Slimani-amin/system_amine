import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_score_provider.dart';
import '../utils/utils.dart';

class ScoreDisplay extends StatelessWidget {
  const ScoreDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserScoreProvider>(
      builder: (context, scoreProvider, _) {
        final score = scoreProvider.score;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          decoration: BoxDecoration(
            gradient: Utils.getScoreGradient(score),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Votre score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                score.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              _buildScoreDescription(score),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreDescription(int score) {
    String description;

    if (score >= 80) {
      description = 'Excellent! Continuez ainsi!';
    } else if (score >= 60) {
      description = 'Bien! Vous êtes sur la bonne voie.';
    } else if (score >= 40) {
      description = 'Moyen. Vous pouvez faire mieux!';
    } else {
      description = 'Attention! Votre score est bas.';
    }

    return Text(
      description,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }
}
