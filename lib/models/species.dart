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
    this.note, {
    this.imageUrl,
    this.thumbnailUrl,
  });

  final String id;
  final String name;
  final String latin;
  final WaterType water;
  final String note;
  final String? imageUrl;
  final String? thumbnailUrl;

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
      'Kolam, waduk, dan sungai. Umpan: cacing, pelet, roti.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/nila.webp'),
  Species('mujair', 'Mujair', 'Oreochromis mossambicus', WaterType.tawar,
      'Waduk, tambak, dan sungai; tahan air payau.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/mujair.webp'),
  Species('gurame', 'Gurame', 'Osphronemus goramy', WaterType.tawar,
      'Kolam dan sungai tenang. Umpan: cacing, pelet.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/gurame.webp'),
  Species('bawal-tawar', 'Bawal Air Tawar', 'Colossoma macropomum',
      WaterType.tawar, 'Kolam pemancingan dan waduk. Umpan: pelet, buah.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/bawal-tawar.webp'),
  Species('tawes', 'Tawes', 'Barbonymus gonionotus', WaterType.tawar,
      'Sungai dan waduk. Umpan: pelet, cacing.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/tawes.webp'),
  Species('lele', 'Lele', 'Clarias gariepinus', WaterType.tawar,
      'Kolam, parit, sungai. Aktif malam hari. Umpan: cacing, hati ayam.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/lele.webp'),
  Species('mas', 'Ikan Mas', 'Cyprinus carpio', WaterType.tawar,
      'Kolam dan danau. Umpan: pelet, jagung, adonan.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/mas.webp'),
  Species('patin', 'Patin', 'Pangasianodon hypophthalmus', WaterType.tawar,
      'Kolam pemancingan dan sungai besar.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/patin.webp'),
  Species('gabus', 'Gabus', 'Channa striata', WaterType.tawar,
      'Rawa, sungai, dan sawah. Pemangsa: anak ikan, katak.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/gabus.webp'),
  Species('toman', 'Toman', 'Channa micropeltes', WaterType.tawar,
      'Sungai besar dan waduk. Pemangsa, sering disambar lure.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/toman.webp'),
  Species('baung', 'Baung', 'Hemibagrus nemurus', WaterType.tawar,
      'Sungai berarus. Umpan: cacing, hati.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/baung.webp'),
  Species('nilem', 'Nilem', 'Osteochilus vittatus', WaterType.tawar,
      'Sungai dan kolam.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/nilem.webp'),
  Species('jelawat', 'Jelawat', 'Leptobarbus hoevenii', WaterType.tawar,
      'Sungai besar Sumatra dan Kalimantan; suka buah-buahan.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/jelawat.webp'),
  Species('betok', 'Betok', 'Anabas testudineus', WaterType.tawar,
      'Rawa dan parit.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/betok.webp'),
  Species('sepat-siam', 'Sepat Siam', 'Trichopodus pectoralis',
      WaterType.tawar, 'Rawa dan kolam.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/sepat-siam.webp'),
  Species('hampala', 'Hampala (Sebarau)', 'Hampala macrolepidota',
      WaterType.tawar, 'Sungai berarus. Sering dipancing dengan lure.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/hampala.webp'),
  Species('black-bass', 'Black Bass', 'Micropterus salmoides',
      WaterType.tawar, 'Spesies introduksi di beberapa waduk. Casting lure.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/black-bass.webp'),
  Species('sapu-sapu', 'Sapu-sapu', 'Pterygoplichthys pardalis',
      WaterType.tawar, 'Spesies invasif; sering tertangkap tidak sengaja.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/sapu-sapu.webp'),

  // ---- Air asin (termasuk payau/muara) ----
  Species('barramundi', 'Kakap Putih (Barramundi)', 'Lates calcarifer',
      WaterType.asin, 'Muara, mangrove, dan tambak. Casting lure atau umpan hidup.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/barramundi.webp'),
  Species('kakap-bakau', 'Kakap Bakau', 'Lutjanus argentimaculatus',
      WaterType.asin, 'Mangrove dan muara.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/kakap-bakau.webp'),
  Species('kakap-merah', 'Kakap Merah', 'Lutjanus malabaricus',
      WaterType.asin, 'Karang dan dasar laut. Umpan ikan hidup atau potongan.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/kakap-merah.webp'),
  Species('kerapu', 'Kerapu', 'Epinephelus spp.', WaterType.asin,
      'Karang dan bebatuan dasar.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/kerapu.webp'),
  Species('barakuda', 'Barakuda', 'Sphyraena barracuda', WaterType.asin,
      'Pemangsa cepat; gigi tajam, pakai leader.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/barakuda.webp'),
  Species('gt', 'Kuwe (GT)', 'Caranx ignobilis', WaterType.asin,
      'Popping, casting, dan jigging di sekitar karang.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/gt.webp'),
  Species('tenggiri', 'Tenggiri', 'Scomberomorus commerson', WaterType.asin,
      'Trolling dan casting; gigi tajam, pakai leader.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/tenggiri.webp'),
  Species('tongkol', 'Tongkol', 'Euthynnus affinis', WaterType.asin,
      'Perairan pantai dan lepas pantai.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/tongkol.webp'),
  Species('cakalang', 'Cakalang', 'Katsuwonus pelamis', WaterType.asin,
      'Perairan lepas pantai.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/cakalang.webp'),
  Species('tuna-sirip-kuning', 'Tuna Sirip Kuning', 'Thunnus albacares',
      WaterType.asin, 'Perairan dalam lepas pantai.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/tuna-sirip-kuning.webp'),
  Species('bawal-putih', 'Bawal Putih', 'Pampus argenteus', WaterType.asin,
      'Perairan pantai berlumpur.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/bawal-putih.webp'),
  Species('baronang', 'Baronang', 'Siganus spp.', WaterType.asin,
      'Padang lamun dan karang. Hati-hati, duri siripnya berbisa.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/baronang.webp'),
  Species('ekor-kuning', 'Ekor Kuning', 'Caesio cuning', WaterType.asin,
      'Karang; berkelompok.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/ekor-kuning.webp'),
  Species('kurisi', 'Kurisi', 'Nemipterus spp.', WaterType.asin,
      'Dasar laut berpasir.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/kurisi.webp'),
  Species('lencam', 'Lencam', 'Lethrinus spp.', WaterType.asin,
      'Karang and dasar berpasir.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/lencam.webp'),
  Species('kembung', 'Kembung', 'Rastrelliger kanagurta', WaterType.asin,
      'Perairan pantai; berkelompok.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/kembung.webp'),
  Species('bandeng', 'Bandeng', 'Chanos chanos', WaterType.asin,
      'Tambak dan muara.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/bandeng.webp'),
  Species('belanak', 'Belanak', 'Mugil cephalus', WaterType.asin,
      'Muara dan pantai. Umpan: roti, adonan.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/belanak.webp'),
  Species('senangin', 'Senangin', 'Eleutheronema tetradactylum',
      WaterType.asin, 'Muara dan pantai berlumpur.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/senangin.webp'),
  Species('sembilang', 'Sembilang', 'Plotosus canius', WaterType.asin,
      'Muara berlumpur. Hati-hati, patilnya berbisa.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/sembilang.webp'),
  Species('kerong-kerong', 'Kerong-kerong', 'Terapon jarbua', WaterType.asin,
      'Muara dan pantai.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/kerong-kerong.webp'),
  Species('pari', 'Pari', 'Dasyatidae', WaterType.asin,
      'Dasar laut dan muara. Sengatnya berbisa. Beberapa jenis pari dilindungi; lepaskan bila ragu.',
      thumbnailUrl:
          'https://hthvshvqzqozvqqzvqqz.supabase.co/storage/v1/object/public/species-index/thumb/pari.webp'),
];

Species? speciesById(String id) {
  for (final s in kDexSpecies) {
    if (s.id == id) return s;
  }
  return null;
}
