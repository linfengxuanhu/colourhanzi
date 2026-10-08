import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'hanzi_data.dart';

void main() => runApp(const HanziColorApp());

class HanziColorApp extends StatelessWidget {
  const HanziColorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '汉字找字涂色',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final all = buildItems();
  final random = Random();
  String semester = '全年';
  String type = '会认';
  String difficulty = '普通';
  int repeat = 5;
  String target = '人';
  Uint8List? image;
  int pageNo = 1;

  List<String> get chars {
    Iterable<HanziItem> x = all;
    if (semester != '全年') x = x.where((e) => e.semester == semester);
    if (type != '全部') x = x.where((e) => e.type == type);
    return x.map((e) => e.char).toSet().toList();
  }

  @override
  void initState() {
    super.initState();
    target = chars.contains(target) ? target : chars.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => generate());
  }

  void _syncTarget() {
    if (!chars.contains(target) && chars.isNotEmpty) target = chars.first;
  }

  List<String> distractors(String t, int count) {
    final pool = chars.where((c) => c != t).toList()..shuffle(random);
    final related = <String>{
      '人': '入大个天夫从众'.split(''),
      '入': '人八大'.split(''),
      '口': '日目田回中'.split(''),
      '日': '目曰白田旧口'.split(''),
      '目': '日自且口'.split(''),
      '木': '本禾林森术'.split(''),
      '本': '木禾末未'.split(''),
      '大': '天太夫人个'.split(''),
      '天': '大夫太'.split(''),
      '土': '士王工'.split(''),
      '王': '土玉三'.split(''),
      '田': '日目由甲电'.split(''),
      '白': '日自百'.split(''),
      '目': '日自口'.split(''),
      '手': '毛才'.split(''),
      '牛': '午生'.split(''),
      '午': '牛干'.split(''),
      '了': '子予'.split(''),
      '子': '了孑'.split(''),
      '问': '间门同'.split(''),
      '间': '问门闪'.split(''),
      '晴': '睛清情请'.split(''),
      '睛': '晴情清请'.split(''),
      '清': '晴情请青'.split(''),
      '情': '晴清请'.split(''),
      '请': '晴清情'.split(''),
      '他': '她地池'.split(''),
      '她': '他地池'.split(''),
      '江': '河池海'.split(''),
      '河': '江池海'.split(''),
      '看': '着着'.split(''),
      '左': '右在'.split(''),
      '右': '左石'.split(''),
      '前': '后'.split(''),
      '后': '前'.split(''),
    }[t] ?? const [];

    final result = <String>[];
    if (difficulty != '简单') {
      for (final c in related) {
        if (chars.contains(c) && c != t && !result.contains(c)) result.add(c);
      }
    }
    if (difficulty == '困难') {
      for (final c in related.reversed) {
        if (chars.contains(c) && c != t && !result.contains(c)) result.add(c);
      }
    }
    for (final c in pool) {
      if (!result.contains(c)) result.add(c);
      if (result.length >= count) break;
    }
    return result.take(count).toList();
  }

  Future<void> generate() async {
    _syncTarget();
    if (chars.isEmpty) return;
    final count = 22;
    final distract = distractors(target, count - 1);
    final allChars = <String>[];
    final targetCount = repeat.clamp(3, 9);
    allChars.addAll(List.filled(targetCount, target));
    allChars.addAll(distract.take(count - targetCount));
    allChars.shuffle(random);
    final bytes = await renderPage(target, allChars, pageNo);
    setState(() => image = bytes);
  }

  Future<Uint8List> renderPage(String target, List<String> chars, int page) async {
    const w = 1240.0;
    const h = 1754.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), bg);

    void text(String s, Offset p, double size, {bool bold = false, TextAlign align = TextAlign.center}) {
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        textAlign: align,
      ))..pushStyle(ui.TextStyle(color: Colors.black, fontSize: size, fontFamily: 'sans-serif'))..addText(s);
      final para = pb.build()..layout(ui.ParagraphConstraints(width: 1000));
      canvas.drawParagraph(para, p);
    }

    text('幼儿识字启蒙', const Offset(120, 75), 44, bold: true);
    text('找出“$target”并涂色', const Offset(120, 135), 34);
    text('第 $page 页', const Offset(980, 85), 24, align: TextAlign.right);

    final center = const Offset(w / 2, 500);
    final circle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.black;
    canvas.drawCircle(center, 150, circle);
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 190, textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: 190, color: Colors.black, fontFamily: 'sans-serif'))
      ..addText(target);
    final para = pb.build()..layout(const ui.ParagraphConstraints(width: 300));
    canvas.drawParagraph(para, Offset(center.dx - 150, center.dy - 105));

    final positions = <Offset>[];
    final areas = [
      Rect.fromLTWH(90, 720, 1060, 900),
    ];
    int guard = 0;
    while (positions.length < chars.length && guard++ < 10000) {
      final x = 145 + random.nextDouble() * 950;
      final y = 770 + random.nextDouble() * 760;
      final p = Offset(x, y);
      if (!areas[0].contains(p)) continue;
      if (positions.every((q) => (q - p).distance > 150)) positions.add(p);
    }
    while (positions.length < chars.length) {
      positions.add(Offset(150 + (positions.length % 8) * 135, 780 + (positions.length ~/ 8) * 170));
    }

    for (var i = 0; i < chars.length; i++) {
      final p = positions[i];
      canvas.drawCircle(p, 53, circle);
      final q = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 52, textAlign: TextAlign.center))
        ..pushStyle(ui.TextStyle(fontSize: 52, color: Colors.black, fontFamily: 'sans-serif'))
        ..addText(chars[i]);
      final qp = q.build()..layout(const ui.ParagraphConstraints(width: 106));
      canvas.drawParagraph(qp, Offset(p.dx - 53, p.dy - 31));
    }

    text('提示：认真观察每一个字，找到相同的字后涂色。', const Offset(120, 1650), 25, align: TextAlign.left);
    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> shareImage() async {
    if (image == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/汉字找字_${pageNo.toString().padLeft(3, '0')}.png');
    await file.writeAsBytes(image!);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: '汉字找字涂色练习'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('汉字找字 · 第二版')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          DropdownButtonFormField<String>(value: semester, decoration: const InputDecoration(labelText: '教材范围'), items: const [
            DropdownMenuItem(value: '全年', child: Text('一年级全年（上册+下册）')),
            DropdownMenuItem(value: '上册', child: Text('一年级上册（2024统编新版）')),
            DropdownMenuItem(value: '下册', child: Text('一年级下册（2024统编新版）')),
          ], onChanged: (v) => setState(() { semester = v!; _syncTarget(); })),
          DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: '字表类型'), items: const [
            DropdownMenuItem(value: '会认', child: Text('会认字')),
            DropdownMenuItem(value: '会写', child: Text('会写字')),
            DropdownMenuItem(value: '全部', child: Text('全部一年级字')),
          ], onChanged: (v) => setState(() { type = v!; _syncTarget(); })),
          DropdownButtonFormField<String>(value: target, decoration: const InputDecoration(labelText: '目标汉字'), items: chars.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 24)))).toList(), onChanged: (v) => setState(() => target = v!)),
          DropdownButtonFormField<String>(value: difficulty, decoration: const InputDecoration(labelText: '难度'), items: const [
            DropdownMenuItem(value: '简单', child: Text('简单：普通干扰字')),
            DropdownMenuItem(value: '普通', child: Text('普通：加入形近字')),
            DropdownMenuItem(value: '困难', child: Text('困难：增加易混字比例')),
          ], onChanged: (v) => setState(() => difficulty = v!)),
          Row(children: [const Text('目标字出现次数'), Expanded(child: Slider(value: repeat.toDouble(), min: 3, max: 8, divisions: 5, label: '$repeat', onChanged: (v) => setState(() => repeat = v.round()))), Text('$repeat 次')]),
        ]))),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: FilledButton.icon(onPressed: generate, icon: const Icon(Icons.refresh), label: const Text('生成'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: image == null ? null : shareImage, icon: const Icon(Icons.share), label: const Text('分享/打印')))]),
        const SizedBox(height: 14),
        if (image != null) Card(clipBehavior: Clip.antiAlias, child: Image.memory(image!, fit: BoxFit.contain)),
        const SizedBox(height: 12),
        const Text('第二版内置：2024统编新版一年级上、下册识字表；会认/会写筛选；形近字干扰；随机排版；A4比例黑白打印图。', style: TextStyle(color: Colors.black54)),
      ]),
    );
  }
}
