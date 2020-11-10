import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'render.dart';
import 'src/item_positions_listener.dart';
import 'src/scrollable_positioned_list.dart';

class ExpendableListView extends StatefulWidget {
  final SectionHeaderBuilder headerBuilder;
  final SectionCount sectionCount;
  final SectionChildBuilder childBuilder;
  final SectionChildrenCount sectionChildrenCount;
  final ExpandableListController controller;

  ExpendableListView(
      {@required this.sectionCount,
      @required this.headerBuilder,
      @required this.sectionChildrenCount,
      @required this.childBuilder,
      this.controller});

  @override
  _ExpendableListViewState createState() => _ExpendableListViewState();
}

class _ExpendableListViewState extends State<ExpendableListView> {
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  ItemScrollController itemScrollController = ItemScrollController();
  _ExpandableListControllerImp controllerImp;

  @override
  void initState() {
    super.initState();
    controllerImp = _ExpandableListControllerImp(
        widget.sectionCount, widget.sectionChildrenCount);
    controllerImp.setExpendCallback(onExpend);
    widget.controller?.setControllerImp(controllerImp);
  }

  @override
  void didUpdateWidget(covariant ExpendableListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.setControllerImp(null);
      widget.controller?.setControllerImp(controllerImp);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.setControllerImp(null);
    controllerImp.setExpendCallback(null);
  }

  @override
  Widget build(BuildContext context) {
    controllerImp.update();
    // SliverList
    return Stack(
      children: [
        ScrollablePositionedList.builder(
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          itemBuilder: (BuildContext context, int index) {
            ItemInfo itemInfo = controllerImp.compute(index);
            if (itemInfo.isSectionHeader) {
              return _buildHeaderWithClick(itemInfo.sectionIndex,
                  controllerImp.isSectionExpanded(itemInfo.sectionIndex));
            }
            return widget.childBuilder(
                itemInfo.sectionIndex, itemInfo.itemIndex);
          },
          itemCount: controllerImp._listChildCount,
        ),
        SizedBox.expand(
          child: StickHeader(
              itemPositionsListener, _buildHeaderWithClick, controllerImp),
        ),
      ],
    );
  }

  void onExpend(int sectionIndex, bool expend) {
    setState(() {});
    itemScrollController.jumpTo(
        index: controllerImp.getSectionHeaderIndex(sectionIndex));
  }

  Widget _buildHeaderWithClick(int sectionIndex, bool expend) {
    return GestureDetector(
      onTap: () {
        print(
            '_buildHeaderWithClick GestureDetector onTap sectionIndex:$sectionIndex expend:$expend');
        controllerImp.setSectionExpanded(
            sectionIndex, !controllerImp.isSectionExpanded(sectionIndex));
      },
      child: widget.headerBuilder(sectionIndex, expend),
    );
  }
}

typedef SectionCount = int Function();
typedef SectionChildrenCount = int Function(int sectionIndex);
typedef SectionHeaderBuilder = Widget Function(int sectionIndex, bool expend);
typedef SectionChildBuilder = Widget Function(
    int sectionIndex, int sectionChildIndex);

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
  final SectionHeaderBuilder builder;
  final _ExpandableListControllerImp _controllerImp;

  StickHeader(this.itemPositionsListener, this.builder, this._controllerImp);

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
      return DisplayHeightWidget(
        displayHeight: headerDisplayHeight,
        child: widget.builder(itemInfo.sectionIndex,
            widget._controllerImp.isSectionExpanded(itemInfo.sectionIndex)),
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
      ItemInfo info = widget._controllerImp.compute(position.index);
      ItemInfo nextInfo = widget._controllerImp.compute(position.index + 1);
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

typedef ExpendCallback = Function(int sectionIndex, bool expend);

class ExpandableListController {
  _ExpandableListControllerImp _controllerImp;

  bool isSectionExpanded(int sectionIndex) {
    return _controllerImp.isSectionExpanded(sectionIndex);
  }

  void setSectionExpanded(int sectionIndex, bool expanded) {
    _controllerImp.setSectionExpanded(sectionIndex, expanded);
  }

  void setControllerImp(_ExpandableListControllerImp controllerImp) {
    _controllerImp = controllerImp;
  }
}

class _ExpandableListControllerImp {
  int _listChildCount;
  SectionCount _sectionCount;
  SectionChildrenCount _sectionChildCount;
  List<int> _sectionHeaderIndexList = [];
  ExpendCallback _expendCallback;
  Map<int, bool> _expandedMap = {};
  Map<int, ItemInfo> itemInfoCache = {};

  _ExpandableListControllerImp(this._sectionCount, this._sectionChildCount);

  void setExpendCallback(ExpendCallback expendCallback) {
    this._expendCallback = expendCallback;
  }

  void update() {
    _listChildCount = 0;
    itemInfoCache.clear();
    _sectionHeaderIndexList.clear();
    int sc = _sectionCount();
    for (int s = 0; s < sc; s++) {
      int childCount = _sectionChildCount(s);
      _sectionHeaderIndexList.add(_listChildCount);
      if (isSectionExpanded(s)) {
        _listChildCount += childCount + 1;
      } else {
        _listChildCount += 1;
      }
    }
  }

  int getSectionHeaderIndex(int sectionIndex) {
    if (sectionIndex < _sectionHeaderIndexList.length) {
      return _sectionHeaderIndexList[sectionIndex];
    }
    return -1;
  }

  ItemInfo compute(int index) {
    ItemInfo info = itemInfoCache[index];
    if (info != null) {
      return info;
    }
    int sectionIndex = 0;
    bool isSectionHeader = false;
    for (int s = 0; s < _sectionHeaderIndexList.length; s++) {
      if (index == _sectionHeaderIndexList[s]) {
        isSectionHeader = true;
        sectionIndex = s;
        break;
      }
      if (index < _sectionHeaderIndexList[s]) {
        sectionIndex = s - 1;
        break;
      }
      if (s == _sectionHeaderIndexList.length - 1) {
        sectionIndex = s;
      }
    }
    if (isSectionHeader) {
      return ItemInfo(isSectionHeader, sectionIndex, null);
    }
    int itemIndex = index - _sectionHeaderIndexList[sectionIndex] - 1;
    return ItemInfo(isSectionHeader, sectionIndex, itemIndex);
  }

  bool isSectionExpanded(int sectionIndex) {
    return _expandedMap[sectionIndex] == null || _expandedMap[sectionIndex];
  }

  void setSectionExpanded(int sectionIndex, bool expanded) {
    _expandedMap[sectionIndex] = expanded;
    if (_expendCallback != null) {
      _expendCallback(sectionIndex, expanded);
    }
  }
}
