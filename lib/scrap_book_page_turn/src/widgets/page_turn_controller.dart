import '../enums/flip_corner.dart';
import '../event/event_object.dart';
import '../page/page_turn.dart';

class PageTurnController {
  late PageTurn _pageTurn;

  initializeController({required PageTurn pageTurn}) {
    _pageTurn = pageTurn;
  }

  /// Internal setter for the PageTurn instance
  set pageTurn(PageTurn pageTurn) => _pageTurn = pageTurn;

  /// Get the current page index (0-based)
  int get currentPageIndex => _pageTurn.getCurrentPageIndex();

  /// Get the total number of pages
  int get pageCount => _pageTurn.getPageCount();

  /// Check if there is a next page available
  bool get hasNextPage =>
      currentPageIndex + (_pageTurn.getSettings.usePortrait ? 0 : 1) <
      (pageCount - 1);

  /// Check if there is a previous page available
  bool get hasPreviousPage => currentPageIndex > 0;

  /// Flip to the next page
  ///
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the last page
  bool nextPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasNextPage) return false;
    _pageTurn.flipNext(corner);

    return true;
  }

  /// Flip to the previous page
  /// [corner] - The corner to flip from (default: top)
  /// Returns true if the flip was successful, false if already at the first page
  bool previousPage([FlipCorner corner = FlipCorner.top]) {
    if (!hasPreviousPage) return false;
    _pageTurn.flipPrev(corner);

    return true;
  }

  /// Go to a specific page
  /// [pageIndex] - The page index to navigate to (0-based)
  /// Returns true if the navigation was successful, false if the page index is invalid
  bool goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageCount) return false;
    _pageTurn.flip(pageIndex, FlipCorner.top);

    return true;
  }

  /// Go to the first page
  bool goToFirstPage() => goToPage(0);

  /// Go to the last page
  bool goToLastPage() => goToPage(pageCount - 1);

  /// Register an event listener
  /// [event] - The event name ('flip', 'changeOrientation', etc.)
  /// [callback] - The callback function to execute
  void addEventListener(String event, EventCallback callback) {
    _pageTurn.on(event, callback);
  }

  /// Remove an event listener
  /// [event] - The event name
  void removeEventListener(String event) {
    _pageTurn.off(event);
  }

  /// Get the underlying PageTurn instance for advanced operations
  /// Use this only when you need direct access to PageTurn methods
  /// not exposed through this controller
  PageTurn? get pageTurnInstance => _pageTurn;
}
