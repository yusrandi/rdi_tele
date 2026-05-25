import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final Function() onAgree;

  const PrivacyPolicyScreen({super.key, required this.onAgree});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _hasAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.shade100,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.privacy_tip,
                        size: 60,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Privasi & Izin Aplikasi',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'RealSpeed Analyzer',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Content ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Izin yang Dibutuhkan ──────────────────
                      _buildSectionTitle('Izin yang Dibutuhkan'),

                      _buildPermissionItem(
                        icon: Icons.location_on,
                        title: 'Lokasi (Saat Digunakan)',
                        description:
                            'Untuk merekam koordinat GPS selama sesi pengukuran '
                            'dan menampilkan posisi tower jaringan terdekat.',
                        isRequired: true,
                        badge: 'WAJIB',
                        badgeColor: Colors.red,
                      ),

                      _buildPermissionItem(
                        icon: Icons.location_searching,
                        title: 'Lokasi Background ("Izinkan Setiap Saat")',
                        description:
                            'Diperlukan agar perekaman GPS tetap berjalan saat '
                            'Anda membuka aplikasi lain selama sesi pengukuran aktif. '
                            'Lokasi hanya direkam selama sesi berlangsung.',
                        isRequired: true,
                        badge: 'WAJIB',
                        badgeColor: Colors.orange,
                      ),

                      _buildPermissionItem(
                        icon: Icons.phone_android,
                        title: 'Informasi Telepon',
                        description:
                            'Untuk membaca data sinyal jaringan (RSRP, RSRQ, RSSI, SNR), '
                            'tipe jaringan, operator, dan informasi sel (Cell ID, PCI, TAC).',
                        isRequired: true,
                        badge: 'WAJIB',
                        badgeColor: Colors.red,
                      ),

                      _buildPermissionItem(
                        icon: Icons.notifications,
                        title: 'Notifikasi',
                        description:
                            'Untuk menampilkan notifikasi permanen selama sesi '
                            'pengukuran aktif (foreground service). Notifikasi ini '
                            'menunjukkan sisa waktu sesi dan tombol Stop.',
                        isRequired: true,
                        badge: 'WAJIB',
                        badgeColor: Colors.red,
                      ),

                      _buildPermissionItem(
                        icon: Icons.network_check,
                        title: 'Akses Internet',
                        description:
                            'Untuk melakukan speed test (download & upload) '
                            'dan mengirim hasil pengukuran ke server analisis.',
                        isRequired: true,
                        badge: 'WAJIB',
                        badgeColor: Colors.red,
                      ),

                      const SizedBox(height: 24),

                      // ── Foreground Service ────────────────────
                      _buildSectionTitle(
                        'Layanan Background (Foreground Service)',
                      ),

                      _buildInfoBox(
                        icon: Icons.memory,
                        color: Colors.blue,
                        content:
                            'Saat sesi pengukuran dimulai, aplikasi menjalankan '
                            'Foreground Service yang ditandai dengan notifikasi '
                            'permanen di status bar.\n\n'
                            'Layanan ini berfungsi untuk:\n'
                            '• Monitoring sinyal jaringan tiap 2 detik\n'
                            '• Menjaga akurasi data saat layar mati\n'
                            '• Memastikan speed test tidak terputus\n'
                            '• Perekaman GPS berjalan terus selama sesi\n\n'
                            'Layanan berhenti otomatis saat sesi selesai '
                            'atau Anda menekan tombol STOP.',
                      ),

                      const SizedBox(height: 24),

                      // ── Data yang Dikumpulkan ─────────────────
                      _buildSectionTitle('Data yang Dikumpulkan'),

                      _buildInfoBox(
                        icon: Icons.storage,
                        color: Colors.purple,
                        content:
                            'Selama sesi pengukuran, aplikasi mengumpulkan:\n\n'
                            '• Sinyal jaringan: RSRP, RSRQ, RSSI, SNR/SINR\n'
                            '• Info sel: Cell ID, PCI, TAC, eNodeB, Sektor\n'
                            '• Info operator: MCC, MNC, nama operator\n'
                            '• Tipe jaringan: LTE, NR (5G), WCDMA, GSM\n'
                            '• Kecepatan: Download, Upload, Latency\n'
                            '• Lokasi GPS: Latitude, Longitude, Akurasi\n'
                            '• Info perangkat: Model, Versi Android\n\n'
                            'Semua data dikirim ke server untuk keperluan '
                            'analisis kualitas jaringan.',
                      ),

                      const SizedBox(height: 24),

                      // ── Komitmen Privasi ──────────────────────
                      _buildSectionTitle('Komitmen Privasi Kami'),

                      _buildPrivacyPoint(
                        '🔐 Data sinyal tidak mengandung informasi pribadi',
                      ),
                      _buildPrivacyPoint(
                        '📍 Lokasi hanya direkam saat sesi pengukuran aktif',
                      ),
                      _buildPrivacyPoint(
                        '📊 Data digunakan semata-mata untuk analisis coverage jaringan',
                      ),
                      _buildPrivacyPoint(
                        '🚫 Data tidak dijual atau dibagikan ke pihak ketiga',
                      ),
                      _buildPrivacyPoint(
                        '🔔 Notifikasi foreground service dapat dihapus kapan saja '
                        'dengan menekan tombol STOP di notifikasi',
                      ),
                      _buildPrivacyPoint(
                        '⏱ Semua pengumpulan data berhenti saat sesi selesai',
                      ),

                      const SizedBox(height: 24),

                      // ── Catatan Background Location ───────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Catatan Penting',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Setelah menyetujui kebijakan ini, Anda akan diminta '
                              'memberikan izin lokasi background. Pada layar izin '
                              'sistem Android, pilih "Izinkan Setiap Saat" agar '
                              'pengukuran berjalan optimal saat aplikasi di-minimize.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade800,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Checkbox Persetujuan ──────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _hasAgreed
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasAgreed
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _hasAgreed,
                              onChanged: (value) {
                                setState(() => _hasAgreed = value ?? false);
                              },
                              activeColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Saya menyetujui ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Kebijakan Privasi',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          ' ini dan memberikan izin yang diperlukan '
                                          'untuk pengoperasian aplikasi, termasuk '
                                          'akses lokasi background selama sesi pengukuran.',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // ── Action Buttons ───────────────────────────────
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasAgreed ? widget.onAgree : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasAgreed
                                ? Icons.check_circle
                                : Icons.lock_outline,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _hasAgreed
                                ? 'SETUJU & LANJUTKAN'
                                : 'CENTANG KOTAK DI ATAS',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Keluar dari Aplikasi?'),
                          content: const Text(
                            'Aplikasi tidak dapat berfungsi tanpa izin yang diperlukan. '
                            'Apakah Anda yakin ingin keluar?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                              ),
                              onPressed: () {
                                // Tutup app
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Keluar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Tolak & Keluar',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isRequired,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.red.shade700, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
