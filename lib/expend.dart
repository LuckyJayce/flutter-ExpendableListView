import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:load_data_test/render.dart';

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
  ScrollController scrollController = ScrollController();
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
        ListView.builder(
          controller: scrollController,
          itemBuilder: (BuildContext context, int index) {
            ItemInfo itemInfo = controllerImp.compute(index);
            if (itemInfo.isSectionHeader) {
              return _buildHeader(index, itemInfo.sectionIndex,
                  controllerImp.isSectionExpanded(itemInfo.sectionIndex));
            }
            return _buildChild(
                index, itemInfo.sectionIndex, itemInfo.itemIndex);
          },
          itemCount: controllerImp._listChildCount,
        ),
        StickHeader(scrollController, _buildHeader, controllerImp),
      ],
    );
  }

  void onExpend(int sectionIndex, bool expend) {
    setState(() {});
    //TODO
    // itemScrollController.jumpTo(
    //     index: controllerImp.getSectionHeaderIndex(sectionIndex));
  }

  Widget _buildHeader(int index, int sectionIndex, bool expend) {
    return RegisteredWidget(
      index: index,
      controllerImp: controllerImp,
      child: GestureDetector(
        onTap: () {
          print(
              '_buildHeaderWithClick GestureDetector onTap sectionIndex:$sectionIndex expend:$expend');
          controllerImp.setSectionExpanded(
              sectionIndex, !controllerImp.isSectionExpanded(sectionIndex));
        },
        child: widget.headerBuilder(sectionIndex, expend),
      ),
    );
  }

  Widget _buildChild(int index, int sectionIndex, int itemIndex) {
    return RegisteredWidget(
      index: index,
      controllerImp: controllerImp,
      child: widget.childBuilder(sectionIndex, itemIndex),
    );
  }
}

typedef _SectionHeaderBuilderImp = Widget Function(
    int index, int sectionIndex, bool expend);

typedef SectionCount = int Function();
typedef SectionChildrenCount = int Function(int sectionIndex);
typedef SectionHeaderBuilder = Widget Function(int sectionIndex, bool expend);
typedef SectionChildBuilder = Widget Function(
    int sectionIndex, int sectionChildIndex);

class ItemInfo {
  int index;
  bool isSectionHeader;
  int sectionIndex;
  int itemIndex;

  ItemInfo(this.index, this.isSectionHeader, this.sectionIndex, this.itemIndex);

  @override
  String toString() {
    return 'ItemInfo{isSectionHeader: $isSectionHeader, sectionIndex: $sectionIndex, itemIndex: $itemIndex}';
  }
}

class StickHeader extends StatefulWidget {
  final ScrollController scrollController;
  final _SectionHeaderBuilderImp builder;
  final _ExpandableListControllerImp _controllerImp;

  StickHeader(this.scrollController, this.builder, this._controllerImp);

  @override
  _StickHeaderState createState() => _StickHeaderState();
}

class HeaderClipper extends CustomClipper<Rect> {
  double headerDisplayHeight;

  HeaderClipper(this.headerDisplayHeight);

  @override
  Rect getClip(Size size) {
    print(
        'getClip headerDisplayHeight:$headerDisplayHeight h:${size.height - headerDisplayHeight} size.height:${size.height}');
    if (headerDisplayHeight > 0) {
      return Rect.fromLTRB(
          0, size.height - headerDisplayHeight, size.width, size.height);
    }
    return Rect.fromLTRB(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class _StickHeaderState extends State<StickHeader> {
  ItemInfo itemInfo;
  double headerDisplayHeight = -1;
  Widget header;
  int displaySectionIndex = -1;

  @override
  void initState() {
    widget.scrollController.addListener(onScroll);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('headerDisplayHeight:$headerDisplayHeight');
    if (itemInfo != null) {
      if (header == null || displaySectionIndex != itemInfo.sectionIndex) {
        header = widget.builder(itemInfo.index, itemInfo.sectionIndex,
            widget._controllerImp.isSectionExpanded(itemInfo.sectionIndex));
      }
      return DisplayHeightWidget(
        displayHeight: headerDisplayHeight,
        child: ClipRect(
          clipper: HeaderClipper(headerDisplayHeight),
          child: header,
        ),
      );
    }
    return Container();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(onScroll);
    super.dispose();
  }

  void onScroll() {
    print('onScroll');
    bool needUpdate = false;

    _RegisteredElement first;
    int firstIndex;
    double firstItemOffsetY;
    widget._controllerImp.elements.forEach((_RegisteredElement element) {
      int index = element.getIndex();

      RenderViewport viewport;
      final RenderBox box = element.renderObject;
      viewport ??= RenderAbstractViewport.of(box);
      if (viewport != null) {
        final reveal = viewport.getOffsetToReveal(box, 0).offset;
        final itemOffset = reveal -
            viewport.offset.pixels +
            viewport.anchor * viewport.size.height;

        double itemLeadingEdge = itemOffset.round() /
            widget.scrollController.position.viewportDimension;
        double itemTrailingEdge = (itemOffset + box.size.height).round() /
            widget.scrollController.position.viewportDimension;
        if (itemLeadingEdge < 1 && itemTrailingEdge > 0) {
          if (firstIndex == null || firstIndex > index) {
            firstIndex = index;
            first = element;
            firstItemOffsetY = itemOffset;
          }
        }
      }
    });

    if (first == null || first.getIndex() < 0) {
      return;
    }
    ItemInfo info = widget._controllerImp.compute(firstIndex);
    ItemInfo nextInfo = widget._controllerImp.compute(firstIndex + 1);
    print('index:$firstIndex');
    print('info:$info');
    print('nextInfo:$nextInfo');
    if (nextInfo.isSectionHeader) {
      final RenderBox box = first.renderObject;

      if (firstItemOffsetY <= 0) {
        headerDisplayHeight = box.size.height + firstItemOffsetY;
        needUpdate = true;
      }
    }
    if (itemInfo == null || (info.sectionIndex != itemInfo.sectionIndex)) {
      if (!nextInfo.isSectionHeader && headerDisplayHeight > 0) {
        headerDisplayHeight = -1;
      }
      needUpdate = true;
      itemInfo = info;
    }
    if (!nextInfo.isSectionHeader && headerDisplayHeight > 0) {
      headerDisplayHeight = -1;
      needUpdate = true;
      return;
    }
    setState(() {});
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

///控制类
class _ExpandableListControllerImp {
  int _listChildCount;
  SectionCount _sectionCount;
  SectionChildrenCount _sectionChildCount;
  List<int> _sectionHeaderIndexList = [];
  ExpendCallback _expendCallback;
  Map<int, bool> _expandedMap = {};
  Map<int, ItemInfo> itemInfoCache = {};
  Set<_RegisteredElement> elements = {};
  _RegisteredElement first;

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

  void register(_RegisteredElement element) {
    elements.add(element);
  }

  void unregister(Element element) {
    elements.remove(element);
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
      return ItemInfo(index, isSectionHeader, sectionIndex, null);
    }
    int itemIndex = index - _sectionHeaderIndexList[sectionIndex] - 1;
    return ItemInfo(index, isSectionHeader, sectionIndex, itemIndex);
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

///注册element
class RegisteredWidget extends StatelessWidget {
  final _ExpandableListControllerImp controllerImp;
  final Widget child;

  RegisteredWidget({int index, this.controllerImp, this.child})
      : super(key: ValueKey<int>(index));

  @override
  StatelessElement createElement() => _RegisteredElement(this);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _RegisteredElement extends StatelessElement {
  _RegisteredElement(RegisteredWidget widget) : super(widget);

  int getIndex() {
    RegisteredWidget registeredElementWidget = widget;
    if (registeredElementWidget != null) {
      ValueKey<int> index = registeredElementWidget.key;
      return index.value;
    }
    return -1;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    RegisteredWidget registeredElementWidget = widget;
    registeredElementWidget.controllerImp.register(this);
    print('mount index :${getIndex()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    RegisteredWidget registeredElementWidget = widget;
    registeredElementWidget.controllerImp.register(this);
  }

  @override
  void unmount() {
    print('unmount index :${getIndex()}');

    RegisteredWidget registeredElementWidget = widget;
    registeredElementWidget.controllerImp.unregister(this);
    super.unmount();
  }
}
