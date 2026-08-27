import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/restaurant/restaurant_detail_screen.dart';
import '../models/restaurant_model.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/checkout/order_confirmation_screen.dart';
import '../features/orders/order_tracking_screen.dart';
import '../features/orders/orders_list_screen.dart';
import '../features/orders/order_history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/addresses_screen.dart';
import '../providers/cart_provider.dart';
import '../features/cart/add_address_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/reviews/reviews_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/language_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: OtpScreen(),
        ),
      ),
      GoRoute(
        path: '/profile_setup',
        name: 'profileSetup',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/restaurant/:id',
        name: 'restaurantDetail',
        builder: (context, state) {
          final restaurantId = state.pathParameters['id'] ?? '';
          // Versuche das Restaurant aus state.extra zu laden
          final restaurant = state.extra is RestaurantModel
              ? state.extra as RestaurantModel
              : null;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: RestaurantDetailScreen(
              restaurant: restaurant ??
                  RestaurantModel(
                    id: restaurantId,
                    nameAr: 'مطعم طوالي',
                    nameEn: 'Tawali Restaurant',
                    phone: '0912345678',
                    address: 'الخرطوم',
                    district: 'الرياض',
                    rating: 4.5,
                    reviewCount: 100,
                    deliveryFee: 3.0,
                    minOrder: 10.0,
                    deliveryTimeMin: 20,
                    deliveryTimeMax: 40,
                    isActive: true,
                    isFeatured: false,
                  ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: CartScreen(),
        ),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => Directionality(
          textDirection: TextDirection.rtl,
          child: CheckoutScreen(
            restaurantId: context.read<CartProvider>().cartItems.isNotEmpty
                ? context.read<CartProvider>().cartItems.first.item.restaurantId
                : '',
          ),
        ),
      ),
      GoRoute(
        path: '/order_confirmation',
        name: 'orderConfirmation',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: OrderConfirmationScreen(),
        ),
      ),
      GoRoute(
        path: '/order_tracking',
        name: 'orderTracking',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: OrderTrackingScreen(),
        ),
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: OrdersListScreen(),
        ),
      ),
      GoRoute(
        path: '/order_history',
        name: 'orderHistory',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: OrderHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: ProfileScreen(),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => const Directionality(
              textDirection: TextDirection.rtl,
              child: EditProfileScreen(),
            ),
          ),
          GoRoute(
            path: 'addresses',
            name: 'addresses',
            builder: (context, state) => const Directionality(
              textDirection: TextDirection.rtl,
              child: AddressesScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/add_address',
        name: 'addAddress',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: AddAddressScreen(),
        ),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: '/reviews/:orderId',
        name: 'reviews',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: ReviewsScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const Directionality(
          textDirection: TextDirection.rtl,
          child: SettingsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'language',
            name: 'language',
            builder: (context, state) => const Directionality(
              textDirection: TextDirection.rtl,
              child: LanguageScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}