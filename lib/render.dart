import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class DisplayHeightWidget extends SingleChildRenderObjectWidget {
  /// Creates a widget that insets its child.
  ///
  /// The [displayHeight] argument must not be null.
  const DisplayHeightWidget({
    Key key,
    @required this.displayHeight, //displayHeight如果小于0 完整显示child，否则通过offset 只显示部分
    Widget child,
  })  : assert(displayHeight != null),
        super(key: key, child: child);

  /// The amount of space by which to inset the child.
  final double displayHeight;

  @override
  RenderOffset createRenderObject(BuildContext context) {
    return RenderOffset(
      headerDisplayHeight: displayHeight,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderOffset renderObject) {
    renderObject..headerDisplayHeight = displayHeight;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<double>('headerDisplayHeight', displayHeight));
  }
}

/// Insets its child by the given padding.
///
/// When passing layout constraints to its child, padding shrinks the
/// constraints by the given padding, causing the child to layout at a smaller
/// size. Padding then sizes itself to its child's size, inflated by the
/// padding, effectively creating empty space around the child.
class RenderOffset extends RenderShiftedBox {
  /// Creates a render object that insets its child.
  ///
  /// The [padding] argument must not be null and must have non-negative insets.
  RenderOffset({
    @required double headerDisplayHeight,
    RenderBox child,
  })  : assert(headerDisplayHeight != null),
        _headerDisplayHeight = headerDisplayHeight,
        super(child);

  /// The amount to pad the child in each dimension.
  ///
  /// If this is set to an [EdgeInsetsDirectional] object, then [textDirection]
  /// must not be null.
  double get headerDisplayHeight => _headerDisplayHeight;
  double _headerDisplayHeight;

  set headerDisplayHeight(double value) {
    assert(value != null);
    if (_headerDisplayHeight == value) return;
    _headerDisplayHeight = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    final BoxConstraints innerConstraints = constraints.loosen();
    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData as BoxParentData;
    double offset = _headerDisplayHeight - child.size.height;
    if (_headerDisplayHeight < 0 || offset > 0) {
      childParentData.offset = Offset(0, 0);
    } else {
      childParentData.offset = Offset(0, offset);
    }
    size = constraints.constrain(Size(
      child.size.width,
      child.size.height,
    ));
  }
}
