import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/video_call_service.dart';

class VideoCallScreen extends StatelessWidget {
  final String? remotePeerId;
  final String? remotePeerName;

  const VideoCallScreen({super.key, this.remotePeerId, this.remotePeerName});

  @override
  Widget build(BuildContext context) {
    final callService = context.watch<VideoCallService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.grey[700],
                            child: Icon(Icons.person, size: 48, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            callService.remotePeerName ?? 'Connecting...',
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _statusText(callService.state),
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (callService.state == CallState.ringing)
                  Container(
                    height: 100,
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _callButton(Icons.call, Colors.green, () => callService.acceptCall()),
                        const SizedBox(width: 40),
                        _callButton(Icons.call_end, Colors.red, () => callService.rejectCall()),
                      ],
                    ),
                  ),
                if (callService.state == CallState.connected || callService.state == CallState.calling)
                  Container(
                    height: 100,
                    color: Colors.black,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _callButton(
                          callService.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                          Colors.grey[700]!,
                          () => callService.toggleVideo(),
                        ),
                        _callButton(
                          callService.isAudioEnabled ? Icons.mic : Icons.mic_off,
                          Colors.grey[700]!,
                          () => callService.toggleAudio(),
                        ),
                        _callButton(Icons.call_end, Colors.red, () {
                          callService.endCall();
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                  ),
              ],
            ),
            if (callService.state == CallState.ended)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Call Ended', style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _callButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  String _statusText(CallState state) {
    switch (state) {
      case CallState.idle: return 'Ready';
      case CallState.calling: return 'Calling...';
      case CallState.ringing: return 'Incoming call...';
      case CallState.connected: return 'Connected';
      case CallState.ended: return 'Call ended';
    }
  }
}
