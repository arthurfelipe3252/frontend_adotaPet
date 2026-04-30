import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:adota_pet/core/theme/app_theme.dart';

class FileUploadCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Uint8List? bytes;
  final String? filename;
  final List<String> allowedExtensions;
  final void Function(Uint8List bytes, String filename) onPick;
  final VoidCallback? onRemove;
  final String? errorText;

  const FileUploadCard({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.bytes,
    required this.filename,
    required this.allowedExtensions,
    required this.onPick,
    this.onRemove,
    this.errorText,
  });

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    onPick(file.bytes!, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = bytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F0E6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: errorText != null ? AppTheme.destructive : AppTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.foreground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              if (hasFile) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.sage,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filename ?? 'Arquivo selecionado',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatSize(bytes!.lengthInBytes),
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onRemove != null) ...[
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: const Text('Remover'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.destructive,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    OutlinedButton.icon(
                      onPressed: _pick,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Trocar'),
                    ),
                  ],
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.upload_rounded, size: 18),
                  label: const Text('Escolher arquivo'),
                ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: AppTheme.destructive, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
