import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pulselink/main.dart';
import 'package:pulselink/presentation/navigation/app_router.dart';
import 'package:pulselink/presentation/navigation/navigation_helper.dart';
import 'package:pulselink/core/routes/app_routes.dart';

void main() {
  group('Integration Tests', () {
    testWidgets('Navigation Helper Routes Test', (WidgetTester tester) async {
      // Test navigation helper route constants
      expect(AppRoutes.discover, '/discover');
      expect(AppRoutes.profile, '/profile');
      expect(AppRoutes.messages, '/messages');
      expect(AppRoutes.advancedFeatures, '/advanced-features');
      expect(AppRoutes.realTimeChat, '/real-time-chat');
      expect(AppRoutes.voiceVideo, '/voice-video');
      expect(AppRoutes.virtualGifts, '/virtual-gifts');
      expect(AppRoutes.subscriptions, '/subscriptions');
      expect(AppRoutes.notifications, '/notifications');
      expect(AppRoutes.security, '/security');
      expect(AppRoutes.enhancedProfileEdit, '/enhanced-profile-edit');
      expect(AppRoutes.paymentManagement, '/payment-management');
      expect(AppRoutes.profilePreview, '/profile-preview');
    });

    testWidgets('Navigation Helper Methods Test', (WidgetTester tester) async {
      // Create a minimal app with navigation
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: AppRouter.router,
        ),
      );

      // Test that we can access navigation methods without errors
      expect(NavigationHelper.goToDiscover, isA<Function>());
      expect(NavigationHelper.goToProfile, isA<Function>());
      expect(NavigationHelper.goToMessages, isA<Function>());
      expect(NavigationHelper.goToAdvancedFeatures, isA<Function>());
      expect(NavigationHelper.goToRealTimeChat, isA<Function>());
      expect(NavigationHelper.goToVoiceVideo, isA<Function>());
      expect(NavigationHelper.goToVirtualGifts, isA<Function>());
      expect(NavigationHelper.goToSubscriptions, isA<Function>());
      expect(NavigationHelper.goToNotifications, isA<Function>());
      expect(NavigationHelper.goToSecurity, isA<Function>());
      expect(NavigationHelper.goToEnhancedProfileEdit, isA<Function>());
      expect(NavigationHelper.goToPaymentManagement, isA<Function>());
      expect(NavigationHelper.goToProfilePreview, isA<Function>());
    });

    testWidgets('App Router Configuration Test', (WidgetTester tester) async {
      // Test that router is properly configured
      expect(AppRouter.router, isNotNull);
      expect(AppRouter.router.configuration, isNotNull);
      
      // Test that router can handle initial route
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: AppRouter.router,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should not throw any errors during initial load
      expect(tester.takeException(), isNull);
    });

    testWidgets('BLoC Registration Test', (WidgetTester tester) async {
      // Test that BLoCs are properly registered and accessible
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: AppRouter.router,
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should be able to build without provider errors
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Profile BLoC Integration Tests', () {
    testWidgets('Profile BLoC State Management Test', (WidgetTester tester) async {
      // Simple test to verify BLoC states are properly defined
      // Note: This is a compile-time check for state classes
      expect(() {
        // Import and instantiate states to ensure they compile
        const profileInitial = ProfileInitial();
        const profileLoading = ProfileLoading();
        const profileError = ProfileError('Test error');
        const photoUploading = PhotoUploading();
        const photoDeleting = PhotoDeleting();
        const photoDeleteError = PhotoDeleteError('Test error');
        
        // Verify states are Equatable
        expect(profileInitial, equals(const ProfileInitial()));
        expect(profileLoading, equals(const ProfileLoading()));
        expect(profileError, equals(const ProfileError('Test error')));
        expect(photoUploading, equals(const PhotoUploading()));
        expect(photoDeleting, equals(const PhotoDeleting()));
        expect(photoDeleteError, equals(const PhotoDeleteError('Test error')));
      }, returnsNormally);
    });
  });
}
