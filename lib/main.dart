import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'expend.dart';
import 'dart:math' as math;

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
  List<List<String>> data = [];
  ExpandableListController controller =
      ExpandableListController(expendAll: true);
  int times = 0;
  ItemBuilder dataBuilder = ItemBuilder();

  @override
  void initState() {
    super.initState();
    data = buildData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('home')),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                  onPressed: () {
                    controller.setSectionExpanded(0, true);
                  },
                  child: Text('展开0')),
              TextButton(
                  onPressed: () {
                    controller.setSectionExpanded(0, false);
                  },
                  child: Text('折叠0')),
              TextButton(
                  onPressed: () {
                    controller.setExpendAll(true);
                  },
                  child: Text('展开全部')),
              TextButton(
                  onPressed: () {
                    controller.setExpendAll(false);
                  },
                  child: Text('折叠全部')),
            ],
          ),
          Row(
            children: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      data = buildData();
                    });
                  },
                  child: Text('更新数据')),
              TextButton(
                  onPressed: () {
                    setState(() {
                      data.clear();
                    });
                  },
                  child: Text('更新为空数据')),
            ],
          ),
          Expanded(
            child: ExpendableListView.build(
              controller: controller,
              sticky: true,
              builder: ExpendableItemBuilder.build(
                sectionCount: () => data.length,
                sectionChildrenCount: (sectionIndex) =>
                    data[sectionIndex].length,
                headerBuilder:
                    (BuildContext context, int sectionIndex, bool expended) {
                  return Container(
                    decoration: BoxDecoration(color: Colors.grey),
                    child: ListTile(
                        title: Text('section:$sectionIndex'),
                        trailing: ExpandIcon(
                          // ValueKey(sectionIndex) 可以变为floatHeader导致重新执行动画
                          key: ValueKey(sectionIndex),
                          isExpanded: expended,
                          onPressed: null,
                        )),
                  );
                },
                childBuilder: (context, sectionIndex, childIndex) => ListTile(
                  title: Text(data[sectionIndex][childIndex]),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  List<List<String>> buildData() {
    times++;
    math.Random random = math.Random();
    int sectionCount = random.nextInt(10) + 3;
    int sectionChildCount = random.nextInt(30) + 10;
    print(
        'buildData sectionCount:$sectionCount  sectionChildCount:$sectionChildCount');
    return List.generate(sectionCount, (section) {
      return List.generate(sectionChildCount,
          (index) => 'times:$times section:$section index:$index');
    });
  }
}

//写法2
// class MyItemBuilder implements ExpendableItemBuilder {
//   List<List<String>> data = [];
//
//   @override
//   Widget buildSectionChild(
//       BuildContext context, int sectionIndex, int childIndex) {
//     return ListTile(
//       title: Text(data[sectionIndex][childIndex]),
//     );
//   }
//
//   @override
//   Widget buildSectionHeader(
//       BuildContext context, int sectionIndex, bool expended) {
//     return Container(
//       decoration: BoxDecoration(color: Colors.grey),
//       child: ListTile(
//           title: Text('section:$sectionIndex'),
//           trailing: ExpandIcon(
//             // ValueKey(sectionIndex) 可以变为floatHeader导致重新执行动画
//             key: ValueKey(sectionIndex),
//             isExpanded: expended,
//             onPressed: null,
//           )),
//     );
//   }
//
//   @override
//   int getSectionChildCount(int sectionIndex) {
//     return data[sectionIndex].length;
//   }
//
//   @override
//   int getSectionCount() {
//     return data.length;
//   }
// }
