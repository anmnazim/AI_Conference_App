import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ParallaxBackground extends StatefulWidget {
  final Widget child;
  
  const ParallaxBackground({
    super.key,
    required this.child,
  });

  @override
  State<ParallaxBackground> createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  final ValueNotifier<Offset> _mousePosNotifier = ValueNotifier(Offset.zero);

  @override
  void dispose() {
    _mousePosNotifier.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event) {
    // Determine the center of the screen
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    
    // Calculate offset from center
    // Normalized from -1.0 to 1.0
    final offset = Offset(
      (event.position.dx - center.dx) / center.dx,
      (event.position.dy - center.dy) / center.dy,
    );

    _mousePosNotifier.value = offset;
  }

  @override
  Widget build(BuildContext context) {
    // Disable on mobile/touch devices if needed, or just rely on mouse events which won't fire closely on touch.
    // However, kIsWeb check combined with platform checks can be good.
    // For now, MouseRegion works fine.
    
    // Theme Colors
    const primaryIndigo = Color(0xFF6200EA);
    const accentViolet = Color(0xFF7C4DFF);

    return MouseRegion(
      onHover: _onHover,
      child: Stack(
        children: [
          // ---------------- LAYER 0: Static Background ----------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A), // Deep Space Blue
                  Color(0xFF1E1B4B), // Indigo Dark
                  Color(0xFF2E1065), // Deep Violet
                ],
              ),
            ),
          ),

          // ---------------- LAYER 1: Deep Blobs (Slower) ----------------
          // Top Right Blob
          _ParallaxLayer(
            mousePosNotifier: _mousePosNotifier,
            movementFactor: 15.0, // Move max 15px opposite to cursor
            child: Positioned(
              top: -150,
              right: -50,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryIndigo.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: primaryIndigo.withOpacity(0.25),
                      blurRadius: 150,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Left Blob
          _ParallaxLayer(
            mousePosNotifier: _mousePosNotifier,
            movementFactor: 25.0, // Move max 25px
            child: Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentViolet.withOpacity(0.1),
                  boxShadow: [
                    BoxShadow(
                      color: accentViolet.withOpacity(0.15),
                      blurRadius: 120,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------------- LAYER 2: Main Content (Very subtle or static) ----------------
          // User requested "Cards (very subtle)" - we can apply a tiny movement to the content wrapper if desired,
          // but for now, let's keep the content static for readability as per "DO NOT affect text readability".
          // If we want to add depth, we can wrap the child in a layer with factor 5.0.
          
           _ParallaxLayer(
             mousePosNotifier: _mousePosNotifier,
             movementFactor: 5.0, // Very subtle foreground movement
             child: widget.child,
           ),
        ],
      ),
    );
  }
}

class _ParallaxLayer extends StatelessWidget {
  final ValueNotifier<Offset> mousePosNotifier;
  final double movementFactor;
  final Widget child;

  const _ParallaxLayer({
    required this.mousePosNotifier,
    required this.movementFactor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: mousePosNotifier,
      builder: (context, mouseOffset, _) {
        // Calculate translation
        // If mouse is at top-left (-1, -1), element moves to bottom-right (+factor, +factor)
        // to create depth (background moves opposite to camera/eye).
        final x = -mouseOffset.dx * movementFactor;
        final y = -mouseOffset.dy * movementFactor;

        return Transform.translate(
          offset: Offset(x, y),
          // Add a tiny bit of easing/smoothness via AnimatedContainer logic if we matched state,
          // but strictly, Transform is instant. "Movement must be eased" -> we might need AnimatedBuilder with a lerp
          // or just rely on high refresh rate. 
          // To strictly start easing, we'd need a Ticker. 
          // For a simple smooth effect, we can use AnimatedSlide or similar, but Transform is usually performant.
          // Let's add a small duration for 'smoothing' out jitters.
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(begin: Offset.zero, end: Offset(x, y)),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) {
              return Transform.translate(
                offset: offset,
                child: child,
              );
            },
            child: child,
          ),
        );
      },
    );
  }
}
