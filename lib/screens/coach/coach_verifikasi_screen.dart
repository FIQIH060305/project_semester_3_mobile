import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class CoachVerifikasiScreen extends StatefulWidget {
  const CoachVerifikasiScreen({super.key});

  @override
  State<CoachVerifikasiScreen> createState() => _CoachVerifikasiScreenState();
}

class _CoachVerifikasiScreenState extends State<CoachVerifikasiScreen> {
  bool _isChecking = false;

  Future<void> _cekStatus() async {
    setState(() => _isChecking = true);
    final updated = await AuthService.instance.refreshCoachStatus();
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (updated?.statusVerifikasi == 'approved') {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/coach-dashboard', (route) => false);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated?.statusVerifikasi == 'rejected'
              ? 'Pendaftaran ditolak. Periksa alasan penolakan di layar.'
              : 'Status pendaftaran masih menunggu persetujuan Admin.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final coach = user?.coach;
    final isRejected = coach?.statusVerifikasi == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isRejected
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top_rounded,
                  size: 46,
                  color: isRejected
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isRejected
                    ? 'Pendaftaran Coach Ditolak'
                    : 'Menunggu Verifikasi Admin',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isRejected
                    ? 'Mohon maaf ${coach?.nama ?? user?.name ?? ''}, pengajuan Coach kamu belum dapat disetujui.'
                    : 'Halo ${coach?.nama ?? user?.name ?? ''}, akun Coach kamu sedang ditinjau oleh Admin GERAK. Fitur pendampingan & rekomendasi akan terbuka otomatis setelah disetujui.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              if (isRejected &&
                  coach?.alasanPenolakan != null &&
                  coach!.alasanPenolakan!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alasan Penolakan dari Admin:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coach.alasanPenolakan!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _cekStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text(
                    _isChecking
                        ? 'Memeriksa Status...'
                        : 'Cek Status Verifikasi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 19),
                label: const Text(
                  'Keluar Akun',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}