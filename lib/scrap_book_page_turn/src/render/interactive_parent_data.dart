import 'package:flutter/rendering.dart';

/// Parent data storing the page index for each child page widget used by the
/// new RenderInteractiveBook render object.
class InteractiveParentData extends ContainerBoxParentData<RenderBox> {
  int pageIndex = 0;
  @override
  String toString() =>
      'InteractiveParentData(index=$pageIndex, offset=$offset)';
}
