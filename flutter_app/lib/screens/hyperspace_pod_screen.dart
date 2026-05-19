import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/hyperspace_pod_service.dart';

class HyperspacePodScreen extends StatefulWidget {
  const HyperspacePodScreen({super.key});
  @override
  State<HyperspacePodScreen> createState() => _HyperspacePodScreenState();
}

class _HyperspacePodScreenState extends State<HyperspacePodScreen> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => context.read<HyperspacePodService>().fetchMembers());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pod = context.watch<HyperspacePodService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Pods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Pod', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Pod Name',
                      hintText: 'e.g., my-ai-cluster',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: pod.loading
                        ? null
                        : () async {
                            final name = _nameController.text.trim();
                            if (name.isEmpty) return;
                            final ok = await context
                                .read<HyperspacePodService>()
                                .createPod(name);
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Pod "$name" created')),
                              );
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Pod'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (pod.currentPodId != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invite Link',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final link = await context
                            .read<HyperspacePodService>()
                            .getInviteLink();
                        if (link != null && mounted) {
                          await Clipboard.setData(
                              ClipboardData(text: link));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Invite link copied!')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Generate & Copy Invite'),
                    ),
                    if (pod.inviteLink != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(pod.inviteLink!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Members',
                          style: theme.textTheme.titleMedium),
                      IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => context
                              .read<HyperspacePodService>()
                              .fetchMembers()),
                    ],
                  ),
                  const Divider(),
                  if (pod.members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'No members. Create or join a pod.'),
                    )
                  else
                    ...pod.members.map((m) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: m.isOnline
                                ? Colors.green
                                : Colors.grey,
                            child: Text(m.name
                                    ?.substring(0, 2)
                                    .toUpperCase() ??
                                '??'),
                          ),
                          title: Text(m.name ?? m.peerId),
                          subtitle:
                              Text('${m.gpu ?? "CPU"} · ${m.vram}GB'),
                          trailing: Icon(
                            m.isOnline
                                ? Icons.circle
                                : Icons.circle_outlined,
                            color: m.isOnline
                                ? Colors.green
                                : Colors.grey,
                            size: 12,
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
