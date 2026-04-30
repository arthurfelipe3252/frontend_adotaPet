import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:adota_pet/presentation/pages/settings_page.dart';
import 'package:adota_pet/domain/entities/user.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'dart:io';

void main() {
  testWidgets('SettingsPage exibe opçoes corretas para ONG', (
    WidgetTester tester,
  ) async {
    const userNgo = User(
      id: '1',
      name: 'ONG Cão Feliz',
      email: 'contato@caofeliz.org',
      type: UserType.ngo,
    );

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage(currentUser: userNgo)),
      );

      expect(find.text('ONG Cão Feliz'), findsOneWidget);
      expect(find.text('contato@caofeliz.org'), findsOneWidget);
      expect(find.text('Gestão da ONG'), findsOneWidget);
      expect(find.text('Meus Pets Cadastrados'), findsOneWidget);
      expect(find.text('Solicitações de Adoção'), findsOneWidget);
      expect(find.text('Meus Favoritos'), findsNothing);
    });
  });

  testWidgets('SettingsPage exibe opçoes corretas para Doador', (
    WidgetTester tester,
  ) async {
    const userDonor = User(
      id: '2',
      name: 'João Doador',
      email: 'joao@email.com',
      type: UserType.donor,
    );

    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage(currentUser: userDonor)),
      );

      expect(find.text('João Doador'), findsOneWidget);
      expect(find.text('joao@email.com'), findsOneWidget);
      expect(find.text('Adoções e Doações'), findsOneWidget);
      expect(find.text('Meus Favoritos'), findsOneWidget);
      expect(find.text('Meus Pets Cadastrados'), findsNothing);
    });
  });
}
