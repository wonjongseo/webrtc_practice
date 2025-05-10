import 'package:flutter/material.dart';

import 'package:webrtc_test/WebRTCPage.dart';
import 'package:webrtc_test/socket_io_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}

class Message {
  final String msg;
  final bool isMe;
  Message({required this.msg, required this.isMe});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController tECtl = TextEditingController();
  SocketIoClient socketIoClient = SocketIoClient();
  bool isEnterRoom = false;
  List<Message> messages = [];
  List<String> roomNames = [];
  String? nickName;
  String? roomName;

  @override
  void initState() {
    super.initState();
    socketIoClient.on(
      event: 'new_message',
      callback: (v) {
        addMessage(Message(msg: v, isMe: false));
      },
    );
    socketIoClient.on(
      event: 'room_change',
      callback: (room) {
        roomNames.add(room);
        setState(() {});
      },
    );
  }

  void addMessage(Message msg) {
    messages.add(msg);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Open Rooms'),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: roomNames.length,
                    itemBuilder: (context, index) {
                      return Text(roomNames[index]);
                    },
                  ),
                ],
              ),
              if (!isEnterRoom) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.pinkAccent,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: tECtl,
                            decoration: InputDecoration(
                              hintText:
                                  nickName == null
                                      ? 'Input NickName'
                                      : 'Input Room Name',
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (nickName == null) {
                            nickName = tECtl.text;
                            socketIoClient.emit(
                              event: 'nickname',
                              data: {'nickname': nickName},
                            );
                            tECtl.clear();
                            setState(() {});
                          } else {
                            socketIoClient.emit(
                              event: 'enter_room',
                              data: tECtl.text,
                              callback: () {
                                roomName = tECtl.text;
                                tECtl.clear();
                                isEnterRoom = true;
                                setState(() {});
                              },
                            );
                          }
                        },
                        child: Text(
                          nickName == null ? 'Create NickName' : 'Enter Room',
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room $roomName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 10),
                    ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return Align(
                          alignment:
                              messages[index].isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Text(messages[index].msg),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.pinkAccent,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: tECtl,
                              decoration: InputDecoration(
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              print('aa');
                              socketIoClient.emit(
                                event: 'new_message',
                                data: {'msg': tECtl.text, 'room': roomName},
                                callback: () {
                                  addMessage(
                                    Message(
                                      msg: 'You : ${tECtl.text}',
                                      isMe: true,
                                    ),
                                  );
                                  tECtl.clear();
                                  // roomName = tECtl.text;
                                  // tECtl.clear();
                                  // isEnterRoom = true;
                                  // setState(() {});
                                },
                              );
                            },
                            child: Text('Send Message'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
