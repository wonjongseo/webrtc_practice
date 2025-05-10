import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketIoClient {
  SocketIoClient() {
    onInit();
  }
  late IO.Socket socket;

  void emit({
    required String event,
    required dynamic data,
    Function? callback,
  }) {
    socket.emitWithAck(event, data, ack: callback);
  }

  void on({required String event, required Function(dynamic) callback}) {
    socket.on(event, callback);
  }

  void onInit() {
    socket = IO.io('http://127.0.0.1:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connect');
    });

    socket.on('welcome', (_) {
      print('someOne Joined');
    });

    socket.on('new_message', (v) {
      print('new_message');
      print('v : ${v}');
    });

    // socket.on('enter_room', (data) {
    //   print('data');
    // });

    socket.onDisconnect((_) => print('disconnect'));
  }
}
