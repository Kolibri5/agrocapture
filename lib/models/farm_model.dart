// ═══════════════════════════════════════════════════════════════════════
// Farm — single source of truth shared by MapScreen, ListScreen &
//         DetailScreen
// ═══════════════════════════════════════════════════════════════════════

class Farm {
  final String id;
  final String name;
  final String status;          // "Siap Panen" / "Belum Panen"
  final String groupName;       // kelompok tani
  final String locationText;    // display string
  final String altitude;        // e.g. "1.200 mdpl"
  final double latitude;
  final double longitude;
  final List<String> varieties;
  final String imageUrl;
  final String luasLahan;
  final String estimasiPanen;
  final String subtitle;        // short blurb for title card
  final String description;     // long text for "Tentang Lahan"
  final String contactPhone;
  final String contactEmail;

  const Farm({
    required this.id,
    required this.name,
    required this.status,
    required this.groupName,
    required this.locationText,
    required this.altitude,
    required this.latitude,
    required this.longitude,
    required this.varieties,
    required this.imageUrl,
    this.luasLahan = '-',
    this.estimasiPanen = '-',
    this.subtitle = '',
    this.description = '',
    this.contactPhone = '-',
    this.contactEmail = '-',
  });

  bool get isSiapPanen => status == 'Siap Panen';

  // ─── Dummy data ─────────────────────────────────────────────────

  static const List<Farm> dummyFarms = [
    Farm(
      id: 'lahan_adidaya',
      name: 'Lahan Adidaya Kopi',
      status: 'Siap Panen',
      groupName: 'Kel. Tani Mekar Jaya',
      locationText: 'Malang, Jawa Timur',
      altitude: '1.200 mdpl',
      latitude: -7.831140,
      longitude: 112.599170,
      varieties: ['ARABIKA', 'ROBUSTA', 'EXELSA', 'ETC.'],
      imageUrl: 'assets/images/adidaya.png',
      luasLahan: '50 Ha',
      estimasiPanen: '2-5 Ton',
      subtitle:
          'Koperasi petani kopi lokal yang berdedikasi '
          'tinggi terhadap kualitas dan kelestarian lingkungan.',
      description:
          'Lahan Adidaya Kopi merupakan salah satu lahan percontohan '
          'di kawasan Malang, Jawa Timur. Berada di ketinggian 1.200 mdpl, '
          'lahan ini memiliki iklim mikro yang sangat ideal untuk budidaya '
          'kopi spesialisasi (specialty coffee).\n\n'
          'Sejak tahun 2015, kelompok tani di sini telah menerapkan '
          'metode pertanian organik berkelanjutan, mengurangi penggunaan '
          'pupuk kimia dan beralih ke kompos organik buatan sendiri.\n\n'
          'Komitmen kami adalah menghasilkan biji kopi berkualitas tinggi '
          'sekaligus menjaga ekosistem hutan sekitarnya tetap lestari.',
      contactPhone: '08123456789',
      contactEmail: 'budiman@email.com',
    ),
    Farm(
      id: 'finca_el_ocaso',
      name: 'Kebun Kopi Abadi',
      status: 'Belum Panen',
      groupName: 'Kel. Tani Sejahtera',
      locationText: 'Malang, Jawa Timur',
      altitude: '820 mdpl',
      latitude: -7.946120,
      longitude: 112.531727,
      varieties: ['ARABIKA', 'EXELSA'],
      imageUrl: 'assets/images/ocaso.png',
      luasLahan: '32 Ha',
      estimasiPanen: '1-3 Ton',
      subtitle:
      'Perkebunan kopi rakyat yang fokus pada penanaman '
          'varietas unggulan di dataran tinggi Malang.',
      description:
      'Kebun Kopi Abadi terletak di lereng perbukitan Malang dengan '
          'akses jalan yang memadai. Lahan ini dikelola secara kolektif '
          'oleh kelompok tani setempat.\n\n'
          'Varietas yang ditanam dipilih berdasarkan kesesuaian iklim '
          'dan elevasi Malang untuk memaksimalkan hasil panen.',
      contactPhone: '08219876543',
      contactEmail: 'ocaso@email.com',
    ),
    Farm(
      id: 'finca_recuca',
      name: 'Finca El Malang',
      status: 'Belum Panen',
      groupName: 'Kel. Tani Malang Makmur',
      locationText: 'Malang, Jawa Timur',
      altitude: '1.400 mdpl',
      latitude: -7.817268,
      longitude: 112.564025,
      varieties: ['ROBUSTA'],
      imageUrl: 'assets/images/recuca.png',
      luasLahan: '18 Ha',
      estimasiPanen: '0.5-1 Ton',
      subtitle:
      'Kebun kopi dataran tinggi Malang yang terkenal '
          'dengan cita rasa robusta khas pegunungan.',
      description:
      'Finca El Malang berada di kawasan dataran tinggi Malang, Jawa Timur. '
          'Ketinggian 1.400 mdpl memberikan karakter rasa yang kuat dan unik '
          'pada biji robusta khas lokal.\n\n'
          'Kelompok tani di sini masih mempertahankan metode pascapanen tradisional '
          'yang diwariskan turun-temurun untuk menjaga keaslian rasa.',
      contactPhone: '08567891234',
      contactEmail: 'recuca@email.com',
    ),
  ];
}
