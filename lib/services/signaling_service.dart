import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef void OnCandidate(RTCIceCandidate candidate);
typedef void OnAnswer(RTCSessionDescription answer);
typedef void OnOffer(RTCSessionDescription offer);

class SignalingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? roomId;
  bool _answerProcessed = false;
  bool _offerProcessed = false;

  FirebaseFirestore get db => _db;

  Future<String> createRoom(RTCSessionDescription offer) async {
    print("SIGNALING: Creating room with offer...");
    DocumentReference roomRef = _db.collection('rooms').doc('livestream');

    roomId = roomRef.id;

    Map<String, dynamic> roomWithOffer = {
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    };

    await roomRef.set(roomWithOffer);
    print("SIGNALING: Room created successfully with ID: $roomId");
    return roomId!;
  }

  Future<void> joinRoom(
    String roomId,
    Function(RTCSessionDescription) onOfferFetched,
  ) async {
    DocumentReference roomRef = _db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      onOfferFetched(RTCSessionDescription(offer['sdp'], offer['type']));
    }
  }

  Future<void> answerRoom(RTCSessionDescription answer) async {
    print("SIGNALING: Sending answer to room...");
    DocumentReference roomRef = _db.collection('rooms').doc('livestream');
    await roomRef.update({
      'answer': {'type': answer.type, 'sdp': answer.sdp},
    });
    print("SIGNALING: Answer sent successfully");
  }

  void listenForAnswer(Function(RTCSessionDescription) onAnswer) {
    print("SIGNALING: Setting up listener for answer...");
    _answerProcessed = false;
    _db.collection('rooms').doc('livestream').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['answer'] != null && !_answerProcessed) {
          print("SIGNALING: Answer received from Firebase");
          var answer = data['answer'];
          _answerProcessed = true;
          onAnswer(RTCSessionDescription(answer['sdp'], answer['type']));
        }
      }
    });
  }

  void listenForOffer(Function(RTCSessionDescription) onOffer) {
    print("SIGNALING: Setting up listener for offer...");
    _offerProcessed = false;
    _db.collection('rooms').doc('livestream').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data['offer'] != null && !_offerProcessed) {
          print("SIGNALING: Offer received from Firebase");
          var offer = data['offer'];
          _offerProcessed = true;
          onOffer(RTCSessionDescription(offer['sdp'], offer['type']));
        }
      }
    });
  }

  Future<void> addCandidate(RTCIceCandidate candidate, bool isHost) async {
    var collection = isHost ? 'hostCandidates' : 'viewerCandidates';
    print(
      "SIGNALING: Adding ${isHost ? 'host' : 'viewer'} ICE candidate to collection: $collection",
    );
    await _db
        .collection('rooms')
        .doc('livestream')
        .collection(collection)
        .add(candidate.toMap());
    print("SIGNALING: ICE candidate added successfully");
  }

  void listenForCandidates(bool isHost, Function(RTCIceCandidate) onCandidate) {
    var collection = isHost ? 'viewerCandidates' : 'hostCandidates';
    print(
      "SIGNALING: Setting up listener for ICE candidates from collection: $collection",
    );
    _db
        .collection('rooms')
        .doc('livestream')
        .collection(collection)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              var data = change.doc.data() as Map<String, dynamic>;
              print("SIGNALING: New ICE candidate received from $collection");
              onCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              );
            }
          }
        });
  }

  Future<void> cleanRoom() async {
    print("SIGNALING: Cleaning room...");
    var roomRef = _db.collection('rooms').doc('livestream');

    // Delete candidates
    var hostCandidates = await roomRef.collection('hostCandidates').get();
    for (var doc in hostCandidates.docs) {
      await doc.reference.delete();
    }
    var viewerCandidates = await roomRef.collection('viewerCandidates').get();
    for (var doc in viewerCandidates.docs) {
      await doc.reference.delete();
    }

    await roomRef.delete();
    _answerProcessed = false;
    _offerProcessed = false;
    print("SIGNALING: Room cleaned successfully");
  }
}
