import 'package:flutter/material.dart';

enum WaterType { tawar, asin }

extension WaterTypeX on WaterType {
  String get label => this == WaterType.tawar ? 'Air Tawar' : 'Air Asin';
  Color get color => this == WaterType.tawar ? Colors.teal : Colors.indigo;
}

WaterType waterFromName(String? name) =>
    name == 'asin' ? WaterType.asin : WaterType.tawar;

class Species {
  const Species(
    this.id,
    this.name,
    this.latin,
    this.water,
    this.note,
  );

  final String id;
  final String name;
  final String latin;
  final WaterType water;
  final String note;

  String? get assetPath =>
      id == otherSpeciesId ? null : 'assets/species/$id.jpg';
}

/// Pilihan untuk ikan yang belum ada di Dex. Tidak masuk grid Dex.
const String otherSpeciesId = 'lainnya';
const Species kOtherSpecies = Species(
  otherSpeciesId,
  'Lainnya (ketik sendiri)',
  '-',
  WaterType.tawar,
  '',
);

/// Daftar Dex: ikan perairan Indonesia yang umum dipancing.
/// Urutan menentukan nomor Dex, jadi tambahkan spesies baru di AKHIR daftar.
final List<Species> kDexSpecies = [
  // ---- Air tawar ----
  Species('nila', 'Nila', 'Oreochromis niloticus', WaterType.tawar,
      'Kolam, waduk, dan sungai. Umpan: cacing, pelet, roti.'),
  Species('mujair', 'Mujair', 'Oreochromis mossambicus', WaterType.tawar,
      'Waduk, tambak, dan sungai; tahan air payau.'),
  Species('gurame', 'Gurame', 'Osphronemus goramy', WaterType.tawar,
      'Kolam dan sungai tenang. Umpan: cacing, pelet.'),
  Species('bawal-tawar', 'Bawal Air Tawar', 'Colossoma macropomum',
      WaterType.tawar, 'Kolam pemancingan dan waduk. Umpan: pelet, buah.'),
  Species('tawes', 'Tawes', 'Barbonymus gonionotus', WaterType.tawar,
      'Sungai dan waduk. Umpan: pelet, cacing.'),
  Species('lele', 'Lele', 'Clarias gariepinus', WaterType.tawar,
      'Kolam, parit, sungai. Aktif malam hari. Umpan: cacing, hati ayam.'),
  Species('mas', 'Ikan Mas', 'Cyprinus carpio', WaterType.tawar,
      'Kolam dan danau. Umpan: pelet, jagung, adonan.'),
  Species('patin', 'Patin', 'Pangasianodon hypophthalmus', WaterType.tawar,
      'Kolam pemancingan dan sungai besar.'),
  Species('gabus', 'Gabus', 'Channa striata', WaterType.tawar,
      'Rawa, sungai, dan sawah. Pemangsa: anak ikan, katak.'),
  Species('toman', 'Toman', 'Channa micropeltes', WaterType.tawar,
      'Sungai besar dan waduk. Pemangsa, sering disambar lure.'),
  Species('baung', 'Baung', 'Hemibagrus nemurus', WaterType.tawar,
      'Sungai berarus. Umpan: cacing, hati.'),
  Species('nilem', 'Nilem', 'Osteochilus vittatus', WaterType.tawar,
      'Sungai dan kolam.'),
  Species('jelawat', 'Jelawat', 'Leptobarbus hoevenii', WaterType.tawar,
      'Sungai besar Sumatra dan Kalimantan; suka buah-buahan.'),
  Species('betok', 'Betok', 'Anabas testudineus', WaterType.tawar,
      'Rawa dan parit.'),
  Species('sepat-siam', 'Sepat Siam', 'Trichopodus pectoralis',
      WaterType.tawar, 'Rawa dan kolam.'),
  Species('hampala', 'Hampala (Sebarau)', 'Hampala macrolepidota',
      WaterType.tawar, 'Sungai berarus. Sering dipancing dengan lure.'),
  Species('black-bass', 'Black Bass', 'Micropterus salmoides',
      WaterType.tawar, 'Spesies introduksi di beberapa waduk. Casting lure.'),
  Species('sapu-sapu', 'Sapu-sapu', 'Pterygoplichthys pardalis',
      WaterType.tawar, 'Spesies invasif; sering tertangkap tidak sengaja.'),

  // ---- Air asin (termasuk payau/muara) ----
  Species('barramundi', 'Kakap Putih (Barramundi)', 'Lates calcarifer',
      WaterType.asin, 'Muara, mangrove, dan tambak. Casting lure atau umpan hidup.'),
  Species('kakap-bakau', 'Kakap Bakau', 'Lutjanus argentimaculatus',
      WaterType.asin, 'Mangrove dan muara.'),
  Species('kakap-merah', 'Kakap Merah', 'Lutjanus malabaricus',
      WaterType.asin, 'Karang dan dasar laut. Umpan ikan hidup atau potongan.'),
  Species('kerapu', 'Kerapu', 'Epinephelus spp.', WaterType.asin,
      'Karang dan bebatuan dasar.'),
  Species('barakuda', 'Barakuda', 'Sphyraena barracuda', WaterType.asin,
      'Pemangsa cepat; gigi tajam, pakai leader.'),
  Species('gt', 'Kuwe (GT)', 'Caranx ignobilis', WaterType.asin,
      'Popping, casting, dan jigging di sekitar karang.'),
  Species('tenggiri', 'Tenggiri', 'Scomberomorus commerson', WaterType.asin,
      'Trolling dan casting; gigi tajam, pakai leader.'),
  Species('tongkol', 'Tongkol', 'Euthynnus affinis', WaterType.asin,
      'Perairan pantai dan lepas pantai.'),
  Species('cakalang', 'Cakalang', 'Katsuwonus pelamis', WaterType.asin,
      'Perairan lepas pantai.'),
  Species('tuna-sirip-kuning', 'Tuna Sirip Kuning', 'Thunnus albacares',
      WaterType.asin, 'Perairan dalam lepas pantai.'),
  Species('bawal-putih', 'Bawal Putih', 'Pampus argenteus', WaterType.asin,
      'Perairan pantai berlumpur.'),
  Species('baronang', 'Baronang', 'Siganus spp.', WaterType.asin,
      'Padang lamun dan karang. Hati-hati, duri siripnya berbisa.'),
  Species('ekor-kuning', 'Ekor Kuning', 'Caesio cuning', WaterType.asin,
      'Karang; berkelompok.'),
  Species('kurisi', 'Kurisi', 'Nemipterus spp.', WaterType.asin,
      'Dasar laut berpasir.'),
  Species('lencam', 'Lencam', 'Lethrinus spp.', WaterType.asin,
      'Karang dan dasar berpasir.'),
  Species('kembung', 'Kembung', 'Rastrelliger kanagurta', WaterType.asin,
      'Perairan pantai; berkelompok.'),
  Species('bandeng', 'Bandeng', 'Chanos chanos', WaterType.asin,
      'Tambak dan muara.'),
  Species('belanak', 'Belanak', 'Mugil cephalus', WaterType.asin,
      'Muara dan pantai. Umpan: roti, adonan.'),
  Species('senangin', 'Senangin', 'Eleutheronema tetradactylum',
      WaterType.asin, 'Muara dan pantai berlumpur.'),
  Species('sembilang', 'Sembilang', 'Plotosus canius', WaterType.asin,
      'Muara berlumpur. Hati-hati, patilnya berbisa.'),
  Species('kerong-kerong', 'Kerong-kerong', 'Terapon jarbua', WaterType.asin,
      'Muara dan pantai.'),
  Species('pari', 'Pari', 'Dasyatidae', WaterType.asin,
      'Dasar laut dan muara. Sengatnya berbisa. Beberapa jenis pari dilindungi; lepaskan bila ragu.'),
];

Species? speciesById(String id) {
  for (final s in kDexSpecies) {
    if (s.id == id) return s;
  }
  return null;
}
