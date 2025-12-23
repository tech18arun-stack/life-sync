import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';
import '../utils/app_theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Recent'; // Recent, Name, Price

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          title: const Text('Shopping List'),
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.fileExport),
              onPressed: () => _showExportOptions(context),
              tooltip: 'Export',
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.broom),
              onPressed: () => _clearPurchased(context),
              tooltip: 'Clear Purchased',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: FaIcon(FontAwesomeIcons.cartShopping, size: 20),
                text: 'To Buy',
              ),
              Tab(
                icon: FaIcon(FontAwesomeIcons.circleCheck, size: 20),
                text: 'Purchased',
              ),
              Tab(
                icon: FaIcon(FontAwesomeIcons.chartColumn, size: 20),
                text: 'Categories',
              ),
            ],
          ),
        ),
        body: Consumer<ShoppingListProvider>(
          builder: (context, provider, child) {
            final activeItems = provider.activeItems;
            final purchasedItems = provider.purchasedItems;
            final allItems = [...activeItems, ...purchasedItems];

            // Apply filters
            final filteredItems = allItems.where((item) {
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  item.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  (item.notes?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false);
              final matchesCategory =
                  _selectedCategory == 'All' ||
                  item.category == _selectedCategory;
              return matchesSearch && matchesCategory;
            }).toList();

            // Sort items
            _sortItems(filteredItems);

            final filteredActive = filteredItems
                .where((item) => !item.isPurchased)
                .toList();
            final filteredPurchased = filteredItems
                .where((item) => item.isPurchased)
                .toList();

            return Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildCategoryFilter(allItems)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSortSelector()),
                        ],
                      ),
                    ],
                  ),
                ),

                // Summary Card
                _buildEnhancedSummaryCard(context, provider),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    children: [
                      // To Buy Tab
                      filteredActive.isEmpty
                          ? _buildEmptyState(
                              context,
                              'No items to buy',
                              'All items purchased or list is empty',
                            )
                          : _buildItemsList(context, filteredActive, provider),
                      // Purchased Tab
                      filteredPurchased.isEmpty
                          ? _buildEmptyState(
                              context,
                              'No purchased items',
                              'Items you purchase will appear here',
                            )
                          : _buildItemsList(
                              context,
                              filteredPurchased,
                              provider,
                            ),
                      // Categories Tab
                      _buildCategoriesView(context, allItems, provider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_shopping_item_fab',
          onPressed: () => _showAddItemDialog(context),
          icon: const FaIcon(FontAwesomeIcons.plus),
          label: const Text('Add Item'),
        ),
      ),
    );
  }

  void _sortItems(List<ShoppingItem> items) {
    switch (_sortBy) {
      case 'Name':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Price':
        items.sort((a, b) {
          final aPrice = a.estimatedPrice ?? 0;
          final bPrice = b.estimatedPrice ?? 0;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'Recent':
      default:
        items.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
    }
  }

  Widget _buildCategoryFilter(List<ShoppingItem> items) {
    final categories = {'All', ...items.map((item) => item.category)}.toList();

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: categories
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCategory = value);
      },
    );
  }

  Widget _buildSortSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _sortBy,
      decoration: InputDecoration(
        labelText: 'Sort By',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['Recent', 'Name', 'Price'].map((sort) {
        return DropdownMenuItem(value: sort, child: Text(sort));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _sortBy = value);
      },
    );
  }

  Widget _buildEnhancedSummaryCard(
    BuildContext context,
    ShoppingListProvider provider,
  ) {
    final estimatedCost = provider.getTotalEstimatedCost();
    final itemCount = provider.activeItems.length;
    final purchasedCount = provider.purchasedItems.length;
    final totalItems = itemCount + purchasedCount;
    final completionRate = totalItems > 0
        ? (purchasedCount / totalItems * 100)
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                context,
                FontAwesomeIcons.listUl,
                '$itemCount',
                'To Buy',
                Colors.white,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatColumn(
                context,
                FontAwesomeIcons.circleCheck,
                '$purchasedCount',
                'Done',
                Colors.white,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatColumn(
                context,
                FontAwesomeIcons.indianRupeeSign,
                '₹${estimatedCost.toStringAsFixed(0)}',
                'Estimated',
                Colors.white,
              ),
            ],
          ),
          if (totalItems > 0) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Shopping Progress',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${completionRate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionRate / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildItemsList(
    BuildContext context,
    List<ShoppingItem> items,
    ShoppingListProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildEnhancedItemCard(context, items[index], provider);
      },
    );
  }

  Widget _buildCategoriesView(
    BuildContext context,
    List<ShoppingItem> items,
    ShoppingListProvider provider,
  ) {
    final categoryStats = <String, Map<String, dynamic>>{};

    for (final item in items) {
      if (!categoryStats.containsKey(item.category)) {
        categoryStats[item.category] = {
          'count': 0,
          'total': 0.0,
          'purchased': 0,
        };
      }
      categoryStats[item.category]!['count'] += 1;
      categoryStats[item.category]!['total'] += item.estimatedPrice ?? 0;
      if (item.isPurchased) {
        categoryStats[item.category]!['purchased'] += 1;
      }
    }

    final sortedCategories = categoryStats.entries.toList()
      ..sort(
        (a, b) =>
            (b.value['total'] as double).compareTo(a.value['total'] as double),
      );

    if (sortedCategories.isEmpty) {
      return _buildEmptyState(
        context,
        'No categories',
        'Add items to see category breakdown',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final category = entry.key;
        final stats = entry.value;
        final count = stats['count'] as int;
        final total = stats['total'] as double;
        final purchased = stats['purchased'] as int;
        final completion = count > 0 ? (purchased / count * 100) : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count items • $purchased purchased',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      Text(
                        '${completion.toStringAsFixed(0)}% done',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(AppTheme.successColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedItemCard(
    BuildContext context,
    ShoppingItem item,
    ShoppingListProvider provider,
  ) {
    final isPurchased = item.isPurchased;
    final color = isPurchased
        ? Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey
        : AppTheme.primaryColor;

    return Dismissible(
      key: Key(item.id ?? ''),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Item?'),
            content: Text('Remove "${item.name}" from the list?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteItem(item.id ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.addItem(item),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPurchased
                ? Theme.of(context).dividerColor.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: () => provider.togglePurchased(item.id ?? ''),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPurchased ? AppTheme.successColor : color,
                      width: 2,
                    ),
                    color: isPurchased
                        ? AppTheme.successColor
                        : Colors.transparent,
                  ),
                  child: isPurchased
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isPurchased
                            ? TextDecoration.lineThrough
                            : null,
                        color: isPurchased
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.quantity > 1) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FaIcon(
                          _getCategoryIcon(item.category),
                          size: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.notes != null) ...[
                          const Text(' • '),
                          Expanded(
                            child: Text(
                              item.notes!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added ${DateFormat('MMM d, h:mm a').format(item.createdDate)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Price and actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (item.estimatedPrice != null)
                    Text(
                      '₹${item.estimatedPrice!.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPurchased
                            ? Theme.of(context).textTheme.bodySmall?.color
                            : AppTheme.primaryColor,
                      ),
                    ),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditItemDialog(context, item);
                      } else if (value == 'delete') {
                        provider.deleteItem(item.id ?? '');
                      } else if (value == 'price') {
                        _showSetPriceDialog(context, item);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'price',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.tag, size: 16),
                            SizedBox(width: 12),
                            Text('Set Price'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            FaIcon(FontAwesomeIcons.trash, size: 16),
                            SizedBox(width: 12),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return FontAwesomeIcons.basketShopping;
      case 'household':
        return FontAwesomeIcons.house;
      case 'personal':
        return FontAwesomeIcons.user;
      default:
        return FontAwesomeIcons.tag;
    }
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.cartShopping,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Export Shopping List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.fileCsv),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.share),
              title: const Text('Share List'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    String selectedCategory = 'groceries';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Est. Price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'groceries',
                      child: Text('Groceries'),
                    ),
                    DropdownMenuItem(
                      value: 'household',
                      child: Text('Household'),
                    ),
                    DropdownMenuItem(
                      value: 'personal',
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final item = ShoppingItem(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    quantity: int.tryParse(quantityController.text) ?? 1,
                    category: selectedCategory,
                    estimatedPrice: priceController.text.isEmpty
                        ? null
                        : double.tryParse(priceController.text),
                    createdDate: DateTime.now(),
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                  );
                  Provider.of<ShoppingListProvider>(
                    context,
                    listen: false,
                  ).addItem(item);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} added to list'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ShoppingItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final priceController = TextEditingController(
      text: item.estimatedPrice?.toString() ?? '',
    );
    final notesController = TextEditingController(text: item.notes ?? '');
    String selectedCategory = item.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Est. Price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'groceries',
                      child: Text('Groceries'),
                    ),
                    DropdownMenuItem(
                      value: 'household',
                      child: Text('Household'),
                    ),
                    DropdownMenuItem(
                      value: 'personal',
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final updatedItem = ShoppingItem(
                    id: item.id,
                    name: nameController.text,
                    quantity: int.tryParse(quantityController.text) ?? 1,
                    category: selectedCategory,
                    estimatedPrice: priceController.text.isEmpty
                        ? null
                        : double.tryParse(priceController.text),
                    createdDate: item.createdDate,
                    isPurchased: item.isPurchased,
                    purchasedDate: item.purchasedDate,
                    actualPrice: item.actualPrice,
                    notes: notesController.text.isEmpty
                        ? null
                        : notesController.text,
                    addedBy: item.addedBy,
                  );
                  Provider.of<ShoppingListProvider>(
                    context,
                    listen: false,
                  ).updateItem(updatedItem);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Item updated successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPriceDialog(BuildContext context, ShoppingItem item) {
    final priceController = TextEditingController(
      text:
          item.actualPrice?.toString() ?? item.estimatedPrice?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Set Actual Price'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Actual Price',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isNotEmpty) {
                final updatedItem = ShoppingItem(
                  id: item.id,
                  name: item.name,
                  quantity: item.quantity,
                  category: item.category,
                  estimatedPrice: item.estimatedPrice,
                  createdDate: item.createdDate,
                  isPurchased: item.isPurchased,
                  purchasedDate: item.purchasedDate,
                  actualPrice: double.tryParse(priceController.text),
                  notes: item.notes,
                  addedBy: item.addedBy,
                );
                Provider.of<ShoppingListProvider>(
                  context,
                  listen: false,
                ).updateItem(updatedItem);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Price updated successfully'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearPurchased(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Clear Purchased Items'),
        content: const Text('Remove all purchased items from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ShoppingListProvider>(
                context,
                listen: false,
              ).clearPurchased();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchased items cleared'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
