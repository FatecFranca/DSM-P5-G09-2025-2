// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Perfil e Configurações',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          SizedBox(height: 24),
          _buildSettingsSection(),
          SizedBox(height: 24),
          _buildAppInfoSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green[100],
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fazendeiro',
                    style: GoogleFonts.interTight(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Usuário Premium',
                    style: GoogleFonts.inter(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fazenda Boa Esperança',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    bool notificationsEnabled = true;
    bool soundEnabled = true;
    bool darkMode = false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações',
              style: GoogleFonts.interTight(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSettingSwitch(
              'Notificações de Lembrete',
              'Receber lembretes diários',
              Icons.notifications,
              notificationsEnabled,
              (value) {
                if (value) {
                  NotificationService.scheduleReminderNotification();
                }
              },
            ),
            _buildSettingSwitch(
              'Som de Confirmação',
              'Tocar som ao obter resultado',
              Icons.volume_up,
              soundEnabled,
              (value) {},
            ),
            _buildSettingSwitch(
              'Modo Escuro',
              'Alternar para tema escuro',
              Icons.dark_mode,
              darkMode,
              (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: Colors.grey[600])),
      secondary: Icon(icon, color: Colors.green),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.green,
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do App',
              style: GoogleFonts.interTight(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoItem('Versão', '1.0.0', Icons.info),
            _buildInfoItem('Desenvolvedor', 'Farm Tech Solutions', Icons.code),
            _buildInfoItem('Contato', 'contato@farmtech.com', Icons.email),
            _buildInfoItem('Política de Privacidade', 'Ler mais', Icons.privacy_tip),
            _buildInfoItem('Termos de Uso', 'Ler mais', Icons.description),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.green, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: GoogleFonts.inter(color: Colors.grey[600])),
      onTap: () {},
      contentPadding: EdgeInsets.zero,
    );
  }
}