import 'package:flutter/material.dart';

// ── Default (seeded) categories ──────────────────────────────────────────

/// Immutable description of a default category seeded on first database
/// creation. [key] is the stable [Category.iconKey] stored in SQLite.
class SeedCategory {
  const SeedCategory({
    required this.key,
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  final String key;
  final String name;
  final IconData icon;
  final String colorHex;
}

/// Cameroon-relevant default categories, seeded exactly once per database.
const List<SeedCategory> seedCategories = [
  SeedCategory(
    key: 'food',
    name: 'Food and groceries',
    icon: Icons.restaurant_outlined,
    colorHex: '#16A34A',
  ),
  SeedCategory(
    key: 'transport',
    name: 'Transport',
    icon: Icons.directions_bus_outlined,
    colorHex: '#0EA5E9',
  ),
  SeedCategory(
    key: 'housing',
    name: 'Housing',
    icon: Icons.home_outlined,
    colorHex: '#7C3AED',
  ),
  SeedCategory(
    key: 'utilities',
    name: 'Utilities and bills',
    icon: Icons.receipt_long_outlined,
    colorHex: '#D97706',
  ),
  SeedCategory(
    key: 'health',
    name: 'Health',
    icon: Icons.health_and_safety_outlined,
    colorHex: '#DC2626',
  ),
  SeedCategory(
    key: 'education',
    name: 'Education',
    icon: Icons.school_outlined,
    colorHex: '#0369A1',
  ),
  SeedCategory(
    key: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
    colorHex: '#DB2777',
  ),
  SeedCategory(
    key: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie_outlined,
    colorHex: '#9333EA',
  ),
  SeedCategory(
    key: 'communication',
    name: 'Communication',
    icon: Icons.phone_iphone_outlined,
    colorHex: '#0891B2',
  ),
  SeedCategory(
    key: 'personal_care',
    name: 'Personal care',
    icon: Icons.spa_outlined,
    colorHex: '#EA580C',
  ),
  SeedCategory(
    key: 'family',
    name: 'Family',
    icon: Icons.family_restroom_outlined,
    colorHex: '#4D7C0F',
  ),
  SeedCategory(
    key: 'other',
    name: 'Other',
    icon: Icons.category_outlined,
    colorHex: '#64748B',
  ),
];

/// Fallback for custom categories created without an icon key.
const String fallbackCategoryIconKey = 'other';
