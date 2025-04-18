import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/user_score_provider.dart';
import '../utils/utils.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de période
            _buildPeriodSelector(),
            const SizedBox(height: 16.0),

            // Graphique d'évolution du score
            _buildScoreChart(),
            const SizedBox(height: 24.0),

            // Statistiques de performance
            _buildStatsCards(),
            const SizedBox(height: 24.0),

            // Historique des actions
            const Text(
              'Historique d\'activités',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),

            // Liste des dernières actions
            _buildActivityHistory(),
          ],
        ),
      ),
    );
  }

  // Construit le sélecteur de période
  Widget _buildPeriodSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(value: 'week', label: Text('Semaine')),
        ButtonSegment<String>(value: 'month', label: Text('Mois')),
        ButtonSegment<String>(value: 'all', label: Text('Tout')),
      ],
      selected: {_selectedPeriod},
      onSelectionChanged: (newSelection) {
        setState(() {
          _selectedPeriod = newSelection.first;
        });
      },
    );
  }

  // Construit le graphique d'évolution du score
  Widget _buildScoreChart() {
    return Consumer<UserScoreProvider>(
      builder: (context, scoreProvider, _) {
        final chartData = scoreProvider.getChartData(_selectedPeriod, 7);

        if (chartData.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Pas assez de données pour afficher le graphique'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du score',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                chartData[value.toInt()]['date'].toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        chartData.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          chartData[index]['score'].toDouble(),
                        ),
                      ),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.indigo.withOpacity(0.8), Colors.indigo],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.withOpacity(0.3),
                            Colors.indigo.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Construit les cartes de statistiques
  Widget _buildStatsCards() {
    return Consumer<UserScoreProvider>(
      builder: (context, scoreProvider, _) {
        final stats = scoreProvider.getStatsByPeriod(_selectedPeriod);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.add_circle,
                  title: 'Points gagnés',
                  value: stats['positivePoints'].toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 12.0),
                _buildStatCard(
                  icon: Icons.remove_circle,
                  title: 'Points perdus',
                  value: stats['negativePoints'].toString(),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                _buildStatCard(
                  icon: Icons.trending_up,
                  title: 'Bilan net',
                  value:
                      (stats['positivePoints'] - stats['negativePoints'])
                          .toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 12.0),
                _buildStatCard(
                  icon: Icons.history,
                  title: 'Actions',
                  value: stats['actionsCount'].toString(),
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Construit une carte de statistique
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.0,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: color is MaterialColor ? color.shade800 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construit l'historique des activités
  Widget _buildActivityHistory() {
    return Consumer<UserScoreProvider>(
      builder: (context, scoreProvider, _) {
        final history = _filterHistoryByPeriod(scoreProvider.history);

        if (history.isEmpty) {
          return const Center(
            child: Text('Aucune activité pour cette période'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final record = history[index];
            final isPositive = record.pointsChange > 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPositive ? Colors.green : Colors.red,
                  child: Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.white,
                  ),
                ),
                title: Text(record.action ?? 'Activité'),
                subtitle: Text(
                  Utils.formatDateTime(record.date),
                  style: const TextStyle(fontSize: 12.0),
                ),
                trailing: Text(
                  '${isPositive ? '+' : ''}${record.pointsChange}',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Filtre l'historique en fonction de la période sélectionnée
  List<ScoreRecord> _filterHistoryByPeriod(List<ScoreRecord> history) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        // Début de la semaine (lundi)
        final weekDay = now.weekday;
        startDate = DateTime(now.year, now.month, now.day - weekDay + 1);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'all':
        return history;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    return history
        .where((record) => record.date.isAfter(startDate))
        .toList()
        .reversed
        .toList();
  }
}
