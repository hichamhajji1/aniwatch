import 'package:flutter/material.dart';

class AniMotion {
  AniMotion._();

  static const Duration fast = Duration(milliseconds: 220);
  static const Duration page = Duration(milliseconds: 340);
  static const Duration pageReverse = Duration(milliseconds: 280);

  static const Curve curve = Curves.easeOutCubic;

  static Widget pageWrap({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
  }) {
    final incoming = CurvedAnimation(parent: animation, curve: curve, reverseCurve: Curves.easeInCubic);
    final outgoing = CurvedAnimation(parent: secondaryAnimation, curve: curve);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.88).animate(outgoing),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.035, 0)).animate(outgoing),
        child: FadeTransition(
          opacity: incoming,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(incoming),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AniPageRoute<T> extends PageRouteBuilder<T> {
  AniPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: AniMotion.page,
          reverseTransitionDuration: AniMotion.pageReverse,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return AniMotion.pageWrap(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

class AniPageTransitionsBuilder extends PageTransitionsBuilder {
  const AniPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AniMotion.pageWrap(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AniMotion.fast,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late int _index = widget.index;
  double _slide = 0.03;

  @override
  void didUpdateWidget(covariant FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _slide = widget.index > oldWidget.index ? 0.03 : -0.03;
      _index = widget.index;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: AniMotion.curve);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.86, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(_slide, 0), end: Offset.zero).animate(curved),
        child: IndexedStack(index: _index, children: widget.children),
      ),
    );
  }
}
