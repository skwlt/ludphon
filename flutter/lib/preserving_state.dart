import 'package:flutter/material.dart';
import 'package:flutter_azure_tts/flutter_azure_tts.dart';
import 'package:project/screens/chat_screen.dart';
import 'package:project/screens/start.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:project/screens/voice_screen.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

late User loggedInUser;

class PreservingBottomNavState extends StatefulWidget {
  const PreservingBottomNavState({Key? key}) : super(key: key);

  @override
  _PreservingBottomNavStateState createState() =>
      _PreservingBottomNavStateState();
}

class _PreservingBottomNavStateState extends State<PreservingBottomNavState> {
  int _selectedIndex = 1;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late final voice;

  @override
  void initState() {
    super.initState();

    getCurrentUser();
    textToSpeech();
  }

  static const List<Widget> _pages = <Widget>[
    Center(
      child: Icon(
        Icons.call,
        size: 150,
      ),
    ),
    ChatScreen(),
    // VoiceScreen(),
    // Center(
    //   child: Icon(
    //     Icons.call,
    //     size: 150,
    //   ),
    // ),
    Center(
      child: Icon(
        Icons.call,
        size: 150,
      ),
    ),
  ];

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      _auth.signOut();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StartScreen()),
      );
    }

    if (index == 2) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'mp4'],
      );
      print(result?.files.single.extension);

      String? extension = result?.files.single.extension;
      if (result != null && (extension == 'pdf' || extension == 'txt')) {
        late String textFromFile;
        if (extension == 'txt') {
          textFromFile = await readString(result.files.single.path!);
        } else if (extension == 'pdf') {
          PDFDoc doc = await PDFDoc.fromPath(result.files.single.path!);
          textFromFile = await doc.text;
        }

        TtsParams params = TtsParams(
            voice: voice,
            audioFormat: AudioOutputFormat.audio16khz32kBitrateMonoMp3,
            rate: 1.5, // optional prosody rate (default is 1.0)
            text: textFromFile);
        final ttsResponse = await AzureTts.getTts(params) as AudioSuccess;

        //Get the audio bytes.
        var directory = await getApplicationSupportDirectory();
        File filemp3 =
            await File('${directory.path}/${result.files.single.name}')
                .create();
        filemp3.writeAsBytesSync(ttsResponse.audio);

        String fileMp3Name = result.files.single.name.split('.')[0];
        Reference reference =
            FirebaseStorage.instance.ref('${fileMp3Name}.mp3');
        final TaskSnapshot snapshot = await reference.putFile(
          filemp3,
          SettableMetadata(
            contentType: "audio/mp3",
          ),
        );

        final downloadUrl = await snapshot.ref.getDownloadURL();

        _firestore.collection('messages').add({
          'message': 'from file ${result.files.single.name}',
          'url': downloadUrl,
          'sender': loggedInUser.email,
          'timestamp': Timestamp.now(),
        });
      } else if (result != null && extension == 'MP4') {
        var dio = Dio();
        var formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            result.files.single.path!,
            filename: '${result.files.single.name}.mp4',
            contentType: MediaType('audio', 'mpeg'),
          ),
        });
        var url = 'https://ludphon-python.herokuapp.com/';
        var response = await dio.post(url, data: formData);
        var mes;
        if (response.data['message'] == null) {
          mes = ' ';
        } else {
          mes = response.data['message'];
        }

        try {
          print('\n${result.files.single.path}');
          Reference reference =
              FirebaseStorage.instance.ref(result.files.single.path);
          var directory = await getApplicationSupportDirectory();
          File file = File(result.files.single.path!);

          final TaskSnapshot snapshot = await reference.putFile(
            file,
            SettableMetadata(
              contentType: "video/mp4",
            ),
          );

          final downloadUrl = await snapshot.ref.getDownloadURL();
          print(downloadUrl);

          _firestore.collection('messages').add({
            'message': mes,
            'url': downloadUrl,
            'sender': loggedInUser.email,
            'timestamp': Timestamp.now(),
          });
        } on FirebaseException catch (e) {
          print(e);
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const PreservingBottomNavState()),
      );
    }
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

  void textToSpeech() async {
    AzureTts.init(
      subscriptionKey: 'da59cd55f55842f1aecd97976b96915f',
      region: "southeastasia",
      withLogs: true,
    );

    final voicesResponse = await AzureTts.getAvailableVoices() as VoicesSuccess;

    voice = voicesResponse.voices
        .where((element) =>
            element.voiceType == 'Neural' && element.locale.startsWith('en-'))
        .toList(growable: false)[0];
  }

  Future<String> readString(String fileName) async {
    return await rootBundle.loadString(fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LUDPHON'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 20,
        selectedIconTheme: IconThemeData(color: Colors.red, size: 40),
        selectedItemColor: Colors.redAccent,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        unselectedIconTheme: IconThemeData(color: Colors.black26, size: 30),
        unselectedItemColor: Colors.black26,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'logout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'chat',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.mic),
          //   label: 'chat',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.import_export),
            label: 'import',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.dock),
          //   label: '',
          // ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
