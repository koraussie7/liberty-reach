import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/hyperspace_earnings_service.dart';

class HyperspaceEarningsScreen extends StatefulWidget {
  const HyperspaceEarningsScreen({super.key});

  @override
  State<HyperspaceEarningsScreen> createState() =>
      _HyperspaceEarningsScreenState();
}

class _HyperspaceEarningsScreenState extends State<HyperspaceEarningsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<HyperspaceEarningsService>().fetchEarnings());
  }

  @override
  Widget build(BuildContext context) {
    final earnings = context.watch<HyperspaceEarningsService>();
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat('#,##0.0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<HyperspaceEarningsService>().fetchEarnings(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => earnings.fetchEarnings(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Total Points Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 56,
                      color: Colors.amber.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total Points',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(earnings.totalPoints),
                      style: theme.textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'earned from node contributions',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Earnings History
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earnings History',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Divider(),
                    if (earnings.loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (earnings.history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('No earnings yet.'),
                        ),
                      )
                    else
                      ...earnings.history.map((entry) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor:
                                  entry.points >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                              radius: 18,
                              child: Icon(
                                entry.points >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: entry.points >= 0
                                    ? Colors.green
                                    : Colors.red,
                                size: 18,
                              ),
                            ),
                            title: Text(entry.description),
                            subtitle: Text(
                              DateFormat('MMM d, HH:mm')
                                  .format(entry.timestamp),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '${entry.points >= 0 ? '+' : ''}${currencyFormat.format(entry.points)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: entry.points >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Leaderboard
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events,
                            color: Colors.amber.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Leaderboard',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Divider(),
                    if (earnings.leaderboard.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text('No leaderboard data yet.'),
                        ),
                      )
                    else
                      ...earnings.leaderboard.map((entry) {
                        IconData medal;
                        Color medalColor;
                        if (entry.rank == 1) {
                          medal = Icons.emoji_events;
                          medalColor = Colors.amber;
                        } else if (entry.rank == 2) {
                          medal = Icons.emoji_events;
                          medalColor = Colors.grey.shade400;
                        } else if (entry.rank == 3) {
                          medal = Icons.emoji_events;
                          medalColor = Colors.brown.shade300;
                        } else {
                          medal = Icons.circle;
                          medalColor = Colors.grey.shade300;
                        }

                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: medalColor.withValues(alpha: 0.2),
                            radius: 18,
                            child: Icon(medal,
                                color: medalColor, size: 18),
                          ),
                          title: Text(
                            entry.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            currencyFormat.format(entry.points),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }),
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
