/// 一个词条：来自 assets/data/words.json
class Word {
  final int id;
  final String w; // 单词
  final String pos; // 词性，可能多个，如 "n.,v."
  final String level; // B2 / C1
  final String ipa; // 英式/美式音标（美音）
  final String cn; // 中文释义，多义用「；」分隔
  final String note; // 词表原文的括注，如 long flat surface
  final String ex; // 例句英文，可能为空
  final String exCn; // 例句中文

  const Word({
    required this.id,
    required this.w,
    required this.pos,
    required this.level,
    required this.ipa,
    required this.cn,
    this.note = '',
    this.ex = '',
    this.exCn = '',
  });

  factory Word.fromJson(Map<String, dynamic> j) => Word(
        id: j['id'] as int,
        w: j['w'] as String? ?? '',
        pos: j['pos'] as String? ?? '',
        level: j['level'] as String? ?? '',
        ipa: j['ipa'] as String? ?? '',
        cn: j['cn'] as String? ?? '',
        note: j['note'] as String? ?? '',
        ex: j['ex'] as String? ?? '',
        exCn: j['exCn'] as String? ?? '',
      );

  /// 音标展示用（带斜杠），无音标时返回空串
  String get ipaText => ipa.isEmpty ? '' : '/$ipa/';

  /// 词性展示：n.,v. -> n. / v.
  String get posText => pos.replaceAll(',', ' / ');

  /// 是否有多条释义（用于详情页分行）
  List<String> get senses =>
      cn.split('；').where((s) => s.trim().isNotEmpty).toList();
}
