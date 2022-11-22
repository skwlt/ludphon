import 'package:flutter/material.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool micOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Listener(
              onPointerDown: (details) {
                setState(() {
                  micOn = true;
                });
              },
              onPointerUp: (details) {
                setState(() {
                  micOn = false;
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
}

