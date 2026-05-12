import 'package:flutter/material.dart';

class LoopsListScreen extends StatelessWidget {
  const LoopsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('모든 Loops')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 24,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, index) => _LoopCard(index: index),
      ),
    );
  }
}

class _LoopCard extends StatelessWidget {
  final int index;

  const _LoopCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/loops/player', arguments: index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.primaries[index % Colors.primaries.length].withOpacity(0.4),
              Colors.primaries[(index + 3) % Colors.primaries.length].withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, color: Colors.white70, size: 28),
            const SizedBox(height: 6),
            Text('Loop ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${120 + index * 15}회', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
