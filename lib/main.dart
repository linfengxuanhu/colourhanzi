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

    final int relatedLimit;
    switch (difficulty) {
      case '简单':
        relatedLimit = 0;
        break;
      case '困难':
        relatedLimit = (count * 0.5).round();
        break;
      default:
        relatedLimit = (count * 0.3).round();
    }

    for (final c in related) {
      if (result.length >= relatedLimit) break;

      if (chars.contains(c) &&
          c != targetChar &&
          !result.contains(c)) {
        result.add(c);
      }
    }

    for (final c in pool) {
      if (result.length >= count) break;

      if (!result.contains(c)) {
        result.add(c);
      }
    }

    return result.take(count).toList();
  }

  Future<void> generate() async {
    if (generating || chars.isEmpty) return;

    setState(() {
      generating = true;
    });

    try {
      syncTarget();

      // 圆圈总数固定为22个。
      // 目标字在圆圈内重复出现，同时页面中央单独展示一个无圆圈的大字。
      const int circleCount = 22;
      final int targetCount = repeat.clamp(3, 8);

      final distractors =
          makeDistractors(target, circleCount - targetCount);

      final List<String> circleChars = [
        ...List.filled(targetCount, target),
        ...distractors,
      ];

      circleChars.shuffle(random);

      final bytes = await renderPage(
        target,
        circleChars,
        pageNo,
      );

      if (!mounted) return;

      setState(() {
        image = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          generating = false;
        });
      }
    }
  }

  Future<Uint8List> renderPage(
    String targetChar,
    List<String> circleChars,
    int page,
  ) async {
    // A4纵向比例，1240×1754像素。
    const double w = 1240;
    const double h = 1754;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()..color = Colors.white,
    );

    // 绘制文字。
    void drawText(
      String value,
      Offset position,
      double fontSize, {
      bool bold = false,
      double width = 1000,
      TextAlign align = TextAlign.center,
    }) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          textAlign: align,
          maxLines: 2,
        ),
      )
        ..pushStyle(
          ui.TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'sans-serif',
          ),
        )
        ..addText(value);

      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: width));

      canvas.drawParagraph(paragraph, position);
    }

    // 标题区域。
    drawText(
      '幼儿识字启蒙',
      const Offset(120, 65),
      46,
      bold: true,
    );

    drawText(
      '找出“$targetChar”并涂色',
      const Offset(120, 125),
      32,
    );

    drawText(
      '第 $page 页',
      const Offset(970, 78),
      23,
      align: TextAlign.right,
    );

    // 中央目标字：不画圆圈。
    // 位置略偏页面中心上方，给周围圆圈留出视觉空间。
    const center = Offset(w / 2, 875);

    final targetBuilder = ui.ParagraphBuilder(
      const ui.ParagraphStyle(
        fontSize: 190,
        textAlign: TextAlign.center,
      ),
    )
      ..pushStyle(
        const ui.TextStyle(
          fontSize: 190,
          color: Colors.black,
          fontFamily: 'sans-serif',
        ),
      )
      ..addText(targetChar);

    final targetParagraph = targetBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 300));

    canvas.drawParagraph(
      targetParagraph,
      Offset(center.dx - 150, center.dy - 100),
    );

    // 22个圆圈错落排列，环绕中央目标字。
    // 采用固定的安全位置，再随机分配汉字，避免圆圈彼此重叠。
    final List<Offset> positions = [
      const Offset(300, 440),
      const Offset(620, 440),
      const Offset(940, 440),

      const Offset(170, 580),
      const Offset(420, 580),
      const Offset(820, 580),
      const Offset(1070, 580),

      const Offset(130, 720),
      const Offset(350, 720),
      const Offset(890, 720),
      const Offset(1110, 720),

      const Offset(170, 1040),
      const Offset(420, 1040),
      const Offset(820, 1040),
      const Offset(1070, 1040),

      const Offset(300, 1180),
      const Offset(560, 1180),
      const Offset(820, 1180),
      const Offset(1040, 1180),

      const Offset(240, 1330),
      const Offset(620, 1330),
      const Offset(1000, 1330),
    ];

    // 轻微随机化位置，使每次练习不完全相同。
    // 只在安全范围内移动，防止圆圈挤到页面边缘。
    final shuffledPositions = List<Offset>.from(positions)
      ..shuffle(random);

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.black;

    final double radius = 53;

    for (int i = 0;
        i < min(circleChars.length, shuffledPositions.length);
        i++) {
      final p = shuffledPositions[i];
      final dx = (random.nextDouble() - 0.5) * 12;
      final dy = (random.nextDouble() - 0.5) * 12;
      final point = Offset(p.dx + dx, p.dy + dy);

      canvas.drawCircle(point, radius, circlePaint);

      final charBuilder = ui.ParagraphBuilder(
        const ui.ParagraphStyle(
          fontSize: 52,
          textAlign: TextAlign.center,
        ),
      )
        ..pushStyle(
          const ui.TextStyle(
            fontSize: 52,
            color: Colors.black,
            fontFamily: 'sans-serif',
          ),
        )
        ..addText(circleChars[i]);

      final charParagraph = charBuilder.build()
        ..layout(
          const ui.ParagraphConstraints(width: 106),
        );

      canvas.drawParagraph(
        charParagraph,
        Offset(point.dx - 53, point.dy - 31),
      );
    }

    // 页脚提示。
    drawText(
      '提示：认真观察每一个字，找到相同的字后涂色。',
      const Offset(120, 1650),
      25,
      width: 1000,
      align: TextAlign.left,
    );

    final picture = recorder.endRecording();

    final img = await picture.toImage(
      w.toInt(),
      h.toInt(),
    );

    final data = await img.toByteData(
      format: ui.ImageByteFormat.png,
    );

    img.dispose();
    picture.dispose();

    if (data == null) {
      throw Exception('图片数据生成失败');
    }

    return data.buffer.asUint8List();
  }

  Future<void> shareImage() async {
    if (image == null) return;

    try {
      final dir = await getTemporaryDirectory();

      final file = File(
        '${dir.path}/汉字找字_${pageNo.toString().padLeft(3, '0')}.png',
      );

      await file.writeAsBytes(image!, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '汉字找字涂色练习',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    }
  }

  void changeSemester(String value) {
    setState(() {
      semester = value;
      syncTarget();
      image = null;
    });
  }

  void changeType(String value) {
    setState(() {
      type = value;
      syncTarget();
      image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableChars = chars;

    return Scaffold(
      appBar: AppBar(
        title: const Text('汉字找字 · 最终优化版'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: semester,
                    decoration: const InputDecoration(
                      labelText: '教材范围',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '全年',
                        child: Text('一年级全年（上册+下册）'),
                      ),
                      DropdownMenuItem(
                        value: '上册',
                        child: Text('一年级上册（2024统编新版）'),
                      ),
                      DropdownMenuItem(
                        value: '下册',
                        child: Text('一年级下册（2024统编新版）'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) changeSemester(value);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: '字表类型',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '会认',
                        child: Text('会认字'),
                      ),
                      DropdownMenuItem(
                        value: '会写',
                        child: Text('会写字'),
                      ),
                      DropdownMenuItem(
                        value: '全部',
                        child: Text('全部一年级字'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) changeType(value);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: availableChars.contains(target)
                        ? target
                        : (availableChars.isNotEmpty
                            ? availableChars.first
                            : null),
                    decoration: const InputDecoration(
                      labelText: '目标汉字',
                    ),
                    items: availableChars
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        target = value;
                        image = null;
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    decoration: const InputDecoration(
                      labelText: '练习难度',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: '简单',
                        child: Text('简单：普通干扰字为主'),
                      ),
                      DropdownMenuItem(
                        value: '普通',
                        child: Text('普通：加入部分形近字'),
                      ),
                      DropdownMenuItem(
                        value: '困难',
                        child: Text('困难：提高易混字比例'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        difficulty = value;
                        image = null;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('目标字出现次数'),
                      Expanded(
                        child: Slider(
                          value: repeat.toDouble(),
                          min: 3,
                          max: 8,
                          divisions: 5,
                          label: '$repeat',
                          onChanged: (value) {
                            setState(() {
                              repeat = value.round();
                              image = null;
                            });
                          },
                        ),
                      ),
                      Text('$repeat 次'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: generating ? null : generate,
                  icon: generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(generating ? '生成中…' : '生成练习页'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: image == null ? null : shareImage,
                  icon: const Icon(Icons.share),
                  label: const Text('分享/打印'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (image != null)
            Card(
              clipBehavior: Clip.antiAlias,
              child: Image.memory(
                image!,
                fit: BoxFit.contain,
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            '版式特点：中央目标字无圆圈；周围汉字各自带圈；'
            '根据难度选择干扰字；黑白打印；A4纵向比例。',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
