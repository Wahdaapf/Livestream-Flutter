import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  MediaStream? localStream;
  RTCPeerConnection? peerConnection;

  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> openUserMedia({bool enableCamera = true}) async {
    if (!enableCamera) {
      print("WEBRTC: Viewer mode - camera not needed");
      return;
    }

    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };

    try {
      if (navigator.mediaDevices == null) {
        print(
          "CAMERA ERROR: Browser blocked access because this is not a Secure Context (HTTPS).",
        );
        return;
      }
      localStream = await navigator.mediaDevices.getUserMedia(constraints);
      localRenderer.srcObject = localStream;
      print("WEBRTC: Camera and microphone initialized successfully");
    } catch (e) {
      print("Error accessing media devices: $e");
      rethrow;
    }
  }

  Future<void> setupPeerConnection(
    bool isHost,
    Function(RTCIceCandidate) onCandidate,
  ) async {
    print("WEBRTC: Setting up peer connection (isHost: $isHost)");

    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
        {"url": "stun:stun1.l.google.com:19302"},
      ],
    };

    peerConnection = await createPeerConnection(configuration);

    // Only add tracks if we have a local stream (host mode)
    if (localStream != null && isHost) {
      localStream!.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
        print("WEBRTC: Added track to peer connection");
      });
    }

    peerConnection?.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        print("WEBRTC: ICE candidate generated");
        onCandidate(candidate);
      }
    };

    peerConnection?.onTrack = (RTCTrackEvent event) {
      print("WEBRTC: Got remote track: ${event.streams.length} streams");
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        print("WEBRTC: Remote stream set to renderer");
      }
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      print("WEBRTC: Connection state changed to: $state");
    };
  }

  Future<RTCSessionDescription> createOffer() async {
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer(
    RTCSessionDescription offer,
  ) async {
    await peerConnection!.setRemoteDescription(offer);
    RTCSessionDescription answer = await peerConnection!.createAnswer();
    await peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await peerConnection!.setRemoteDescription(description);
  }

  Future<void> addCandidate(RTCIceCandidate candidate) async {
    await peerConnection?.addCandidate(candidate);
  }

  void dispose() {
    localStream?.dispose();
    peerConnection?.dispose();
    localRenderer.dispose();
    remoteRenderer.dispose();
  }
}
