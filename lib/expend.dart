import 'dart:core';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'render.dart';

class ExpendableListView extends StatefulWidget {
  final ExpendableItemBuilder builder;
  final ExpandableListController controller;
  final bool sticky;

  //ListView params
//  固定垂直方向
  final Axis scrollDirection = Axis.vertical;
  final bool reverse;
  final bool primary;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;
  final IndexedWidgetBuilder separatorBuilder;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double cacheExtent;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String restorationId;
  final Clip clipBehavior;

  ExpendableListView.build(
      {Key key,
      @required this.builder,
      this.controller,
      this.sticky = true,
      //ListView params ------
      // this.scrollDirection,
      this.reverse = false,
      this.primary,
      this.physics,
      this.shrinkWrap = false,
      this.padding,
      this.separatorBuilder,
      this.addAutomaticKeepAlives = true,
      this.addRepaintBoundaries = true,
      this.addSemanticIndexes = true,
      this.cacheExtent,
      this.dragStartBehavior = DragStartBehavior.start,
      this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
      this.restorationId,
      this.clipBehavior = Clip.hardEdge})
      : super(key: key);

  @override
  _ExpendableListViewState createState() => _ExpendableListViewState();
}

class _ExpendableListViewState extends State<ExpendableListView> {
  ScrollController scrollController = ScrollController();
  _ControllerImp controllerImp;

  @override
  void initState() {
    super.initState();
    controllerImp = _ControllerImp(widget.builder);
    widget.controller?.setControllerImp(controllerImp);
    controllerImp.addExpendSectionCallback(onExpend);
    controllerImp.addExpendAllCallback(onExpendAll);
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
    controllerImp.dispose();
    widget.controller._dispose();
  }

  @override
  Widget build(BuildContext context) {
    controllerImp.update();
    // SliverList
    return Stack(
      children: [
        if (widget.separatorBuilder == null)
          ListView.builder(
            reverse: widget.reverse,
            primary: widget.primary,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            padding: widget.padding,
            addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
            addRepaintBoundaries: widget.addRepaintBoundaries,
            addSemanticIndexes: widget.addSemanticIndexes,
            cacheExtent: widget.cacheExtent,
            dragStartBehavior: widget.dragStartBehavior,
            keyboardDismissBehavior: widget.keyboardDismissBehavior,
            restorationId: widget.restorationId,
            clipBehavior: widget.clipBehavior,
            controller: scrollController,
            itemBuilder: (BuildContext context, int index) {
              ItemInfo itemInfo = controllerImp.compute(index);
              return _buildItem(context, itemInfo);
            },
            itemCount: controllerImp._listChildCount,
          ),
        if (widget.separatorBuilder != null)
          ListView.separated(
            reverse: widget.reverse,
            primary: widget.primary,
            physics: widget.physics,
            shrinkWrap: widget.shrinkWrap,
            padding: widget.padding,
            separatorBuilder: widget.separatorBuilder,
            addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
            addRepaintBoundaries: widget.addRepaintBoundaries,
            addSemanticIndexes: widget.addSemanticIndexes,
            cacheExtent: widget.cacheExtent,
            dragStartBehavior: widget.dragStartBehavior,
            keyboardDismissBehavior: widget.keyboardDismissBehavior,
            restorationId: widget.restorationId,
            clipBehavior: widget.clipBehavior,
            controller: scrollController,
            itemBuilder: (BuildContext context, int index) {
              ItemInfo itemInfo = controllerImp.compute(index);
              return _buildItem(context, itemInfo);
            },
            itemCount: controllerImp._listChildCount,
          ),
        if (widget.sticky)
          _StickHeader(scrollController, _buildHeader, controllerImp),
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

  void onExpendAll(bool expendAll) {
    setState(() {});
    scrollController.jumpTo(0);
  }

  Widget _buildItem(BuildContext context, ItemInfo itemInfo) {
    if (itemInfo.isSectionHeader) {
      return _buildHeader(context, itemInfo);
    }
    return _buildChild(context, itemInfo);
  }

  Widget _buildHeader(BuildContext context, ItemInfo itemInfo) {
    return RegisteredWidget(
      itemInfo: itemInfo,
      controllerImp: controllerImp,
      child: GestureDetector(
        onTap: () {
          controllerImp.setSectionExpanded(itemInfo.sectionIndex,
              !controllerImp.isSectionExpanded(itemInfo.sectionIndex));
        },
        child: widget.builder.buildSectionHeader(context, itemInfo.sectionIndex,
            controllerImp.isSectionExpanded(itemInfo.sectionIndex)),
      ),
    );
  }

  Widget _buildChild(BuildContext context, ItemInfo itemInfo) {
    return RegisteredWidget(
      itemInfo: itemInfo,
      controllerImp: controllerImp,
      child: widget.builder.buildSectionChild(
          context, itemInfo.sectionIndex, itemInfo.itemIndex),
    );
  }
}

typedef _SectionHeaderBuilderImp = Widget Function(
    BuildContext context, ItemInfo itemInfo);

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

/// _StickHeader 浮在顶部的header，滚动变化内部会自动更新sectionHeader
class _StickHeader extends StatefulWidget {
  final ScrollController scrollController;
  final _SectionHeaderBuilderImp builder;
  final _ControllerImp _controllerImp;

  _StickHeader(this.scrollController, this.builder, this._controllerImp);

  @override
  _StickHeaderState createState() => _StickHeaderState();
}

class _StickHeaderState extends State<_StickHeader> {
  ItemInfo itemInfo;
  double headerDisplayHeight = -1;
  Widget header;
  int displaySectionIndex = -1;

  @override
  void initState() {
    widget.scrollController.addListener(onScroll);
    widget._controllerImp.addExpendSectionCallback(onExpended);
    widget._controllerImp.addExpendAllCallback(onExpendAll);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (itemInfo == null &&
        widget._controllerImp.builder.getSectionCount() > 0) {
      check();
    }
    if (itemInfo != null &&
        widget._controllerImp.builder.getSectionCount() > 0) {
      if (header == null || displaySectionIndex != itemInfo.sectionIndex) {
        header = widget.builder(context, itemInfo);
      }
      return DisplayHeightWidget(
        displayHeight: headerDisplayHeight,
        child: ClipRect(
          clipper: _HeaderClipper(headerDisplayHeight),
          child: header,
        ),
      );
    }
    return Container();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(onScroll);
    widget._controllerImp.removeExpendSectionCallback(onExpended);
    widget._controllerImp.removeExpendAllCallback(onExpendAll);
    super.dispose();
  }

  void onExpended(int sectionIndex, bool expended) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onScroll();
    });
  }

  void onExpendAll(bool expendAll) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onScroll();
    });
  }

  void onScroll() {
    check();
    setState(() {});
  }

  void check() {
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
          //记录section的位置 方便折叠时候滚动定位
          if (itemInfo.isSectionHeader) {
            double scrollY = widget.scrollController.position.pixels;
            double sectionHeaderScrollOffsetY = scrollY + firstItemOffsetY;
            widget._controllerImp.setSectionHeaderOffsetY(
                itemInfo.sectionIndex, sectionHeaderScrollOffsetY);
          }
        }
      }
    });

    if (firstVisibleElement != null && firstVisibleItemInfo != null) {
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
    }
  }
}

///裁切浮动header溢出的部分
class _HeaderClipper extends CustomClipper<Rect> {
  double headerDisplayHeight;

  _HeaderClipper(this.headerDisplayHeight);

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

///给外部调用的控制类
class ExpandableListController {
  bool expendAll;
  _ControllerImp _controllerImp;
  List<ExpendSectionCallback> _expendCallbackList = [];
  List<ExpendAllCallback> _expendAllCallbackList = [];

  ExpandableListController({this.expendAll = true});

  bool isSectionExpanded(int sectionIndex) {
    return _controllerImp?.isSectionExpanded(sectionIndex);
  }

  void setSectionExpanded(int sectionIndex, bool expanded) {
    _controllerImp?.setSectionExpanded(sectionIndex, expanded);
    _controllerImp.expendSectionCallbackList.addAll(_expendCallbackList);
    _expendCallbackList.clear();
  }

  void setControllerImp(_ControllerImp controllerImp) {
    _controllerImp = controllerImp;
    if (expendAll != null) {
      if (_controllerImp._expendAll != expendAll) {
        _controllerImp.setExpendAll(expendAll);
      }
      expendAll = null;
    }
  }

  void addExpendSectionCallback(ExpendSectionCallback callback) {
    if (_controllerImp != null) {
      _controllerImp.addExpendSectionCallback(callback);
    } else {
      _expendCallbackList.add(callback);
    }
  }

  void removeExpendSectionCallback(ExpendSectionCallback callback) {
    _expendCallbackList.remove(callback);
    _controllerImp?.removeExpendSectionCallback(callback);
  }

  void addExpendAllCallback(ExpendAllCallback callback) {
    if (_controllerImp != null) {
      _controllerImp.addExpendAllCallback(callback);
    } else {
      _expendAllCallbackList.add(callback);
    }
  }

  void removeExpendAllCallback(ExpendAllCallback callback) {
    _expendAllCallbackList.remove(callback);
    _controllerImp?.removeExpendAllCallback(callback);
  }

  void setExpendAll(bool expendAll) {
    _controllerImp?.setExpendAll(expendAll);
  }

  void _dispose() {
    _expendCallbackList.clear();
  }
}

///控制类
class _ControllerImp {
  int _listChildCount;
  List<int> _sectionHeaderIndexList = [];
  Map<int, bool> _expandedMap = {};
  Map<int, ItemInfo> itemInfoCache = {};
  Set<_RegisteredElement> elements = {};
  _RegisteredElement first;
  List<ExpendSectionCallback> expendSectionCallbackList = [];
  List<ExpendAllCallback> expendAllCallbackList = [];
  Map<int, double> headerScrollOffsetYList = {};
  bool _expendAll = true;
  ExpendableItemBuilder builder;

  _ControllerImp(this.builder);

  void update() {
    _listChildCount = 0;
    itemInfoCache.clear();
    _sectionHeaderIndexList.clear();
    int sc = builder.getSectionCount();
    for (int s = 0; s < sc; s++) {
      int childCount = builder.getSectionChildCount(s);
      _sectionHeaderIndexList.add(_listChildCount);
      if (isSectionExpanded(s)) {
        _listChildCount += childCount + 1;
      } else {
        _listChildCount += 1;
      }
    }
  }

  void setExpendAll(bool expendAll) {
    _expendAll = expendAll;
    _expandedMap.clear();
    for (var callback in expendAllCallbackList) {
      callback(expendAll);
    }
  }

  void setSectionHeaderOffsetY(int sectionIndex, double scrollOffsetY) {
    headerScrollOffsetYList[sectionIndex] = scrollOffsetY;
  }

  void addExpendSectionCallback(ExpendSectionCallback callback) {
    expendSectionCallbackList.add(callback);
  }

  void removeExpendSectionCallback(ExpendSectionCallback callback) {
    expendSectionCallbackList.remove(callback);
  }

  void addExpendAllCallback(ExpendAllCallback callback) {
    expendAllCallbackList.add(callback);
  }

  void removeExpendAllCallback(ExpendAllCallback callback) {
    expendAllCallbackList.remove(callback);
  }

  void dispose() {
    expendSectionCallbackList.clear();
    expendAllCallbackList.clear();
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
    if (_expendAll) {
      //_expendAll 为true， null则就是展开
      return _expandedMap[sectionIndex] == null || _expandedMap[sectionIndex];
    } else {
      //_expendAll 为false， null则就是折叠
      return _expandedMap[sectionIndex] != null && _expandedMap[sectionIndex];
    }
  }

  void setSectionExpanded(int sectionIndex, bool expanded) {
    _expandedMap[sectionIndex] = expanded;
    expendSectionCallbackList.forEach((callback) {
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
typedef ChildrenCount = int Function(int section);

///构建 SectionHeader
typedef SectionHeaderBuilder = Widget Function(
    BuildContext context, int section, bool expended);

///构建section下的child
typedef SectionChildBuilder = Widget Function(
    BuildContext context, int section, int childIndex);

///折叠展开回调
typedef ExpendSectionCallback = Function(int section, bool expended);
typedef ExpendAllCallback = Function(bool expendAll);

///数据加载成功显示的WidgetBuilder
abstract class ExpendableItemBuilder {
  int getSectionCount();

  int getSectionChildCount(int sectionIndex);

  Widget buildSectionHeader(
      BuildContext context, int sectionIndex, bool expended);

  Widget buildSectionChild(
      BuildContext context, int sectionIndex, int childIndex);

  static ExpendableItemBuilder build(
      {@required SectionCount sectionCount,
      @required ChildrenCount sectionChildrenCount,
      @required SectionHeaderBuilder headerBuilder,
      @required SectionChildBuilder childBuilder}) {
    return _ExpendableListDataBuilderImp(
        sectionCount: sectionCount,
        childrenCount: sectionChildrenCount,
        headerBuilder: headerBuilder,
        childBuilder: childBuilder);
  }
}

class _ExpendableListDataBuilderImp extends ExpendableItemBuilder {
  SectionCount sectionCount;
  ChildrenCount childrenCount;
  SectionHeaderBuilder headerBuilder;
  SectionChildBuilder childBuilder;

  _ExpendableListDataBuilderImp(
      {this.sectionCount,
      this.childrenCount,
      this.headerBuilder,
      this.childBuilder});

  @override
  Widget buildSectionChild(
      BuildContext context, int sectionIndex, int childIndex) {
    return childBuilder(context, sectionIndex, childIndex);
  }

  @override
  Widget buildSectionHeader(
      BuildContext context, int sectionIndex, bool expended) {
    return headerBuilder(context, sectionIndex, expended);
  }

  @override
  int getSectionChildCount(int sectionIndex) {
    return childrenCount(sectionIndex);
  }

  @override
  int getSectionCount() {
    return sectionCount();
  }
}
