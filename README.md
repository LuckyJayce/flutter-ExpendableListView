### 说明

 通过计算section位置，section也当做listview item，避免ListView + Column(children实现方式)的性能问题
 用了https://github.com/google/flutter.widgets/tree/master/packages/scrollable_positioned_list
 但是数据不够所以修改了源码 ，ItemPosition 添加 ItemPosition 添加了 this.offsetY和this.height两个字段

###TODO
1. 顶部吸顶的stickyHeader有时溢出
2. 折叠站看动画
