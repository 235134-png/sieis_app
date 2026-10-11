import 'dart:math';
import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue with Google',
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3C4043),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
              ),
            )
          else ...[
            const CustomGoogleLogo(size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3C4043),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomGoogleLogo extends StatelessWidget {
  const CustomGoogleLogo({super.key, this.size = 24.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = size.width / 2;
    final double strokeWidth = size.width * 0.22;

    final rect = Rect.fromCircle(
      center: Offset(center, center),
      radius: radius - (strokeWidth / 2),
    );

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red arc (top left to top right)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -45 * pi / 180, -135 * pi / 180, false, paint);

    // Yellow arc (bottom left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -180 * pi / 180, -45 * pi / 180, false, paint);

    // Green arc (bottom right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -225 * pi / 180, -90 * pi / 180, false, paint);

    // Blue arc (right side)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, 0 * pi / 180, 45 * pi / 180, false, paint);

    // Horizontal blue bar into the center
    final Paint fillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barHeight = strokeWidth;
    final barRect = Rect.fromLTWH(
      center - (strokeWidth * 0.1),
      center - (barHeight / 2),
      radius - (strokeWidth * 0.2),
      barHeight,
    );
    canvas.drawRect(barRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
