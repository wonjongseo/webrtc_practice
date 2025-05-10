import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCPage extends StatefulWidget {
  @override
  _WebRTCPageState createState() => _WebRTCPageState();
}

class _WebRTCPageState extends State<WebRTCPage> {
  late RTCVideoRenderer _localRenderer;
  late MediaStream _localStream;
  late IO.Socket _socket;
  late RTCPeerConnection _peerConnection;

  // ICE 후보를 저장할 리스트
  List<RTCIceCandidate> _remoteCandidates = [];
  bool _isRemoteDescriptionSet = false; // remoteDescription이 설정된 상태를 추적

  @override
  void initState() {
    super.initState();
    _localRenderer = RTCVideoRenderer();
    _localRenderer.initialize();

    _initializeWebRTC();
    _setupSocket();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _peerConnection.dispose();
    super.dispose();
  }

  Future<void> _initializeWebRTC() async {
    try {
      // 로컬 미디어 스트림 얻기 (카메라)
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': true,
        'mandatory': {
          'googNoiseSuppression': true,
          'googEchoCancellation': true,
          'googAutoGainControl': true,
          'minSampleRate': 16000,
          'maxSampleRate': 48000,
          'minBitrate': 32000,
          'maxBitrate': 128000,
        },
        'optional': [
          {'googHighpassFilter': true},
        ],
      });

      _localRenderer.srcObject = _localStream;
      _localStream.getTracks().forEach((track) {
        _peerConnection.addTrack(track, _localStream);
      });

      // PeerConnection 설정
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      });

      await _peerConnection.addStream(_localStream);

      // _peerConnection.onIceCandidate = (candidate) {
      //   _socket.emit('candidate', candidate.toMap());
      // };
    } catch (e) {
      print("Error initializing WebRTC: $e");
    }
  }

  // WebSocket 서버와 연결
  Future<void> _setupSocket() async {
    try {
      _socket = IO.io('http://localhost:3000', <String, dynamic>{
        'transports': ['websocket'],
      });

      _socket.on('connect', (_) {
        print('Connected to signaling server');
      });

      // offer을 받으면 응답
      _socket.on('offer', (offer) async {
        try {
          print("Received offer: $offer");

          // remoteDescription 설정
          await _peerConnection.setRemoteDescription(
            RTCSessionDescription(offer['sdp'], offer['type']),
          );

          // remoteDescription이 설정되면 저장된 후보를 처리
          _isRemoteDescriptionSet = true;
          for (var candidate in _remoteCandidates) {
            await _peerConnection.addCandidate(candidate);
          }
          _remoteCandidates.clear();

          var answer = await _peerConnection.createAnswer();
          _peerConnection.setLocalDescription(answer);
          _socket.emit('answer', {'type': answer.type, 'sdp': answer.sdp});
        } catch (e) {
          print("Error handling offer: $e");
        }
      });

      // ICE candidate를 받으면 처리
      _socket.on('candidate', (candidate) {
        try {
          var iceCandidate = RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          );

          // remoteDescription이 설정되었으면 후보를 추가
          if (_isRemoteDescriptionSet) {
            _peerConnection.addCandidate(iceCandidate);
          } else {
            // 아직 remoteDescription이 설정되지 않았으면 후보를 임시로 저장
            _remoteCandidates.add(iceCandidate);
          }
        } catch (e) {
          print("Error handling candidate: $e");
        }
      });
    } catch (e) {
      print("Error setting up socket: $e");
    }
  }

  // offer를 보내는 함수
  Future<void> _sendOffer() async {
    try {
      var offer = await _peerConnection.createOffer();
      _peerConnection.setLocalDescription(offer);
      _socket.emit('offer', {'type': offer.type, 'sdp': offer.sdp});
    } catch (e) {
      print("Error sending offer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebRTC iOS Stream')),
      body: Column(
        children: <Widget>[
          Expanded(child: RTCVideoView(_localRenderer)),
          ElevatedButton(
            onPressed: _sendOffer,
            child: Text('Send Offer to Browser'),
          ),
        ],
      ),
    );
  }
}
