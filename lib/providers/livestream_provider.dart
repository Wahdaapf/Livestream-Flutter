import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/webrtc_service.dart';
import '../models/user_model.dart';
import '../services/signaling_service.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class LivestreamProvider with ChangeNotifier {
  final WebRTCService _webRTCService = WebRTCService();
  final SignalingService _signalingService = SignalingService();
  final List<ChatMessage> _messages = [];
  int _viewerCount = 0;
  bool _isLive = false;
  UserModel? _currentUser;

  WebRTCService get webRTCService => _webRTCService;
  List<ChatMessage> get messages => _messages;
  int get viewerCount => _viewerCount;
  bool get isLive => _isLive;
  UserModel? get currentUser => _currentUser;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> init() async {
    await _webRTCService.init();
    if (_currentUser != null && !_currentUser!.isHost) {
      // Automagically join if viewer
      joinLive();
    }
    notifyListeners();
  }

  Future<void> startLive() async {
    if (_currentUser == null || !_currentUser!.isHost) return;

    print("HOST: Starting live stream...");
    await _signalingService.cleanRoom(); // Reset room
    print("HOST: Room cleaned");

    await _webRTCService.openUserMedia();
    print("HOST: Camera opened");

    await _webRTCService.setupPeerConnection(true, (candidate) {
      print("HOST: Generated ICE candidate, sending to Firebase");
      _signalingService.addCandidate(candidate, true);
    });
    print("HOST: Peer connection set up");

    final offer = await _webRTCService.createOffer();
    print("HOST: Offer created");

    await _signalingService.createRoom(offer);
    print("HOST: Room created with offer");

    _signalingService.listenForAnswer((answer) {
      print("HOST: Received answer from viewer");
      _webRTCService.setRemoteDescription(answer);
      print("HOST: Remote description set");
    });

    _signalingService.listenForCandidates(true, (candidate) {
      print("HOST: Received ICE candidate from viewer");
      _webRTCService.addCandidate(candidate);
    });

    _isLive = true;
    _viewerCount = 1;
    notifyListeners();
    print("HOST: Live stream started successfully!");
  }

  Future<void> joinLive() async {
    if (_currentUser == null || _currentUser!.isHost) return;

    try {
      print("VIEWER: Attempting to join live stream...");

      // Set up peer connection first
      await _webRTCService.setupPeerConnection(false, (candidate) {
        print("VIEWER: Generated ICE candidate, sending to host");
        _signalingService.addCandidate(candidate, false);
      });

      // Listen for host's ICE candidates
      _signalingService.listenForCandidates(false, (candidate) {
        print("VIEWER: Received ICE candidate from host");
        _webRTCService.addCandidate(candidate);
      });

      // Check if room already exists
      final roomSnapshot = await _signalingService.db
          .collection('rooms')
          .doc('livestream')
          .get();

      if (roomSnapshot.exists && roomSnapshot.data()?['offer'] != null) {
        // Room exists with offer, process it immediately
        print("VIEWER: Room exists, processing existing offer...");
        var offerData = roomSnapshot.data()!['offer'];
        RTCSessionDescription offer = RTCSessionDescription(
          offerData['sdp'],
          offerData['type'],
        );

        // Create and send answer
        print("VIEWER: Creating answer...");
        final answer = await _webRTCService.createAnswer(offer);
        await _signalingService.answerRoom(answer);
        print("VIEWER: Answer sent to host");

        _isLive = true;
        notifyListeners();
      } else {
        // Room doesn't exist yet, wait for host to start
        print("VIEWER: Waiting for host to start streaming...");
        _signalingService.listenForOffer((offer) async {
          print("VIEWER: Host started streaming! Processing offer...");

          // Create and send answer
          final answer = await _webRTCService.createAnswer(offer);
          await _signalingService.answerRoom(answer);
          print("VIEWER: Answer sent to host");

          _isLive = true;
          notifyListeners();
        });
      }
    } catch (e) {
      print("VIEWER ERROR: Failed to join live stream - $e");
      print("VIEWER ERROR Stack: ${StackTrace.current}");
    }
  }

  void stopLive() {
    _webRTCService.dispose();
    if (_currentUser?.isHost ?? false) {
      _signalingService.cleanRoom();
    }
    _isLive = false;
    _viewerCount = 0;
    notifyListeners();
  }

  void sendMessage(String text, String sender) {
    final message = ChatMessage(
      id: DateTime.now().toString(),
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
    );
    _messages.add(message);
    notifyListeners();
  }

  void updateViewerCount(int count) {
    _viewerCount = count;
    notifyListeners();
  }
}
