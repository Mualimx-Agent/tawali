import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import '../../providers/restaurant_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  List<RestaurantModel> _restaurantResults = [];
  List<MenuItemModel> _menuResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () {
        setState(() {
          _query = value.trim();
          if (_query.isNotEmpty) {
            final provider = context.read<RestaurantProvider>();
            final lowerQuery = _query.toLowerCase();
            _restaurantResults = provider.searchRestaurants(lowerQuery);
            _menuResults = provider.searchMenuItems(lowerQuery);
          } else {
            _restaurantResults = [];
            _menuResults = [];
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 44,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: AppStrings.searchRestaurants,
              hintTextDirection: TextDirection.rtl,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 22),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: AppColors.textHint),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        _focusNode.requestFocus();
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _buildEmptyState()
          : _buildResults(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.border,
          ),
          const SizedBox(height: 20),
          Text(
            'ابحث عن مطعم أو وجبة',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اكتشف أفضل المطاعم والأطباق في الخرطوم',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_restaurantResults.isEmpty && _menuResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.border),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج لـ "$_query"',
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Restaurant results
        if (_restaurantResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.restaurant, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'المطاعم (${_restaurantResults.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ..._restaurantResults.map((r) => _SearchRestaurantItem(restaurant: r)),
        ],
        // Menu item results
        if (_menuResults.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book, size: 18, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  'الوجبات (${_menuResults.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ..._menuResults.map((m) => _SearchMenuItem(item: m)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SearchRestaurantItem extends StatelessWidget {
  final RestaurantModel restaurant;
  const _SearchRestaurantItem({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/restaurant_detail', arguments: restaurant),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.nameAr,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text('${restaurant.rating.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Text('${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax} ${AppStrings.mins}', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _SearchMenuItem extends StatelessWidget {
  final MenuItemModel item;
  const _SearchMenuItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fastfood, size: 24, color: AppColors.secondary.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameAr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  item.descriptionAr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Text(
            '${item.price.toStringAsFixed(0)} ${AppConstants.defaultCurrencySymbol}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}