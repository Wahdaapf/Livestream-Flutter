import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../providers/livestream_provider.dart';

class LivestreamScreen extends StatefulWidget {
  const LivestreamScreen({super.key});

  @override
  State<LivestreamScreen> createState() => _LivestreamScreenState();
}

class _LivestreamScreenState extends State<LivestreamScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivestreamProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<LivestreamProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // 1. Fullscreen Video Background
              _buildVideoBackground(provider),

              // 2. Top Header (Streamer Info & Viewer Count)
              _buildHeader(provider),

              // 3. Right Sidebar (Interactions)
              _buildRightSidebar(),

              // 4. Bottom Chat Overlay
              _buildChatOverlay(provider),

              // 5. Actions (Go Live / Stop)
              _buildActionButtons(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoBackground(LivestreamProvider provider) {
    if (!provider.isLive) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white70, size: 60),
            const SizedBox(height: 10),
            Text(
              provider.currentUser?.isHost ?? false
                  ? 'Tap "GO LIVE" to start'
                  : 'Waiting for stream to start...',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (provider.currentUser?.isHost ?? false) {
      return RTCVideoView(
        provider.webRTCService.localRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    } else {
      return RTCVideoView(
        provider.webRTCService.remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }
  }

  Widget _buildHeader(LivestreamProvider provider) {
    return Positioned(
      top: 50,
      left: 15,
      right: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.pink,
                  child: Text(
                    provider.currentUser?.name[0].toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.currentUser?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Live Stream',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
                if (!(provider.currentUser?.isHost ?? false)) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  '${provider.viewerCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Positioned(
      right: 15,
      bottom: 200,
      child: Column(
        children: [
          _buildSideIcon(Icons.card_giftcard, 'Gift', Colors.orange),
          const SizedBox(height: 20),
          _buildSideIcon(Icons.favorite, '12.5k', Colors.pink),
          const SizedBox(height: 20),
          _buildSideIcon(Icons.share, 'Share', Colors.white),
        ],
      ),
    );
  }

  Widget _buildSideIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 35),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildChatOverlay(LivestreamProvider provider) {
    return Positioned(
      bottom: 80,
      left: 15,
      right: 100,
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                final msg = provider.messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${msg.sender}: ',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: msg.text,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add comment...',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      provider.sendMessage(
                        val,
                        provider.currentUser?.name ?? 'Me',
                      );
                      _chatController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  if (_chatController.text.isNotEmpty) {
                    provider.sendMessage(
                      _chatController.text,
                      provider.currentUser?.name ?? 'Me',
                    );
                    _chatController.clear();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LivestreamProvider provider) {
    if (!(provider.currentUser?.isHost ?? false))
      return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 15,
      right: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!provider.isLive)
            ElevatedButton(
              onPressed: () => provider.startLive(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'GO LIVE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          else
            IconButton(
              onPressed: () => provider.stopLive(),
              icon: const Icon(Icons.close, color: Colors.white, size: 40),
            ),
        ],
      ),
    );
  }
}
