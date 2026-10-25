import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/custom_item.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/models/purchase_transaction.dart';
import 'package:canele/models/rule_config.dart';
import 'package:canele/features/custom/models/custom_space_backup.dart';

void main() {
  group('CustomSpaceBackup Domain Serialization Tests', () {
    test('CustomSpaceBackup serializes and deserializes cleanly with dynamic schema', () {
      final schema = CustomWorkspaceSchema(
        itemLabel: 'Sneaker',
        unitLabel: 'Pair',
        groupLabel: 'Brand',
        customAttributes: [
          const CustomAttributeDefinition(
            id: 'colorway',
            name: 'Colorway',
            type: 'text',
          ),
          const CustomAttributeDefinition(
            id: 'size',
            name: 'US Size',
            type: 'number',
          ),
        ],
        statusOptions: ['wishlist', 'owned', 'sold'],
      );

      final profile = Profile(
        id: 'p_sneakers',
        name: 'Sneaker Vault',
        type: ProfileType.custom,
        icon: 'shoe',
        createdAt: DateTime(2026, 1, 1),
        customSchema: schema,
      );

      final item = CustomItem(
        id: 'shoe_1',
        title: 'Air Jordan 1 High OG',
        groupTitle: 'Nike / Jordan',
        status: 'owned',
        price: 180.0,
        currency: 'USD',
        edition: 'Chicago 2015',
        customFields: {
          'colorway': 'White/Black/Varsity Red',
          'size': 10.5,
        },
      );

      final tx = PurchaseTransaction(
        id: 'tx_shoe_1',
        volumeId: 'shoe_1',
        purchaseDate: DateTime(2026, 2, 1),
        quotaBucket: 'regular',
        price: 180.0,
        currency: 'USD',
      );

      final backup = CustomSpaceBackup(
        exportedAt: DateTime(2026, 3, 1),
        profile: profile,
        items: [item],
        ruleConfig: RuleConfig.createDefault(),
        transactions: [tx],
      );

      final jsonStr = backup.toJson(indent: true);
      expect(jsonStr, contains('Sneaker Vault'));
      expect(jsonStr, contains('Air Jordan 1 High OG'));
      expect(jsonStr, contains('colorway'));
      expect(jsonStr, contains('"spaceType": "custom"'));

      final restored = CustomSpaceBackup.fromJson(jsonStr);
      expect(restored.spaceType, 'custom');
      expect(restored.profile.name, 'Sneaker Vault');
      expect(restored.profile.customSchema?.itemLabel, 'Sneaker');
      expect(restored.profile.customSchema?.customAttributes.length, 2);

      expect(restored.items.length, 1);
      final restoredItem = restored.items.first;
      expect(restoredItem.title, 'Air Jordan 1 High OG');
      expect(restoredItem.customFields['colorway'], 'White/Black/Varsity Red');
      expect(restoredItem.customFields['size'], 10.5);

      expect(restored.transactions.length, 1);
      expect(restored.transactions.first.price, 180.0);
    });
  });
}
