import 'package:flutter/material.dart';
import 'package:project/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:record/record.dart';
// import 'package:audioplayer/audioplayer.dart';
import 'dart:math';
// import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

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
  // late String messageText;
  bool micOn = false;
  final record = Record();
  UploadTask? task;

  final _firestore = FirebaseFirestore.instance;

  // final recorder = FlutterSoundRecorder();
  bool isRecorderReady = false;

  // final _firestore = FirebaseFirestore.instance;

  final messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // initRecorder();

    getCurrentUser();
  }

  // @override
  // void dispose() {
  //   recorder.closeRecorder();
  //   super.dispose();
  // }

  // Future initRecorder() async {
  //   final status = await Permission.microphone.request();

  //   if (status != PermissionStatus.granted) throw 'Microphone permission not granted';

  //   await recorder.openRecorder();

  //   isRecorderReady = true;
  // }

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

  // void getMessages() async {
  //   final messages = await _firestore.collection('messages').get();
  //   for (var message in messages.docs) {
  //     print(message.data());
  //   }
  // }

  // void messagesStream() async {
  //   await for (var snapshot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshot.docs) {
  //       print(message.data());
  //     }
  //   }
  // }

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
                  size: 180,
                  color: micOn ? Colors.redAccent : Colors.black45,
                ),
              ),
            ),
            // FloatingActionButton.large(
            //   heroTag: null,
            //   backgroundColor: Colors.redAccent,
            //   onPressed: () async {
            //     if (recorder.isRecording) {
            //       await stopRecord();
            //     } else {
            //       await recordStart();
            //     }
            //   },
            //   child: Icon(
            //     // Icons.mic,
            //     recorder.isRecording ? Icons.stop : Icons.mic,
            //     size: 35,
            //     color: Colors.white,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Future recordStart() async {
  //   if (!isRecorderReady) return;
  //   await recorder.startRecorder(toFile: 'audio');
  // }

  // Future stopRecord() async {
  //   if (!isRecorderReady) return;
  //   final path = await recorder.stopRecorder();
  //   final audioFile = File(path!);
  //   print('Recorded audio: $audioFile');
  // }

  void startRecording() async {
    if (await record.hasPermission()) {
      var directory = await getApplicationSupportDirectory();
      var directoryPath = '${directory.path}/${count}.mp4';
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
    // var directoryPath = await _directoryPath();
    // var directoryPath = '${directory.path}wave.mp4';
    // var recordedPath = '${directoryPath}wave.mp4';

    await record.stop();
    var directory = await getApplicationSupportDirectory();
    // DateTime now = new DateTime.now();
    var recordedPath = '${directory.path}/${count}.mp4';
    print(recordedPath);
    // final storageRef = FirebaseStorage.instance.ref();
    // final mountainsRef = storageRef.child(recordedPath);

    File file = File(recordedPath);
    // final ref = FirebaseStorage.instance.ref(recordedPath);
    try {
      // final ref = FirebaseStorage.instance.ref();
      // final mountainsRef = ref.child(recordedPath);
      ////////////////////
      // final uploadTask = FirebaseStorage.instance.ref().child(recordedPath).putFile(file);

      // final snapshot = await uploadTask.whenComplete(() {});

      // final downloadURL = await snapshot.ref.getDownloadURL();
      // print(downloadURL);
      ///////////////////
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
        'url': downloadUrl,
        'sender': loggedInUser.email,
        'timestamp': Timestamp.now(),
      });
      print(count);
      count = rng.nextInt(1000);
    } on FirebaseException catch (e) {
      print(e);
    }

    // _firestore.collection('messages').add({
    //   'url': await mountainsRef.getDownloadURL(),
    //   'sender': loggedInUser.email,
    //   'timestamp': Timestamp.now(),
    // });
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots(),
      // stream: _firestore.collection('messages').snapshots(),
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
            // final messageText = message['text'];
            final messageUrl = message['url'];
            final messageSender = message['sender'];

            final currentUser = loggedInUser.email;

            final messageBubble = MessageBubble(
              messageSender,
              messageUrl,
              currentUser == messageSender,
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
  MessageBubble(this.sender, this.url, this.isMe);

  late final String sender;
  String url;
  late bool isMe;
  final player = AudioPlayer();
  bool isPlay = false;

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
              // child: Text(
              //   '$text',
              //   style: TextStyle(
              //     color: isMe ? Colors.white : Colors.black54,
              //     fontSize: 15,
              //   ),
              // ),
              child: GestureDetector(
                onTap: playSound,
                child: Text(
                  'Play Sound',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black54,
                    fontSize: 15,
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
    // var audioUrl = UrlSource(url);
    print(url);
    // // await player.play(audioUrl);
    // // // player.stop();
    final duration = await player.setUrl(url);
    // print(duration);
    player.play();
    // await player.play();
    // await player.stop();
    // AudioPlayer audioPlugin = AudioPlayer();
  }
}

// Future uploadVoice() async {
//   // final destination = 'files/long_audio.mp4';
//   Directory appDocDir = await getApplicationSupportDirectory();
//   // print(appDocDir.absolute);
//   String filePath = '${appDocDir.path}/long_audio.mp4';
//   // print(filePath);
//   File file = File(filePath);
//   final ref = FirebaseStorage.instance.ref(filePath);
//   try {
//     ref.putFile(file);
//   } catch (e) {
//     print(e);
//   }

//   // FirebaseApi.uploadFile(destination, file);
// }
