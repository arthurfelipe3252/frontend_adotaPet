import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';

class SettingsPage extends StatelessWidget {
  final User currentUser;

  const SettingsPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final isNgo = currentUser.type == UserType.ngo;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Perfil Header
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                isNgo
                    ? 'https://via.placeholder.com/150/FF9800/FFFFFF?text=ONG'
                    : 'https://via.placeholder.com/150/2196F3/FFFFFF?text=DOA',
              ),
            ),
            title: Text(
              currentUser.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(currentUser.email),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
          const Divider(height: 32),

          // Seções Gerais
          _buildSectionHeader('Conta'),
          _buildSettingsItem(Icons.person_outline, 'Meus Dados'),
          _buildSettingsItem(Icons.lock_outline, 'Privacidade e Segurança'),

          const SizedBox(height: 16),

          // Seção Específica (ONG vs Doador)
          _buildSectionHeader(isNgo ? 'Gestão da ONG' : 'Adoções e Doações'),
          if (isNgo) ...[
            _buildSettingsItem(Icons.pets, 'Meus Pets Cadastrados'),
            _buildSettingsItem(Icons.assignment, 'Solicitações de Adoção'),
            _buildSettingsItem(Icons.monetization_on, 'Dados Bancários / Pix'),
          ] else ...[
            _buildSettingsItem(Icons.favorite_border, 'Meus Favoritos'),
            _buildSettingsItem(Icons.history, 'Histórico de Adoções'),
            _buildSettingsItem(Icons.card_giftcard, 'Minhas Doações'),
          ],

          const SizedBox(height: 16),

          _buildSectionHeader('Preferências'),
          _buildSettingsItem(Icons.notifications_none, 'Notificações'),
          _buildSettingsItem(Icons.dark_mode_outlined, 'Modo Escuro'),

          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text(
              'Sair',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
