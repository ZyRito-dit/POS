import 'package:flutter/material.dart';

/// Komponen garis putus-putus pembatas (dashed divider)
/// sesuai format tampilan struk dan ringkasan pembayaran di Figma.
class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DashedDivider({
    super.key,
    this.height = 1.0,
    this.color = const Color(0xFFD1D5DB),
    this.dashWidth = 5.0,
    this.dashSpace = 3.5,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        if (boxWidth <= 0 || boxWidth.isInfinite) {
          return Divider(color: color, height: height, thickness: height);
        }
        final count = (boxWidth / (dashWidth + dashSpace)).floor();
        return SizedBox(
          width: boxWidth,
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(count, (_) {
              return SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
