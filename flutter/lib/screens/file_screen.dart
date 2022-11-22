import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/preserving_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends State<FileScreen> {
  final _auth = FirebaseAuth.instance;

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
            FileStream(),
          ],
        ),
      ),
    );
  }
}

class FileStream extends StatelessWidget {
  const FileStream({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('textFile')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        } else {
          final files = snapshot.data!.docs;
          List<FileBubble> fileBubbles = [];
          for (var file in files) {
            final fileName = file['fileName'];
            final fileSender = file['sender'];
            final currentUser = loggedInUser.email;
            final fileText = file['text'];
            final timestamp = file['timestamp'];
            DateTime date = timestamp.toDate();

            final fileBubble = FileBubble(
              fileName,
              fileSender,
              currentUser == fileSender,
              fileText,
              date,
            );
            fileBubbles.add(fileBubble);
          }

          return Expanded(
            child: ListView(
              // reverse: true,
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 20,
              ),
              children: fileBubbles,
            ),
          );
        }
      },
    );
  }
}

class FileBubble extends StatelessWidget {
  FileBubble(this.fileName, this.sender, this.isMe, this.text, this.timestamp);

  late final String fileName;
  late final String sender;
  late bool isMe;
  late final String text;
  late final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        // crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Material(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            elevation: 5,
            // color: isMe ? Colors.lightBlueAccent : Colors.white,
            color: Colors.grey,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              padding: const EdgeInsets.all(5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(fontSize: 30),
                        ),
                        Text(
                          timestamp.day.toString() + '/' + timestamp.month.toString() + '/' + timestamp.year.toString(),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                  ),
                  Expanded(
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
