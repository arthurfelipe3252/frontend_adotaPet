import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../../domain/entities/user.dart';

class UserConfigPage extends StatefulWidget {
  const UserConfigPage({super.key});

  @override
  State<UserConfigPage> createState() => _UserConfigPageState();
}

class _UserConfigPageState extends State<UserConfigPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações de Usuários')),
      body: Consumer<UserViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null) {
            return Center(child: Text(vm.error!));
          }
          if (vm.users.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          return ListView.builder(
            itemCount: vm.users.length,
            itemBuilder: (_, i) {
              final user = vm.users[i];
              final isNgo = user.type == UserType.ngo;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isNgo
                      ? Colors.orange.shade100
                      : Colors.blue.shade100,
                  child: Icon(
                    isNgo ? Icons.pets : Icons.favorite,
                    color: isNgo ? Colors.orange : Colors.blue,
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: Chip(
                  label: Text(
                    isNgo ? 'ONG' : 'Doador',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: isNgo
                      ? Colors.orange.shade50
                      : Colors.blue.shade50,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
