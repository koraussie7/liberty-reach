import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hyperspace_service.dart';
import '../core/theme/app_theme.dart';

class HyperspaceDashboard extends StatelessWidget {
  const HyperspaceDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final hs = context.watch<HyperspaceService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyperspace Node'),
        actions: [
          IconButton(
            icon: Icon(hs.nodeRunning
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outline),
            onPressed: () async {
              if (hs.nodeRunning) {
                await hs.stopNode();
              } else {
                await hs.startNode();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => hs.fetchStatus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      hs.agentOnline
                          ? Icons.wifi_tethering
                          : Icons.wifi_off,
                      size: 64,
                      color: hs.agentOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hs.agentOnline ? 'Node Running' : 'Node Stopped',
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (hs.agentOnline) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Agent API: OK',
                        style: TextStyle(color: Colors.green),
                      ),
                      Text(
                        'Chain: ${hs.chainOnline ? "Block #${hs.chainBlock}" : "Offline"}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Network Stats',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Divider(),
                    _statRow(
                        Icons.cloud_done, '2M+ nodes', 'P2P Network Available'),
                    _statRow(Icons.memory, '${hs.models.length} models',
                        'Served by node'),
                    _statRow(Icons.link, 'Chain 808080',
                        hs.chainOnline ? 'Synced' : 'Syncing...'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Models',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Divider(),
                    if (hs.models.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'No models available. Start node to fetch.'),
                      )
                    else
                      ...hs.models.take(5).map((m) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.model_training),
                            title: Text(m['id']?.toString() ??
                                m['name']?.toString() ??
                                'Unknown'),
                            subtitle:
                                Text('${m['owned_by'] ?? 'hyperspace'}'),
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ]),
    );
  }
}
