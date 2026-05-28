import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/follow_up_viewmodel.dart';
import '../../widgets/follow_up_status_badge.dart';
import '../../widgets/follow_up_timeline_item.dart';
import '../../../domain/entities/adoption_follow_up.dart';
import 'package:intl/intl.dart';

class FollowUpDetailPage extends StatefulWidget {
  final String id;
  const FollowUpDetailPage({super.key, required this.id});

  @override
  State<FollowUpDetailPage> createState() => _FollowUpDetailPageState();
}

class _FollowUpDetailPageState extends State<FollowUpDetailPage> {
  final _commentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  String _saude = 'Excelente';
  String _comportamento = 'Normal';
  String _alimentacao = 'Ótima';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowUpViewModel>().loadFollowUpDetails(widget.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhamento')),
      body: Consumer<FollowUpViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading)
            return const Center(child: CircularProgressIndicator());
          if (vm.selectedFollowUp == null)
            return const Center(child: Text('Não encontrado'));

          final f = vm.selectedFollowUp!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(f),
                if (f.status != 'CONCLUIDO')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => _showUpdateForm(context, vm),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Enviar Nova Atualização'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
                  child: Text(
                    'HISTÓRICO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vm.updates.length,
                  itemBuilder: (context, index) => FollowUpTimelineItem(
                    update: vm.updates[index],
                    isLast: index == vm.updates.length - 1,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(AdoptionFollowUp f) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: f.petFotoUrl != null
                ? NetworkImage(f.petFotoUrl!)
                : null,
            child: f.petFotoUrl == null ? const Icon(Icons.pets) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.petNome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                FollowUpStatusBadge(status: f.status),
                const SizedBox(height: 4),
                Text(
                  'Próxima entrega: ${DateFormat('dd/MM').format(f.dataProximaAtualizacao)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateForm(BuildContext context, FollowUpViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nova Atualização',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Como ele(a) está?'),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Conte um pouco sobre a adaptação...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdown('Saúde', _saude, [
                  'Excelente',
                  'Boa',
                  'Regular',
                  'Ruim',
                ], (v) => setModalState(() => _saude = v!)),
                _buildDropdown(
                  'Comportamento',
                  _comportamento,
                  ['Normal', 'Agitado', 'Triste', 'Agressivo'],
                  (v) => setModalState(() => _comportamento = v!),
                ),
                _buildDropdown(
                  'Alimentação',
                  _alimentacao,
                  ['Ótima', 'Normal', 'Comendo pouco', 'Não come'],
                  (v) => setModalState(() => _alimentacao = v!),
                ),
                const SizedBox(height: 16),
                const Text('Fotos recentes'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      InkWell(
                        onTap: () async {
                          final img = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (img != null)
                            setModalState(() => _selectedImages.add(img));
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ..._selectedImages.map(
                        (img) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(img.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final ok = await vm.sendUpdate(
                      followUpId: widget.id,
                      fotosPaths: _selectedImages.map((e) => e.path).toList(),
                      descricao: _commentController.text,
                      statusSaude: _saude,
                      statusComportamento: _comportamento,
                      statusAlimentacao: _alimentacao,
                    );
                    if (ok && mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Enviar Atualização'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 3,
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
