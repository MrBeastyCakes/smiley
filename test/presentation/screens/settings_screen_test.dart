import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/constants/app_constants.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/domain/repositories/settings_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/settings/settings_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/settings_screen.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}
class FakeGatewaySettings extends Fake implements GatewaySettings {}

void main() {
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const GatewaySettings(host: '', port: 0, token: ''));
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
  });

  Widget buildTestableWidget({required SettingsBloc bloc, required WidgetTester tester}) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return MaterialApp(
      home: BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: const SettingsScreen(),
      ),
    );
  }

  group('SettingsScreen', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsLoaded when LoadSettings is added and settings exist',
      build: () {
        when(() => mockRepository.getSettings()).thenAnswer(
          (_) async => const Right(GatewaySettings(host: '192.168.1.1', port: 18789, token: 'abc123')),
        );
        return SettingsBloc(settingsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        const SettingsLoading(),
        SettingsLoaded(
          settings: const GatewaySettings(host: '192.168.1.1', port: 18789, token: 'abc123'),
          version: AppConstants.appVersion,
          buildNumber: '1',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsLoaded with null settings when none saved',
      build: () {
        when(() => mockRepository.getSettings()).thenAnswer(
          (_) async => const Right(null),
        );
        return SettingsBloc(settingsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        const SettingsLoading(),
        SettingsLoaded(
          settings: null,
          version: AppConstants.appVersion,
          buildNumber: '1',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsDisconnected on Disconnect',
      build: () {
        when(() => mockRepository.deleteSettings()).thenAnswer((_) async => const Right(null));
        return SettingsBloc(settingsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const Disconnect()),
      expect: () => [
        const SettingsLoading(),
        const SettingsDisconnected(),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'emits SettingsCacheCleared on ClearCache',
      build: () {
        when(() => mockRepository.deleteSettings()).thenAnswer((_) async => const Right(null));
        return SettingsBloc(settingsRepository: mockRepository);
      },
      act: (bloc) => bloc.add(const ClearCache()),
      expect: () => [
        const SettingsLoading(),
        const SettingsCacheCleared(),
      ],
    );

    testWidgets('displays settings title', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders gateway connection fields', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer(
        (_) async => const Right(GatewaySettings(host: '192.168.1.1', port: 18789, token: 'abc123')),
      );
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Host'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
      expect(find.text('Token'), findsOneWidget);

      expect(find.text('192.168.1.1'), findsOneWidget);
      expect(find.text('18789'), findsOneWidget);
      expect(find.text('••••c123'), findsOneWidget);
    });

    testWidgets('shows em dash when no settings saved', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsNWidgets(3));
    });

    testWidgets('has disconnect button', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect'), findsOneWidget);
    });

    testWidgets('has theme toggle switch', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('has clear data button', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Clear all data'), findsOneWidget);
    });

    testWidgets('shows version info', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text(AppConstants.appVersion), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('tapping disconnect shows confirmation dialog', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();

      expect(find.text('Disconnect from gateway?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Disconnect'), findsNWidgets(2));
    });

    testWidgets('tapping clear data shows confirmation dialog', (tester) async {
      when(() => mockRepository.getSettings()).thenAnswer((_) async => const Right(null));
      final bloc = SettingsBloc(settingsRepository: mockRepository);
      await tester.pumpWidget(buildTestableWidget(bloc: bloc, tester: tester));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear all data'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all data?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });
  });
}
