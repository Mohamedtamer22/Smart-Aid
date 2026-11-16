import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A high-visibility, living pulsing emergency SOS button designed for
/// rapid recognition, accessibility, and positive tactical feedback.
class PulsingSosButton extends StatefulWidget {
  const PulsingSosButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.size = 190,
  });

  final VoidCallback onPressed;
  final String label;
  final double size;

  @override
  State<PulsingSosButton> createState() => _PulsingSosButtonState();
}

class _PulsingSosButtonState extends State<PulsingSosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _waveAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOut),
      ),
    );

    _waveAnimation = Tween<double>(begin: 0.96, end: 1.36).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.92, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final innerSize = widget.size * 0.88;

    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final waveValue = _waveAnimation.value;
          final waveOpacity = (1.0 - _controller.value).clamp(0.0, 0.36);

          return SizedBox(
            width: widget.size * 1.36,
            height: widget.size * 1.36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer expanding radar ring 1
                Transform.scale(
                  scale: waveValue,
                  child: Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.emergencyRed.withValues(
                          alpha: waveOpacity,
                        ),
                        width: 2.4,
                      ),
                      color: AppTheme.emergencyRed.withValues(
                        alpha: waveOpacity * 0.14,
                      ),
                    ),
                  ),
                ),
                // Mid expanding radar ring 2
                Transform.scale(
                  scale: 1.0 + (waveValue - 1.0) * 0.52,
                  child: Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.emergencyRed.withValues(alpha: 0.16),
                        width: 1.5,
                      ),
                      color: AppTheme.emergencyRed.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Soft static anchor halo
                Container(
                  width: innerSize + 18,
                  height: innerSize + 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.emergencyRed.withValues(alpha: 0.09),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 2.5,
                    ),
                  ),
                ),
                // Main Central Button with Pulse + Press Scaling
                AnimatedScale(
                  scale: _pressed ? 0.94 : _pulseAnimation.value,
                  duration: const Duration(milliseconds: 110),
                  child: Container(
                    width: innerSize,
                    height: innerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.22, -0.28),
                        radius: 0.95,
                        colors: [
                          Color(0xffFF5A52),
                          AppTheme.emergencyRed,
                          Color(0xff991B1B),
                        ],
                        stops: [0.0, 0.58, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emergencyRed.withValues(alpha: 0.42),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTapDown: (_) => setState(() => _pressed = true),
                        onTapCancel: () => setState(() => _pressed = false),
                        onTapUp: (_) => setState(() => _pressed = false),
                        onTap: widget.onPressed,
                        splashColor: Colors.white.withValues(alpha: 0.32),
                        highlightColor: Colors.black.withValues(alpha: 0.12),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.emergency_outlined,
                                    size: 38,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      widget.label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x66000000),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
