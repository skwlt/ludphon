import 'package:flutter/material.dart';
import 'package:project/preserving_state.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('dad'),
          Container(
            width: 400,
            height: 200,
            color: Colors.orange,
          ),
          SizedBox(
            width: 200,
            height: 100,
          ),
          FloatingActionButton.large(backgroundColor: Colors.redAccent, onPressed: () {}, child: Icon(Icons.mic, size: 35, color: Colors.white))
        ],
      )),
    );
  }
}
