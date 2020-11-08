import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sticky_headers/sticky_headers.dart';

class ExpendableListView extends StatefulWidget {
  final ExpendableBuilder builder;

  ExpendableListView({this.builder});

  @override
  _ExpendableListViewState createState() => _ExpendableListViewState();
}

class _ExpendableListViewState extends State<ExpendableListView> {
  ItemScrollController scrollController = ItemScrollController();
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  Accountant accountant;

  @override
  void initState() {
    super.initState();
    itemPositionsListener.itemPositions.addListener(() {});
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
        StickHeader(itemPositionsListener, widget.builder, accountant),
        ScrollablePositionedList.builder(
            // 只有设置了1.0 才能够准确的标记position 位置
            itemScrollController: scrollController,
            itemPositionsListener: itemPositionsListener,
            itemBuilder: (BuildContext context, int index) {
              ItemInfo itemInfo = accountant.compute(index);
              if (itemInfo.isSectionHeader) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      print('click');
                      accountant.expends[itemInfo.sectionIndex] =
                          !accountant.isSectionExpanded(itemInfo.sectionIndex);
                    });
                  },
                  child: widget.builder.buildSectionHeader(
                      itemInfo.sectionIndex,
                      accountant.isSectionExpanded(itemInfo.sectionIndex)),
                );
              }
              return widget.builder
                  .buildSectionItem(itemInfo.sectionIndex, itemInfo.itemIndex);
            },
            itemCount: accountant.count)
      ],
    );
  }
}

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
    ItemInfo info = map[index];
    if (info != null) {
      return info;
    }
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
}

class _SaltedValueKey extends ValueKey<Key> {
  const _SaltedValueKey(Key key)
      : assert(key != null),
        super(key);
}

class MyChildrenDelegate extends SliverChildBuilderDelegate {
  MyChildrenDelegate(
    Widget Function(BuildContext, int) builder, {
    int childCount,
    bool addAutomaticKeepAlive = true,
    bool addRepaintBoundaries = true,
  }) : super(builder,
            childCount: childCount,
            addAutomaticKeepAlives: addAutomaticKeepAlive,
            addRepaintBoundaries: addRepaintBoundaries);

  // Return a Widget for the given Exception
  Widget _createErrorWidget(dynamic exception, StackTrace stackTrace) {
    final FlutterErrorDetails details = FlutterErrorDetails(
      exception: exception,
      stack: stackTrace,
      library: 'widgets library',
      context: ErrorDescription('building'),
    );
    FlutterError.reportError(details);
    return ErrorWidget.builder(details);
  }

  @override
  Widget build(BuildContext context, int index) {
    assert(builder != null);
    if (index < 0 || (childCount != null && index >= childCount)) return null;
    Widget child;
    try {
      child = builder(context, index);
    } catch (exception, stackTrace) {
      child = _createErrorWidget(exception, stackTrace);
    }
    if (child == null) return null;
    final Key key = child.key != null ? _SaltedValueKey(child.key) : null;
    if (addRepaintBoundaries) child = RepaintBoundary(child: child);
    if (addSemanticIndexes) {
      final int semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null)
        child = IndexedSemantics(
            index: semanticIndex + semanticIndexOffset, child: child);
    }
    if (addAutomaticKeepAlives) child = AutomaticKeepAlive(child: child);
    return KeyedSubtree(child: child, key: key);
  }

  @override
  void didFinishLayout(int firstIndex, int lastIndex) {
    super.didFinishLayout(firstIndex, lastIndex);
  }

  ///监听 在可见的列表中 显示的第一个位置和最后一个位置
  @override
  double estimateMaxScrollOffset(int firstIndex, int lastIndex,
      double leadingScrollOffset, double trailingScrollOffset) {
    print(
        'firstIndex sss : $firstIndex, lastIndex ssss : $lastIndex, leadingScrollOffset ssss : $leadingScrollOffset,'
        'trailingScrollOffset ssss : $trailingScrollOffset  ');
    return super.estimateMaxScrollOffset(
        firstIndex, lastIndex, leadingScrollOffset, trailingScrollOffset);
  }
}

class StickHeader extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ExpendableBuilder builder;
  final Accountant accountant;

  StickHeader(this.itemPositionsListener, this.builder, this.accountant);

  @override
  _StickHeaderState createState() => _StickHeaderState();
}

class _StickHeaderState extends State<StickHeader> {
  @override
  void initState() {
    widget.itemPositionsListener.itemPositions.addListener(positionChange);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemPositionsListener.itemPositions.value.isEmpty) {
      return Container();
    }
    ItemPosition itemPosition =
        widget.itemPositionsListener.itemPositions.value.first;
    if (itemPosition != null) {
      int index = itemPosition.index;
      ItemInfo info = widget.accountant.compute(index);
      Widget w = widget.builder.buildSectionHeader(info.sectionIndex,
          widget.accountant.isSectionExpanded(info.sectionIndex));
      return w ?? Container();
    }
    return Container();
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(positionChange);
    super.dispose();
  }

  void positionChange() {
    setState(() {});
  }
}

abstract class ExpendableBuilder {
  int getSectionCount();

  Widget buildSectionHeader(int section, bool expend);

  int getSectionItemCount(int sectionIndex);

  Widget buildSectionItem(int section, int itemIndex);
}

typedef Expend = Function(int sectionIndex, bool expend);

class ExpandableListController {}
