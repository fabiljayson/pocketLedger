import 'package:flutter/material.dart';

import '../utils/money.dart';

// ── Amount display ───────────────────────────────────────────────────────

/// Renders an integer FCFA amount with thousands grouping and the FCFA
/// symbol. Wraps text never breaks between grouping groups.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amountFcfa, {
    super.key,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.showSymbol = true,
  });

  final int amountFcfa;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight fontWeight;
  final bool showSymbol;

  @override
  Widget build(BuildContext context) {
    final text = showSymbol
        ? formatFcfa(amountFcfa)
        : formatGrouped(amountFcfa);
    return Text(
      text,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
