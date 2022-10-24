import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;
var rng = Random();
int count = rng.nextInt(1000);

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  bool micOn = false;
  final record = Record();
  UploadTask? task;

  final _firestore = FirebaseFirestore.instance;

  bool isRecorderReady = false;

  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        // print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Listener(
              onPointerDown: (details) {
                setState(() {
                  micOn = true;
                  startRecording();
                });
              },
              onPointerUp: (details) {
                setState(() {
                  micOn = false;
                  stopRecording();
                });
              },
              child: Container(
                child: Icon(
                  Icons.mic,
                  size: 250,
                  color: micOn ? Colors.redAccent : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startRecording() async {
    if (await record.hasPermission()) {
      var directory = await getApplicationSupportDirectory();
      var directoryPath = '${directory.path}/${count}.mp4';

      final player = AudioPlayer();
      var duration = await player.setAsset('assets/startTalk.mp3');
      player.play();

      print(directoryPath);
      await record.start(
        path: directoryPath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
    }
  }

  void stopRecording() async {
    final player = AudioPlayer();
    var duration = await player.setAsset('assets/stop.mp3');
    player.play();

    await record.stop();

    var directory = await getApplicationSupportDirectory();
    var recordedPath = '${directory.path}/${count}.mp4';
    print(recordedPath);

    File file = File(recordedPath);

    var dio = Dio();
    var formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        recordedPath,
        filename: '${count}.mp4',
        contentType: MediaType('audio', 'mpeg'),
      ),
    });
    var url = 'http://127.0.0.1:3000/';
    var response = await dio.post(url, data: formData);
    // print(response.data);
    var mes;
    if (response.data['message'] == null) {
      mes = ' ';
    } else {
      mes = response.data['message'];
    }

    try {
      Reference reference = FirebaseStorage.instance.ref(recordedPath);

      final TaskSnapshot snapshot = await reference.putFile(
        file,
        SettableMetadata(
          contentType: "video/mp4",
        ),
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print(downloadUrl);

      _firestore.collection('messages').add({
        // 'message': response.data['message'],
        'message': mes,
        'url': downloadUrl,
        'sender': loggedInUser.email,
        'timestamp': Timestamp.now(),
      });
      print(count);
      count = rng.nextInt(1000);
    } on FirebaseException catch (e) {
      print(e);
    }
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        } else {
          final messages = snapshot.data!.docs;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messageUrl = message['url'];
            final messageSender = message['sender'];

            final currentUser = loggedInUser.email;
            final messageText = message['message'];

            final messageBubble = MessageBubble(
              messageSender,
              messageUrl,
              currentUser == messageSender,
              messageText,
            );
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 20,
              ),
              children: messageBubbles,
            ),
          );
        }
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(this.sender, this.url, this.isMe, this.message);

  late final String sender;
  String url;
  late bool isMe;
  final player = AudioPlayer();
  bool isPlay = false;
  String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: GestureDetector(
                onTap: playSound,
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black54,
                    fontSize: 23,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void playSound() async {
    print(url);
    final duration = await player.setUrl(url);
    player.play();
  }
}
