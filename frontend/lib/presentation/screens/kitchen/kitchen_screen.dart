import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/recipe_model.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../providers/api_provider.dart';

class KitchenScreen extends ConsumerStatefulWidget {
  const KitchenScreen({super.key});

  @override
  ConsumerState<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends ConsumerState<KitchenScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<InventoryItemModel> _inventory = [];
  List<Map<String, dynamic>> _useSoon = [];
  String _searchQuery = '';
  bool _isEditing = false;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final prefs = await SharedPreferences.getInstance();
      final kitchenProfile = _kitchenProfileFromPreferences(prefs);
      final results = await Future.wait([
        repo.getInventory(kitchenProfile: kitchenProfile),
        repo.getUseSoon(),
      ]);
      if (mounted) {
        setState(() {
          _inventory = results[0] as List<InventoryItemModel>;
          _useSoon = results[1] as List<Map<String, dynamic>>;
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

  String _kitchenProfileFromPreferences(SharedPreferences prefs) {
    final foodPreference = prefs.getString('food_preference') ?? 'vegetarian';
    final cuisines = prefs.getStringList('cuisine_preferences') ?? const ['north_indian'];
    if (foodPreference == 'non_vegetarian') return 'north_indian_non_veg';
    if (cuisines.any((c) => c == 'south_indian' || c == 'kerala' || c == 'tamil')) {
      return 'south_indian';
    }
    if (cuisines.length > 1 || cuisines.any((c) => c != 'north_indian' && c != 'punjabi')) {
      return 'mixed_indian';
    }
    return prefs.getString('kitchen_profile') ?? 'basic_north_indian_veg';
  }

  List<InventoryItemModel> get _filteredInventory {
    if (_searchQuery.isEmpty) return _inventory;
    return _inventory.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Map<String, List<InventoryItemModel>> get _groupedInventory {
    final grouped = <String, List<InventoryItemModel>>{};
    for (final item in _filteredInventory) {
      final cat = item.category.isEmpty ? 'Other' : item.category;
      grouped.putIfAbsent(cat, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('My Kitchen', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined),
                          onPressed: () => context.push('/shopping-list'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search ingredients...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showVoiceDialog,
                        icon: const Icon(Icons.mic, size: 28),
                        label: const Text('Tell us what\'s in your kitchen'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _ShimmerLoading(),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(theme),
              )
            else ...[
              if (_useSoon.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text('Use Soon', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                ...(_useSoon.map((item) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: _buildUseSoonItem(theme, item['ingredient_name'] ?? '', item['days_remaining']?.toString() ?? ''),
                  ),
                ))),
              ],
              if (_groupedInventory.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.kitchen, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Your kitchen looks empty', style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Add ingredients using the voice button above', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...(_groupedInventory.entries.map((entry) => _buildCategorySection(theme, entry.key, entry.value))),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
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
            Text('Could not load your kitchen inventory', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
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

  Widget _buildCategorySection(ThemeData theme, String title, List<InventoryItemModel> items) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isEditing = !_isEditing),
                  child: Text(
                    _isEditing ? 'Done' : 'Edit',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _isEditing ? Colors.green : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => _buildInventoryChip(item)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryChip(InventoryItemModel item) {
    final isLow = item.status == 'low';
    return Chip(
      label: Text(item.name, style: const TextStyle(fontSize: 13)),
      deleteIcon: Icon(
        _isEditing ? Icons.remove_circle : (isLow ? Icons.warning_amber_rounded : Icons.check_circle),
        size: 18,
        color: _isEditing ? Colors.red : (isLow ? Colors.orange : Colors.green),
      ),
      onDeleted: _isEditing ? () => _deleteItem(item.id) : null,
      backgroundColor: isLow ? Colors.orange.withOpacity(0.1) : null,
    );
  }

  Future<void> _deleteItem(String itemId) async {
    setState(() => _deletingId = itemId);
    try {
      await ref.read(inventoryRepositoryProvider).deleteItem(itemId);
      setState(() {
        _inventory.removeWhere((i) => i.id == itemId);
        _deletingId = null;
      });
    } catch (e) {
      setState(() => _deletingId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildUseSoonItem(ThemeData theme, String name, String days) {
    return Card(
      color: theme.colorScheme.errorContainer.withOpacity(0.3),
      child: ListTile(
        leading: const Icon(Icons.timer, color: Colors.orange),
        title: Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text('Use within $days days', style: theme.textTheme.bodySmall),
        trailing: TextButton(onPressed: () => context.go('/home'), child: const Text('Cook Now')),
      ),
    );
  }

  void _showVoiceDialog() {
    final repo = ref.read(inventoryRepositoryProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VoiceInputSheet(repository: repo),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 120, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          ...List.generate(5, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 60,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            ),
          )),
          const SizedBox(height: 24),
          Container(height: 20, width: 100, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(width: 80, height: 32, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 8),
                Container(width: 60, height: 32, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16))),
                const SizedBox(width: 8),
                Container(width: 90, height: 32, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _VoiceInputSheet extends StatefulWidget {
  final InventoryRepository repository;

  const _VoiceInputSheet({required this.repository});

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet> {
  bool _isListening = false;
  bool _isSubmitting = false;
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('Update Kitchen', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Tell us what's in your kitchen", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _isListening = !_isListening),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 40,
                color: _isListening ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_isListening ? 'Listening...' : 'Tap to speak', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Or type here...\ne.g. "Mere paas aloo pyaz tomato hai"',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          if (_isSubmitting)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _submitVoice, child: const Text('Update')),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _submitVoice() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.repository.voiceUpdate(text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitchen Updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
