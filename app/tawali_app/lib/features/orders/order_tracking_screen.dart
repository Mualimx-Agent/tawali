import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../providers/order_provider.dart';
import 'package:provider/provider.dart';

/// Order status timeline steps
const List<_OrderStep> _orderSteps = [
  _OrderStep(status: 'pending', label: 'قيد الانتظار', icon: Icons.receipt_long),
  _OrderStep(status: 'confirmed', label: 'تم التأكيد', icon: Icons.check_circle_outline),
  _OrderStep(status: 'preparing', label: 'جاري التحضير', icon: Icons.restaurant),
  _OrderStep(status: 'delivering', label: 'في الطريق', icon: Icons.delivery_dining),
  _OrderStep(status: 'completed', label: 'تم التوصيل', icon: Icons.check_circle),
];

class _OrderStep {
  final String status;
  final String label;
  final IconData icon;
  const _OrderStep({required this.status, required this.label, required this.icon});
}

/// Get status index for progress
int _statusIndex(String status) {
  const statuses = ['pending', 'confirmed', 'preparing', 'delivering', 'completed'];
  final idx = statuses.indexOf(status);
  return idx >= 0 ? idx : 0;
}

/// Status color mapping
Color _statusColor(String status) {
  switch (status) {
    case 'pending':
      return AppColors.statusPending;
    case 'confirmed':
      return AppColors.statusConfirmed;
    case 'preparing':
      return AppColors.statusPreparing;
    case 'ready':
    case 'delivering':
      return AppColors.statusDelivering;
    case 'completed':
      return AppColors.statusCompleted;
    case 'cancelled':
      return AppColors.statusCancelled;
    default:
      return AppColors.textHint;
  }
}

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late String _orderNumber;
  late String _orderStatus;
  late String _orderId;
  late int _remainingMinutes;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _orderId = extra?['orderId'] as String? ?? '';
    _orderNumber = extra?['orderNumber'] as String? ?? 'TW-20260815-0001';
    _orderStatus = 'pending';
    _remainingMinutes = 35;

    if (_orderId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrderProvider>().loadOrder(_orderId);
        context.read<OrderProvider>().listenToOrder(_orderId);
      });
    }

    // Countdown timer
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_remainingMinutes > 0) {
        setState(() => _remainingMinutes--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _canCancel =>
      (_orderStatus == 'pending' || _orderStatus == 'confirmed')
      && _orderId.isNotEmpty;

  void _showCancelDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'إلغاء الطلب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('هل أنت متأكد من إلغاء الطلب؟'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'ذكر سبب الإلغاء (اختياري)',
                  contentPadding: EdgeInsets.all(12),
                ),
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel, style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (_orderId.isNotEmpty) {
                  context.read<OrderProvider>().cancelOrder(
                    _orderId,
                    reason: reasonController.text.isNotEmpty ? reasonController.text : null,
                  );
                } else {
                  setState(() => _orderStatus = 'cancelled');
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.orderCancelledSuccess)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.confirm, style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final liveOrder = orderProvider.currentOrder;
    final status = liveOrder?.orderStatus ?? _orderStatus;
    final orderNum = liveOrder?.orderNumber ?? _orderNumber;
    final currentIndex = _statusIndex(status);
    final isCancelled = status == 'cancelled';
    final canCancel = (status == 'pending' || status == 'confirmed') && _orderId.isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تتبع الطلب #$orderNum'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header card
            _buildHeaderCard(currentIndex, isCancelled, status, orderNum),
            const SizedBox(height: 16),
            // Timeline / Stepper
            if (!isCancelled) _buildTimeline(currentIndex),
            if (isCancelled) _buildCancelledBanner(),
            const SizedBox(height: 16),
            // Estimated time
            if (!isCancelled) _buildTimeCard(),
            const SizedBox(height: 16),
            // Restaurant info
            _buildRestaurantCard(),
            const SizedBox(height: 16),
            // Delivery address map placeholder
            _buildAddressCard(),
            const SizedBox(height: 24),
            // Cancel button
            if (canCancel) _buildCancelButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(int currentIndex, bool isCancelled, String status, String orderNum) {
    final statusLabel = isCancelled
        ? AppStrings.orderCancelled
        : _orderSteps[currentIndex].label;
    final color = isCancelled ? AppColors.statusCancelled : _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isCancelled ? Icons.cancel : _orderSteps[currentIndex].icon,
            size: 40,
            color: color,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب #$orderNum',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int currentIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة الطلب',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_orderSteps.length, (index) {
            final step = _orderSteps[index];
            final isActive = index <= currentIndex;
            final isLast = index == _orderSteps.length - 1;
            return _TimelineItem(
              step: step,
              isActive: isActive,
              isLast: isLast,
              isCurrent: index == currentIndex,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'تم إلغاء الطلب',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.estimatedTime,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_remainingMinutes دقيقة',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المطعم',
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant, color: AppColors.secondary.withValues(alpha: 0.6), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مطعم الشيف',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الرياض، الخرطوم',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Call & WhatsApp buttons
              _IconButtonSmall(
                icon: Icons.phone,
                color: AppColors.secondary,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _IconButtonSmall(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'عنوان التوصيل',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: AppColors.textHint.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'خريطة الموقع',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شارع النيل، الرياض، الخرطوم',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _showCancelDialog,
        icon: const Icon(Icons.cancel_outlined, size: 20),
        label: Text(AppStrings.cancelOrder),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ---- Timeline item ----
class _TimelineItem extends StatelessWidget {
  final _OrderStep step;
  final bool isActive;
  final bool isLast;
  final bool isCurrent;

  const _TimelineItem({
    required this.step,
    required this.isActive,
    required this.isLast,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: isCurrent ? 28 : 24,
                  height: isCurrent ? 28 : 24,
                  decoration: BoxDecoration(
                    color: isActive ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: isCurrent ? 3 : 2,
                    ),
                  ),
                  child: isActive
                      ? Icon(
                          step.icon,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Text(
                step.label,
                style: GoogleFonts.cairo(
                  fontSize: isCurrent ? 15 : 14,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Small icon button ----
class _IconButtonSmall extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButtonSmall({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}