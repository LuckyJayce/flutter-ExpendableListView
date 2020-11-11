import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'render.dart';

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
  _ControllerImp controllerImp;

  @override
  void initState() {
    super.initState();
    controllerImp =
        _ControllerImp(widget.sectionCount, widget.sectionChildrenCount);
    controllerImp.addExpendCallback(onExpend);
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
    controllerImp.removeExpendCallback(null);
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
            return _buildItem(itemInfo);
          },
          itemCount: controllerImp._listChildCount,
        ),
        StickHeader(scrollController, _buildHeader, controllerImp),
      ],
    );
  }

  void onExpend(int sectionIndex, bool expend) {
    setState(() {});
    double scrollOffsetY = controllerImp.headerScrollOffsetYList[sectionIndex];
    if (scrollOffsetY != null) {
      scrollController.jumpTo(scrollOffsetY);
    }
  }

  Widget _buildItem(ItemInfo itemInfo) {
    if (itemInfo.isSectionHeader) {
      return _buildHeader(itemInfo);
    }
    return _buildChild(itemInfo);
  }

  Widget _buildHeader(ItemInfo itemInfo) {
    return RegisteredWidget(
      itemInfo: itemInfo,
      controllerImp: controllerImp,
      child: GestureDetector(
        onTap: () {
          controllerImp.setSectionExpanded(itemInfo.sectionIndex,
              !controllerImp.isSectionExpanded(itemInfo.sectionIndex));
        },
        child: widget.headerBuilder(itemInfo.sectionIndex,
            controllerImp.isSectionExpanded(itemInfo.sectionIndex)),
      ),
    );
  }

  Widget _buildChild(ItemInfo itemInfo) {
    return RegisteredWidget(
      itemInfo: itemInfo,
      controllerImp: controllerImp,
      child: widget.childBuilder(itemInfo.sectionIndex, itemInfo.itemIndex),
    );
  }
}

typedef _SectionHeaderBuilderImp = Widget Function(ItemInfo itemInfo);

class ItemInfo {
  final int index;
  final bool isSectionHeader;
  final int sectionIndex;
  final int itemIndex;

  ItemInfo(this.index, this.isSectionHeader, this.sectionIndex, this.itemIndex);

  @override
  String toString() {
    return 'ItemInfo{isSectionHeader: $isSectionHeader, sectionIndex: $sectionIndex, itemIndex: $itemIndex}';
  }
}

class StickHeader extends StatefulWidget {
  final ScrollController scrollController;
  final _SectionHeaderBuilderImp builder;
  final _ControllerImp _controllerImp;

  StickHeader(this.scrollController, this.builder, this._controllerImp);

  @override
  _StickHeaderState createState() => _StickHeaderState();
}

class HeaderClipper extends CustomClipper<Rect> {
  double headerDisplayHeight;

  HeaderClipper(this.headerDisplayHeight);

  @override
  Rect getClip(Size size) {
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
    widget._controllerImp.addExpendCallback(onExpended);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (itemInfo != null) {
      if (header == null || displaySectionIndex != itemInfo.sectionIndex) {
        header = widget.builder(itemInfo);
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
    widget._controllerImp.removeExpendCallback(onExpended);
    super.dispose();
  }

  void onExpended(int sectionIndex, bool expended) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onScroll();
    });
  }

  void onScroll() {
    _RegisteredElement firstVisibleElement;
    ItemInfo firstVisibleItemInfo;
    double firstItemOffsetY;
    widget._controllerImp.elements.forEach((_RegisteredElement element) {
      ItemInfo itemInfo = element.getItemInfo();

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
          if (firstVisibleItemInfo == null ||
              firstVisibleItemInfo.index > itemInfo.index) {
            firstVisibleItemInfo = itemInfo;
            firstVisibleElement = element;
            firstItemOffsetY = itemOffset;
          }
          if (itemInfo.isSectionHeader) {
            double scrollY = widget.scrollController.position.pixels;
            double sectionHeaderScrollOffsetY = scrollY + firstItemOffsetY;
            widget._controllerImp.setSectionHeaderOffsetY(
                itemInfo.sectionIndex, sectionHeaderScrollOffsetY);
          }
        }
      }
    });

    if (firstVisibleElement == null || firstVisibleItemInfo == null) {
      return;
    }
    ItemInfo nextItemInfo =
        widget._controllerImp.compute(firstVisibleItemInfo.index + 1);

    if (nextItemInfo.isSectionHeader) {
      final RenderBox box = firstVisibleElement.renderObject;
      if (firstItemOffsetY <= 0) {
        headerDisplayHeight = box.size.height + firstItemOffsetY;
      }
    }
    if (itemInfo == null ||
        (firstVisibleItemInfo.sectionIndex != itemInfo.sectionIndex)) {
      if (!nextItemInfo.isSectionHeader && headerDisplayHeight > 0) {
        headerDisplayHeight = -1;
      }
      itemInfo = firstVisibleItemInfo;
    }
    if (!nextItemInfo.isSectionHeader && headerDisplayHeight > 0) {
      headerDisplayHeight = -1;
      return;
    }
    setState(() {});
  }
}

class ExpandableListController {
  _ControllerImp _controllerImp;

  bool isSectionExpanded(int sectionIndex) {
    return _controllerImp.isSectionExpanded(sectionIndex);
  }

  void setSectionExpanded(int sectionIndex, bool expanded) {
    _controllerImp.setSectionExpanded(sectionIndex, expanded);
  }

  void setControllerImp(_ControllerImp controllerImp) {
    _controllerImp = controllerImp;
  }
}

///控制类
class _ControllerImp {
  int _listChildCount;
  SectionCount _sectionCount;
  SectionChildrenCount _sectionChildCount;
  List<int> _sectionHeaderIndexList = [];
  Map<int, bool> _expandedMap = {};
  Map<int, ItemInfo> itemInfoCache = {};
  Set<_RegisteredElement> elements = {};
  _RegisteredElement first;
  List<ExpendCallback> expendCallbackList = [];
  Map<int, double> headerScrollOffsetYList = {};

  _ControllerImp(this._sectionCount, this._sectionChildCount);

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

  void setSectionHeaderOffsetY(int sectionIndex, double scrollOffsetY) {
    headerScrollOffsetYList[sectionIndex] = scrollOffsetY;
  }

  void addExpendCallback(ExpendCallback callback) {
    expendCallbackList.add(callback);
  }

  void removeExpendCallback(ExpendCallback callback) {
    expendCallbackList.remove(callback);
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
    expendCallbackList.forEach((callback) {
      callback(sectionIndex, expanded);
    });
  }
}

///注册element
class RegisteredWidget extends StatelessWidget {
  final ItemInfo itemInfo;
  final _ControllerImp controllerImp;
  final Widget child;

  RegisteredWidget({this.itemInfo, this.controllerImp, this.child}) : super();

  @override
  StatelessElement createElement() => _RegisteredElement(this);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _RegisteredElement extends StatelessElement {
  _RegisteredElement(RegisteredWidget widget) : super(widget);

  ItemInfo getItemInfo() {
    RegisteredWidget registeredElementWidget = widget;
    if (registeredElementWidget != null) {
      return registeredElementWidget.itemInfo;
    }
    return null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    RegisteredWidget registeredElementWidget = widget;
    registeredElementWidget.controllerImp.register(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    RegisteredWidget registeredElementWidget = widget;
    registeredElementWidget.controllerImp.register(this);
  }

  @override
  void unmount() {
    RegisteredWidget registeredElementWidget = widget;
    registeredElementWidget.controllerImp.unregister(this);
    super.unmount();
  }
}

///获取sectionCount
typedef SectionCount = int Function();

///获取section对应childCount
typedef SectionChildrenCount = int Function(int sectionIndex);

///构建 SectionHeader
typedef SectionHeaderBuilder = Widget Function(int sectionIndex, bool expended);

///构建section下的child
typedef SectionChildBuilder = Widget Function(
    int sectionIndex, int sectionChildIndex);

///折叠展开回调
typedef ExpendCallback = Function(int sectionIndex, bool expended);
