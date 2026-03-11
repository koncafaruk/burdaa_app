import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../courses/bloc/courses_bloc.dart';
import '../../today/bloc/attendance_bloc.dart';
import '../../../core/util/notification_service.dart';
import '../../../core/database/database_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ayarlar',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uygulama tercihlerini buradan değiştirebilirsin.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.backup_outlined,
                        title: 'Veritabanını Yedekle',
                        subtitle: 'Veritabanını harici bir dosyaya yedekle',
                        onTap: () => _handleBackup(context),
                      ),
                      _buildSettingTile(
                        context,
                        icon: Icons.restore_outlined,
                        title: 'Veritabanı Geri Yükle',
                        subtitle: 'Yedekten veritabanını geri yükle',
                        onTap: () => _handleRestore(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Versiyon 1.0.1+5',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context) async {
    try {
      final String timestamp = DateFormat(
        'yyyyMMdd_HHmmss',
      ).format(DateTime.now());
      final String fileName = 'burdaa_vibe_backup_$timestamp.db';

      final List<int> dbBytes = await DatabaseHelper.instance
          .getDatabaseBytes();

      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Yedeği Kaydet',
        fileName: fileName,
        bytes: Uint8List.fromList(dbBytes),
        type: FileType.any,
      );

      if (selectedPath != null) {
        if (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS) {
          await DatabaseHelper.instance.backupDatabase(selectedPath);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yedekleme başarılı: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRestore(BuildContext context) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Veritabanı Dosyası Seç (Yedek)',
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        if (!path.endsWith('.db')) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hata: Lütfen geçerli bir .db dosyası seçin.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await DatabaseHelper.instance.restoreDatabase(path);

        // Cancel old notifications before refreshing courses
        await NotificationService().cancelAllNotifications();

        if (context.mounted) {
          // Trigger course reload which implicitly handles setting up new notifications via CoursesBloc logic
          context.read<CoursesBloc>().add(LoadCourses());
          context.read<AttendanceBloc>().add(LoadAttendance());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Veritabanı geri yüklendi! Kurslar ve bildirimler güncellendi.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.tertiary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
