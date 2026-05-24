import 'package:flutter/material.dart';

class PixelButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const PixelButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFF5D4037),
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        padding: EdgeInsets.only(
          top: _isPressed ? 8 : 4,
          bottom: _isPressed ? 4 : 8,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: [
            if (!_isPressed)
              const BoxShadow(
                color: Colors.black,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          widget.text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
