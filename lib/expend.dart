import 'dart:core';

import 'package:flutter/widgets.dart';

class ExpendableListView extends StatefulWidget {
  final ExpendableBuilder builder;

  ExpendableListView({this.builder});

  @override
  _ExpendableListViewState createState() => _ExpendableListViewState();
}

class _ExpendableListViewState extends State<ExpendableListView> {
  Map<int, bool> expends = {};

  @override
  void initState() {
    super.initState();
    ccc();
  }

  @override
  void didUpdateWidget(covariant ExpendableListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    ccc();
  }

  void ccc() {}

  bool isSectionExpanded(int s) {
    return expends[s] == null || expends[s];
  }

  @override
  Widget build(BuildContext context) {
    int count = 0;
    List<int> sectionDataList = [];
    int sectionCount = widget.builder.getSectionCount();
    for (int s = 0; s < sectionCount; s++) {
      int itemCount = widget.builder.getSectionItemCount(s);
      sectionDataList.add(count);
      if (isSectionExpanded(s)) {
        count += itemCount + 1;
      } else {
        count += 1;
      }
    }
    // SliverList
    return ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          int sectionIndex = 0;
          bool isSectionHeader = false;
          for (int s = 0; s < sectionDataList.length; s++) {
            if (index == sectionDataList[s]) {
              isSectionHeader = true;
              sectionIndex = s;
              break;
            }
            if (index < sectionDataList[s]) {
              sectionIndex = s - 1;
              break;
            }
            if (s == sectionDataList.length - 1) {
              sectionIndex = s;
            }
          }
          if (isSectionHeader) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  expends[sectionIndex] = !isSectionExpanded(sectionIndex);
                });
              },
              child: widget.builder.buildSectionHeader(
                  sectionIndex, isSectionExpanded(sectionIndex)),
            );
          }
          int itemIndex = index - sectionDataList[sectionIndex] - 1;
          return widget.builder.buildSectionItem(sectionIndex, itemIndex);
        },
        itemCount: count);
  }
}

class SectionData {
  int startIndex;
  bool expend;

  SectionData(this.startIndex, this.expend);
}

abstract class ExpendableBuilder {
  int getSectionCount();

  Widget buildSectionHeader(int section, bool expend);

  int getSectionItemCount(int sectionIndex);

  Widget buildSectionItem(int section, int itemIndex);
}

typedef Expend = Function(int sectionIndex, bool expend);

class ExpandableListController {}
