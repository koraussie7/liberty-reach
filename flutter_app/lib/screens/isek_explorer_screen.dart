import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/isek_service.dart';

/// Agent Explorer — browse the ISEK network, view agent cards, and send
/// quick A2A messages to discovered agents.
class ISEKExplorerScreen extends StatelessWidget {
  const ISEKExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isek = context.watch<ISEKService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISEK Agent Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh agents',
            onPressed: () => isek.discoverAgents(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => isek.discoverAgents(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Relay status card ──────────────────────────────────────
            _RelayStatusCard(isek: isek, theme: theme),
            const SizedBox(height: 16),

            // ── Agent list ─────────────────────────────────────────────
            Text('Agent Explorer', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),

            if (isek.discoveredAgents.isEmpty)
              _EmptyState()
            else
              ...isek.discoveredAgents.map(
                (agent) => _AgentCard(agent: agent),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _RelayStatusCard extends StatelessWidget {
  const _RelayStatusCard({required this.isek, required this.theme});

  final ISEKService isek;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isek.relayRunning ? Icons.wifi : Icons.wifi_off,
              color: isek.relayRunning ? Colors.green : Colors.red,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ISEK Relay', style: theme.textTheme.titleMedium),
                  Text(
                    isek.relayRunning ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      color: isek.relayRunning ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isek.relayRunning ? null : () => isek.startRelay(),
              child: Text(isek.relayRunning ? 'Running' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No agents discovered',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Start the ISEK relay to discover agents on the network',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.agent});

  final dynamic agent; // ISEKAgentCard

  @override
  Widget build(BuildContext context) {
    final a = agent;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            (a.name?.isNotEmpty == true ? a.name[0] : '?').toUpperCase(),
          ),
        ),
        title: Text(a.name ?? 'Unknown'),
        subtitle: Text('${a.skills?.length ?? 0} skills · ${a.version ?? '?'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAgentDialog(context, a),
      ),
    );
  }

  void _showAgentDialog(BuildContext context, dynamic agent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(agent.name ?? 'Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(agent.description ?? ''),
            if (agent.url != null) ...[
              const SizedBox(height: 8),
              Text(
                'URL: ${agent.url}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
            Text('Version: ${agent.version ?? '?'}'),
            if ((agent.skills ?? []).isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...agent.skills.map(
                (s) => Text(' • $s', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openQuickChat(context, agent);
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  void _openQuickChat(BuildContext context, dynamic agent) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Message ${agent.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your message...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final q = controller.text.trim();
                if (q.isEmpty) return;
                Navigator.pop(ctx);
                final result =
                    await context.read<ISEKService>().sendA2A(agent.url, q);
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: Text('${agent.name} Response'),
                      content: SingleChildScrollView(child: Text(result)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Send'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
