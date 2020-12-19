import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Scaffold build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Search"),
      body: Text('Search'),
    );
  }
}

class UserResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text("User Result");
  }
}
