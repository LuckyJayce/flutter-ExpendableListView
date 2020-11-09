import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'render.dart';
import 'src/item_positions_listener.dart';
import 'src/scrollable_positioned_list.dart';

class ExpendableListView extends StatefulWidget {
  final ExpendableBuilder builder;

  ExpendableListView({this.builder});

  @override
  _ExpendableListViewState createState() => _ExpendableListViewState();
}

class _ExpendableListViewState extends State<ExpendableListView> {
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  ItemScrollController itemScrollController = ItemScrollController();
  Accountant accountant;

  @override
  void initState() {
    super.initState();
    accountant = Accountant(widget.builder);
  }

  @override
  void didUpdateWidget(covariant ExpendableListView oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    accountant.update();
    // SliverList
    return Stack(
      children: [
        ScrollablePositionedList.builder(
          // 只有设置了1.0 才能够准确的标记position 位置
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          itemBuilder: (BuildContext context, int index) {
            ItemInfo itemInfo = accountant.compute(index);
            if (itemInfo.isSectionHeader) {
              return _buildHeader(index, itemInfo.sectionIndex,
                  accountant.isSectionExpanded(itemInfo.sectionIndex));
            }
            return widget.builder
                .buildSectionItem(itemInfo.sectionIndex, itemInfo.itemIndex);
          },
          itemCount: accountant.count,
        ),
        SizedBox.expand(
          child: StickHeader(itemPositionsListener, _buildHeader, accountant),
        ),
      ],
    );
  }

  Widget _buildHeader(int index, int sectionIndex, bool expend) {
    return GestureDetector(
      onTap: () {
        setState(() {
          accountant.expends[sectionIndex] =
              !accountant.isSectionExpanded(sectionIndex);
        });
        itemScrollController.jumpTo(index: index);
      },
      child: widget.builder.buildSectionHeader(sectionIndex, expend),
    );
  }
}

typedef StickHeaderBuilder = Widget Function(
    int index, int sectionIndexm, bool expend);

class Accountant {
  ExpendableBuilder builder;
  List<int> sectionDataList = [];

  Accountant(this.builder);

  Map<int, bool> expends = {};
  int count;
  Map<int, ItemInfo> map = {};

  void update() {
    count = 0;
    map.clear();
    sectionDataList.clear();
    int sectionCount = builder.getSectionCount();
    for (int s = 0; s < sectionCount; s++) {
      int itemCount = builder.getSectionItemCount(s);
      sectionDataList.add(count);
      if (isSectionExpanded(s)) {
        count += itemCount + 1;
      } else {
        count += 1;
      }
    }
  }

  ItemInfo compute(int index) {
    // ItemInfo info = map[index];
    // if (info != null) {
    //   return info;
    // }
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
      return ItemInfo(isSectionHeader, sectionIndex, null);
    }
    int itemIndex = index - sectionDataList[sectionIndex] - 1;
    return ItemInfo(isSectionHeader, sectionIndex, itemIndex);
  }

  bool isSectionExpanded(int s) {
    return expends[s] == null || expends[s];
  }
}

class ItemInfo {
  bool isSectionHeader;
  int sectionIndex;
  int itemIndex;

  ItemInfo(this.isSectionHeader, this.sectionIndex, this.itemIndex);

  @override
  String toString() {
    return 'ItemInfo{isSectionHeader: $isSectionHeader, sectionIndex: $sectionIndex, itemIndex: $itemIndex}';
  }
}

class StickHeader extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final StickHeaderBuilder builder;
  final Accountant accountant;

  StickHeader(this.itemPositionsListener, this.builder, this.accountant);

  @override
  _StickHeaderState createState() => _StickHeaderState();
}

class _StickHeaderState extends State<StickHeader> {
  ItemPosition itemPosition;
  ItemInfo itemInfo;
  double headerDisplayHeight = -1;

  @override
  void initState() {
    widget.itemPositionsListener.itemPositions.addListener(onPositionChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (itemInfo != null) {
      return DisplayWidget(
        headerDisplayHeight: headerDisplayHeight,
        child: widget.builder(itemPosition.index, itemInfo.sectionIndex,
            widget.accountant.isSectionExpanded(itemInfo.sectionIndex)),
      );
    }
    return Container();
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(onPositionChange);
    super.dispose();
  }

  void onPositionChange() {
    ItemPosition position = getFirstItemPosition();
    if (position != null) {
      ItemInfo info = widget.accountant.compute(position.index);
      ItemInfo nextInfo = widget.accountant.compute(position.index + 1);
      if (nextInfo.isSectionHeader) {
        if (position.offsetY <= 0) {
          itemInfo = info;
          itemPosition = position;
          headerDisplayHeight = position.height + position.offsetY;
          setState(() {});
          return;
        }
      }

      print('position $position');
      print('info $info');
      print('nextInfo $nextInfo');
      if (itemInfo == null || (info.sectionIndex != itemInfo.sectionIndex)) {
        itemInfo = info;
        itemPosition = position;
        if (!nextInfo.isSectionHeader && headerDisplayHeight > 0) {
          headerDisplayHeight = -1;
        }
        setState(() {});
        return;
      }
      if (!nextInfo.isSectionHeader && headerDisplayHeight > 0) {
        headerDisplayHeight = -1;
        setState(() {});
        return;
      }
    }
  }

  ItemPosition getFirstItemPosition() {
    if (widget.itemPositionsListener.itemPositions.value.isEmpty) {
      return null;
    }
    ItemPosition min = widget.itemPositionsListener.itemPositions.value
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((ItemPosition min, ItemPosition position) =>
            position.itemTrailingEdge < min.itemTrailingEdge ? position : min);
    return min;
  }
}

abstract class ExpendableBuilder {
  int getSectionCount();

  Widget buildSectionHeader(int section, bool expend);

  int getSectionItemCount(int sectionIndex);

  Widget buildSectionItem(int section, int itemIndex);
}

typedef Expend = Function(int sectionIndex, bool expend);

//TODO
class ExpandableListController {
  bool isSectionExpanded(int sectionIndex) {
    return false;
  }

  void setSectionExpanded(int sectionIndex, bool expanded) {
  }
}
