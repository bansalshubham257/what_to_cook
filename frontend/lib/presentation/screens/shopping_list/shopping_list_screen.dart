import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/shopping_repository.dart';
import '../../providers/api_provider.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  bool _isLoading = true;
  String? _error;
  List<ShoppingItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(shoppingRepositoryProvider);
      final items = await repo.getShoppingList();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleItem(String itemId) async {
    try {
      final repo = ref.read(shoppingRepositoryProvider);
      await repo.toggleItem(itemId);
      setState(() {
        _items = _items.map((item) {
          if (item.id == itemId) {
            return item.copyWith(status: item.isBought ? 'pending' : 'bought');
          }
          return item;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeItem(String itemId) async {
    try {
      final repo = ref.read(shoppingRepositoryProvider);
      await repo.removeItem(itemId);
      setState(() => _items.removeWhere((item) => item.id == itemId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final isSaving = ValueNotifier<bool>(false);

    await showDialog<bool>(
      context: context,
      builder: (ctx) => ValueListenableBuilder<bool>(
        valueListenable: isSaving,
        builder: (ctx, saving, _) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name', hintText: 'e.g. Potato'),
                enabled: !saving,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity', hintText: 'e.g. 1'),
                      keyboardType: TextInputType.number,
                      enabled: !saving,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(labelText: 'Unit', hintText: 'e.g. kg'),
                      enabled: !saving,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      isSaving.value = true;
                      try {
                        final repo = ref.read(shoppingRepositoryProvider);
                        await repo.addItem(name, quantity: quantityController.text.trim(), unit: unitController.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          isSaving.value = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding item: ${e.toString()}'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: _buildBody(theme),
      floatingActionButton: _isLoading || _error != null
          ? null
          : FloatingActionButton(
              onPressed: _showAddDialog,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Something went wrong', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Could not load your shopping list', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Your shopping list is empty', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Add items using the + button below', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final pending = _items.where((item) => !item.isBought).toList();
    final bought = _items.where((item) => item.isBought).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        if (pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('To Buy', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          ),
          ...pending.map((item) => _ShoppingItemTile(
            item: item,
            onToggle: () => _toggleItem(item.id),
            onDelete: () => _removeItem(item.id),
          )),
        ],
        if (bought.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Bought', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          ...bought.map((item) => _ShoppingItemTile(
            item: item,
            onToggle: () => _toggleItem(item.id),
            onDelete: () => _removeItem(item.id),
          )),
        ],
      ],
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItemModel item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ShoppingItemTile({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity != null && item.unit != null
        ? '${item.quantity} ${item.unit}'
        : item.quantity ?? item.unit ?? '';
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: CheckboxListTile(
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isBought ? TextDecoration.lineThrough : null,
            color: item.isBought ? Colors.grey : null,
          ),
        ),
        subtitle: qty.isNotEmpty ? Text(qty) : null,
        value: item.isBought,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
