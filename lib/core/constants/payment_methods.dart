import 'package:flutter/material.dart';

// ── Payment methods ──────────────────────────────────────────────────────

/// Supported payment methods. [dbValue] is the stable string persisted in
/// SQLite; it must never change once shipped.
enum PaymentMethod {
  cash('cash', 'Cash', Icons.payments_outlined),
  bankCard('bank_card', 'Bank card', Icons.credit_card_outlined),
  bankTransfer(
    'bank_transfer',
    'Bank transfer',
    Icons.account_balance_outlined,
  ),
  mobileMoney('mobile_money', 'Mobile money', Icons.phone_android_outlined),
  other('other', 'Other', Icons.more_horiz);

  const PaymentMethod(this.dbValue, this.label, this.icon);

  final String dbValue;
  final String label;
  final IconData icon;

  static PaymentMethod fromDb(String? value) => PaymentMethod.values.firstWhere(
    (m) => m.dbValue == value,
    orElse: () => PaymentMethod.other,
  );
}
