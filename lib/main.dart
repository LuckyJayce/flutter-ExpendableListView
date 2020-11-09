import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'expend.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Test(),
    );
  }
}

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('test'),
      ),
      body: TextButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return Home();
          }));
        },
        child: Text('jump'),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('home')),
      body: ExpendableListView(
        sectionCount: () => 10,
        sectionChildrenCount: (sectionIndex) => 20,
        headerBuilder: (index, sectionIndex, expend) => Container(
          decoration: BoxDecoration(color: Colors.grey),
          child: ListTile(
            title: Text('section:$sectionIndex'),
          ),
        ),
        childBuilder: (sectionIndex, childIndex) => ListTile(
          title: Text('item $sectionIndex - $childIndex'),
        ),
      ),
    );
  }
}
