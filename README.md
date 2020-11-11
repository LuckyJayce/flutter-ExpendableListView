### 说明

 通过计算section位置，section也当做listview item，避免ListView + Column(children实现方式)的性能问题
 借鉴于https://github.com/google/flutter.widgets/tree/master/packages/scrollable_positioned_list
  RegisterElement解决位置问题，获取ListView的第一个item和滚动偏移量

### TODO
1. 折叠的动画
2. Sliver
