import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/agixt_service.dart';

class AGiXTAgentsScreen extends StatefulWidget {
  const AGiXTAgentsScreen({super.key});

  @override
  State<AGiXTAgentsScreen> createState() => _AGiXTAgentsScreenState();
}

class _AGiXTAgentsScreenState extends State<AGiXTAgentsScreen> {
  final _nameCtrl = TextEditingController();
  final _modelCtrl = TextEditingController(text: 'gpt-4o-mini');

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<AGiXTService>().checkHealth();
      await context.read<AGiXTService>().listAgents();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AGiXTService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AGiXT Agents')),
      body: RefreshIndicator(
        onRefresh: () async {
          await a.listAgents();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Health status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Icon(
                    a.healthy ? Icons.check_circle : Icons.error,
                    color: a.healthy ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  Text(
                    a.healthy ? 'AGiXT Connected' : 'AGiXT Unreachable',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (!a.healthy)
                    ElevatedButton(
                      onPressed: () => a.checkHealth(),
                      child: const Text('Retry'),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Create Agent card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Agent',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Agent Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.smart_toy),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _modelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.model_training),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: a.loading
                            ? null
                            : () async {
                                final name = _nameCtrl.text.trim();
                                if (name.isEmpty) return;
                                final ok = await context
                                    .read<AGiXTService>()
                                    .createAgent(name,
                                        model: _modelCtrl.text.trim());
                                if (ok && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Agent "$name" created')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Agent'),
                      ),
                    ]),
              ),
            ),
            const SizedBox(height: 16),

            // Agents list
            Text(
              'Your Agents (${a.agents.length})',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (a.agents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No agents. Create one above!',
                      textAlign: TextAlign.center),
                ),
              )
            else
              ...a.agents.map((agent) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                            (agent['name']?.toString() ?? 'A')[0]),
                      ),
                      title: Text(
                          agent['name']?.toString() ?? 'Unnamed'),
                      subtitle: Text(
                          'Model: ${agent['settings']?['AI_MODEL'] ?? 'default'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _promptDialog(
                          context, agent['name']?.toString() ?? 'default'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _promptDialog(BuildContext ctx, String agentName) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(c).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Prompt $agentName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your prompt...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final input = ctrl.text.trim();
                if (input.isEmpty) return;
                Navigator.pop(c);
                final resp = await context
                    .read<AGiXTService>()
                    .promptAgent(agentName, input);
                if (ctx.mounted) {
                  showDialog(
                    context: ctx,
                    builder: (dc) => AlertDialog(
                      title: Text('$agentName responds'),
                      content: SingleChildScrollView(
                        child: Text(resp),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dc),
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
