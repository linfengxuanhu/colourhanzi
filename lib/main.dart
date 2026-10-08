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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '汉字找字涂色',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
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

  // 根据教材范围和字表类型筛选汉字。
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      generate();
    });
  }

  void syncTarget() {
    if (chars.isNotEmpty && !chars.contains(target)) {
      target = chars.first;
    }
  }

  // 形近字、易混字候选库。
  // 程序会根据当前字库过滤，避免出现不在所选教材范围内的干扰字。
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
    '清': ['晴', '情', '请', '青'],
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

  // 先安排形近字，再用其他汉字补足。
  List<String> makeDistractors(String targetChar, int count) {
    final pool = chars
        .where((c) => c != targetChar)
        .toList()
      ..shuffle(random);

    final related = confusables[targetChar] ?? const <String>[];
    final result = <String>[];

    final
