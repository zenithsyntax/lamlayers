import 'package:flutter/widgets.dart';

import '../../interactive_book.dart';
import '../page/page_turn.dart';
import '../page/page_host.dart';
import '../render/render_interactive_book.dart';

class InteractiveBookRenderObjectWidget extends MultiChildRenderObjectWidget {
  final int pageCount;
  final PageWidgetBuilder builder;
  final FlipSettings settings;
  final PageTurn pageTurn;

  InteractiveBookRenderObjectWidget({
    super.key,
    required this.pageCount,
    required this.builder,
    required this.settings,
    required this.pageTurn,
  }) : super(
         children: List.generate(
           pageCount,
           (i) => PageHost(
             index: i,
             child: builder(WidgetsBinding.instance.rootElement!, i),
           ),
         ),
       );

  @override
  RenderInteractiveBook createRenderObject(BuildContext context) {
    final render = RenderInteractiveBook(settings, pageTurn);
    return render;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderInteractiveBook renderObject,
  ) {
    renderObject.updateSettings(settings);
  }
}
