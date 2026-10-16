import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'hanzi_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HanziColorApp());
}

class HanziColorApp extends StatelessWidget {
  const HanziColorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF535D96);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '汉字找字涂色',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<HanziItem> all = buildItems();
  final Random random = Random();

  String semester = '全年';
  String type = '会认';
  String difficulty = '普通';
  int repeat = 5;
  String target = '二';

  Uint8List? image;
  int pageNo = 1;
  bool generating = false;

  List<String> get chars {
    Iterable<HanziItem> items = all;

    if (semester != '全年') {
      items = items.where((e) => e.semester == semester);
    }

    if (type != '全部') {
      items = items.where((e) => e.type == type);
    }

    return items.map((e) => e.char).toSet().toList();
  }

  @override
  void initState() {
    super.initState();

    if (!chars.contains(target) && chars.isNotEmpty) {
      target = chars.first;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => generate());
  }

  void syncTarget() {
    if (chars.isNotEmpty && !chars.contains(target)) {
      target = chars.first;
    }
  }

  // 形近字、易混字候选库。
  static const Map<String, List<String>> confusables = {
    '一': ['二', '三', '十', '土', '工', '干', '上', '下'],
    '二': ['一', '三', '十', '土', '工', '干', '云', '元', '王', '上', '下'],
    '三': ['二', '王', '丰', '干', '工', '土', '正'],
    '十': ['土', '干', '千', '士', '才', '上', '下', '二'],
    '土': ['士', '干', '工', '王', '上', '下', '十', '三'],
    '士': ['土', '干', '工', '王', '十'],
    '工': ['土', '王', '干', '上', '下', '正'],
    '干': ['千', '十', '土', '士', '于', '开'],
    '千': ['干', '十', '午', '牛', '于'],
    '人': ['入', '大', '个', '天', '夫', '从', '众'],
    '入': ['人', '八', '大', '个'],
    '八': ['人', '入', '个'],
    '个': ['人', '大', '介', '今'],
    '大': ['天', '太', '夫', '人', '个', '犬'],
    '天': ['大', '夫', '太', '无', '关'],
    '口': ['日', '目', '田', '回', '中', '曰'],
    '日': ['目', '曰', '白', '田', '旧', '口', '电'],
    '目': ['日', '自', '且', '口', '田'],
    '自': ['目', '白', '日', '且'],
    '木': ['本', '禾', '林', '森', '术', '米'],
    '本': ['木', '禾', '末', '未'],
    '末': ['未', '木', '本'],
    '未': ['末', '木', '本'],
    '田': ['日', '目', '由', '甲', '电', '口'],
    '白': ['日', '自', '百'],
    '王': ['玉', '土', '三', '主', '丰'],
    '玉': ['王', '主', '全'],
    '牛': ['午', '生', '手'],
    '午': ['牛', '干', '千'],
    '手': ['毛', '才', '牛'],
    '了': ['子', '予'],
    '子': ['了', '孑'],
    '问': ['间', '门', '同', '闪'],
    '间': ['问', '门', '闪', '阳'],
    '晴': ['睛', '清', '情', '请'],
    '睛': ['晴', '情', '清', '请'],
    '清': ['晴', '睛', '情', '请', '青'],
    '情': ['晴', '清', '请', '青'],
    '请': ['晴', '清', '情', '青'],
    '青': ['清', '晴', '情', '请'],
    '他': ['她', '地', '池'],
    '她': ['他', '地', '池'],
    '江': ['河', '池', '海'],
    '河': ['江', '池', '海'],
    '左': ['右', '在', '石'],
    '右': ['左', '石', '有'],
    '前': ['后', '剪'],
    '后': ['前', '石'],
  };

  // 按难度挑选干扰字。
  List<String> makeDistractors(String targetChar, int count) {
    if (count <= 0) return <String>[];

    final selected = chars;
    final complete = all.map((e) => e.char).toSet().toList();
    final result = <String>[];

    final int relatedLimit = switch (difficulty) {
      '简单' => 0,
      '困难' => (count * 0.5).round(),
      _ => (count * 0.3).round(),
    };

    for (final c in confusables[targetChar] ?? const <String>[]) {
      if (result.length >= relatedLimit) break;

      if (selected.contains(c) &&
          c != targetChar &&
          !result.contains(c)) {
        result.add(c);
      }
    }

    final pool = selected
        .where((c) => c != targetChar && !result.contains(c))
        .toList()
      ..shuffle(random);

    for (final c in pool) {
      if (result.length >= count) break;
      result.add(c);
    }

    if (result.length < count) {
      final fallback = complete
          .where((c) => c != targetChar && !result.contains(c))
          .toList()
        ..shuffle(random);

      for (final c in fallback) {
        if (result.length >= count) break;
        result.add(c);
      }
    }

    return result.take(count).toList();
  }

  Future<void> generate() async {
    if (generating || chars.isEmpty) return;

    setState(() => generating = true);

    try {
      syncTarget();

      const int circleCount = 24;
      final int targetCount = repeat.clamp(3, 8);

      final circleChars = <String>[
        ...List.filled(targetCount, target),
        ...makeDistractors(target, circleCount - targetCount),
      ];

      circleChars.shuffle(random);

      final bytes = await renderPage(target, circleChars, pageNo);

      if (!mounted) return;

      setState(() {
        image = bytes;
        pageNo++;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() => generating = false);
      }
    }
  }

  Future<Uint8List> renderPage(
    String targetChar,
    List<String> circleChars,
    int page,
  ) async {
    // A4纵向比例，约1240×1754像素。
    const double w = 1240;
    const double h = 1754;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white,
    );

    // 使用系统中文字体回退。
    // 如果需要严格的楷体效果，还需将真实字体文件加入项目。
    void drawText(
      String value,
      double centerX,
      double top,
      double fontSize, {
      bool bold = false,
      double maxWidth = 1000,
    }) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        )
        ..addText(value);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: maxWidth));

      canvas.drawParagraph(
        paragraph,
        Offset(centerX - maxWidth / 2, top),
      );
    }

    // 标题区域。
    drawText(
      '幼儿识字启蒙',
      w / 2,
      70,
    
