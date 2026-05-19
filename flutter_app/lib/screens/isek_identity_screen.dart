import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/isek_service.dart';

/// Agent Identity — register an ERC-8004 blockchain identity for an agent
/// and manage existing registrations.
class ISEKIdentityScreen extends StatefulWidget {
  const ISEKIdentityScreen({super.key});

  @override
  State<ISEKIdentityScreen> createState() => _ISEKIdentityScreenState();
}

class _ISEKIdentityScreenState extends State<ISEKIdentityScreen> {
  final _urlController = TextEditingController(text: 'http://localhost:9999');
  final _nameController = TextEditingController(text: 'DADA-Hermes');
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _registerIdentity() async {
    setState(() => _loading = true);
    final isek = context.read<ISEKService>();
    final result = await isek.registerIdentity(_urlController.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ERC-8004 Identity'),
        content: result.isEmpty
            ? const Text('Registration failed. Check the server logs.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Address', result['address']?.toString() ?? '—'),
                  _kv('Agent ID', result['agent_id']?.toString() ?? '—'),
                  _kv('Tx Hash', result['tx_hash']?.toString() ?? '—'),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isek = context.watch<ISEKService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Identity — ERC-8004')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Info card ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Text('ERC-8004 Identity', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Register your agent on the blockchain to give it a '
                    'verifiable, on-chain identity. This enables other agents '
                    'on the ISEK network to discover and trust your agent.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Form ─────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Register New Identity', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Agent Name',
                      hintText: 'e.g. DADA-Hermes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Agent URL',
                      hintText: 'http://localhost:9999',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _registerIdentity,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user),
                      label: Text(_loading ? 'Registering...' : 'Register Identity'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Relay connection status ──────────────────────────────────
          Card(
            child: ListTile(
              leading: Icon(
                isek.relayRunning ? Icons.wifi : Icons.wifi_off,
                color: isek.relayRunning ? Colors.green : Colors.grey,
              ),
              title: Text(isek.relayRunning ? 'Relay Connected' : 'Relay Disconnected'),
              subtitle: Text(
                isek.relayRunning
                    ? 'Identity registration requires an active relay'
                    : 'Start the relay in the ISEK Explorer first',
              ),
              trailing: isek.relayRunning
                  ? null
                  : ElevatedButton(
                      onPressed: () => isek.startRelay(),
                      child: const Text('Start Relay'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
