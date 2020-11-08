import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:load_data_test/refresh_page.dart';

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
        builder: MyBuilder(),
      ),
    );
  }
}

class MyBuilder extends ExpendableBuilder {
  @override
  Widget buildSectionHeader(int section, bool expend) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey),
      child: Text('header $section'),
    );
  }

  @override
  Widget buildSectionItem(int section, int itemIndex) {
    return ListTile(
      title: Text('item $section - $itemIndex'),
    );
  }

  @override
  int getSectionCount() {
    return 3;
  }

  @override
  int getSectionItemCount(int sectionIndex) {
    return 2;
  }
}
