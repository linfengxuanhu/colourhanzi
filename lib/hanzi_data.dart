class HanziItem {
  final String char;
  final String semester;
  final String type;
  final int order;
  const HanziItem(this.char, this.semester, this.type, this.order);
}

// 2024统编新版：一年级上册识字表280字。
const String upperRecognize = '天地人你我他一二三四五上下口耳目手足站坐日月山川水火田禾六七八九十爸妈大马路土本学校班级姓名王哥弟画花打棋积木字词句子桌纸读书鱼鸭乌鸦午星期语文数写会白菜西瓜果小桥流柳开雪夜色美蓝云草原冰自行车晚昨今明个这去年秋气了树叶黄片从来飞江南可采莲戏间东西北的家鸡竹牙用几步没参加鸟说是春青蛙夏着皮地就冬男女人关正反先后内外对歌雨风虫清绿桃红力尖尘众双林森不条心金包尺作业笔刀宝贝少课早升国旗中们声起多么向立老师工厂医院生门卫船弯儿两头在里看见闪影前常黑狗左右它好朋友件有和做也办到又才能爷奶叔姐妹比尾巴谁长短把伞兔最公喝只处找许石出法放进高点彩半空问回答方久更牛羊爪旦拼音';

// 2024统编新版：一年级下册识字表410字。
const String lowerRecognize = '霜吹落降飘游池入姓氏李张弓古胡吴言孙河晴眼睛保护苗吃事情请让猜边凉喜欢时怕攻令感动万无识组计算减式图形卡合唱团热爱共产党太阳光怀抱幸福成井城村毛主席住乡亲战士想念告诉北京广走座安场非常壮观玩得急直哭跟忽然听喊快己背只很孤单种每都邻居叫招呼乐怎独跳绳当还羽球劲轮排母页止斤寸丁千全元静思床疑举望低故胆敢勇讲窗乱拉样笑再睡觉端粽节总煮盼米枣甜分鲜肉了册支台电视部机衣裤被物捉迷藏造蚂蚁运食粮房结网圆严寒酷暑暖晨细朝霞夕杨香操拔拍跑踢玲真闹丢沙身体之初相近习远教道专幼玉知义饭饱茶泡轻穿袍鞭炮诗首偷浮萍泉惜照柔荷露角浪迈悄泪次给壳虾装像淘娃珠摇篮亮晶停坪展透翅膀朵要腰阴沉呀忙呢吗面空闷吧消息棍豆汤蚊扇椅牵织斗具铅新平盒些此仔检查所伙伴钟迟灯等啊决定已经位表虎熊通注意遍百为因舍理第猴块结兴掰扛往棵满扔摘捧追刷梳巾皂洗澡脸盆棉姑娘病她治燕帮害别干惊奇咕咚熟掉湖吓啦鹿象野拦哪那领壁借咬难爬您拨赶摆过孩转吵现顶胖票户交父';

// 会写字表：按2024新版教材整理。
const String upperWrite = '一二三上口耳目手日火田禾六七八十九王午下去年了子大人可叶东西竹马牙用几四小鸟是天女开关先云雨虫山水力男土木心尺本刀不少中五风立正工厂门卫月儿头里见在我左右和也又才爸妈比巴长公只个多石出来半你有牛羊果白';
const String lowerWrite = '春冬吹花飞入什么古胡双言青清晴苗请生字红动万无明文卡片合共产党太阳光井主江住方后告的会北京广写认走河说让自己从好们叫他回快乐当书画毛止斤寸丁千元思床前地故乡色把讲样笑再节米间分吃肉册支电衣物造运欢房网对今雪细夕语打皮跑足沙包近习远学玉义饱抱首池采尖角早玩眼泪它贝气机台唱伞朵美这看鱼面问加豆斗笔知道放平安灯车站课坐老师国都百听时点林高兴着往瓜兔进巾洗她空还干身星久吓为怕家象没到向边行草赶过找页户交父';

List<HanziItem> buildItems() {
  final items = <HanziItem>[];
  var i = 0;
  for (final c in upperRecognize.runes.map(String.fromCharCode).toSet()) {
    items.add(HanziItem(c, '上册', '会认', i++));
  }
  i = 0;
  for (final c in upperWrite.runes.map(String.fromCharCode)) {
    items.add(HanziItem(c, '上册', '会写', i++));
  }
  i = 0;
  for (final c in lowerRecognize.runes.map(String.fromCharCode).toSet()) {
    items.add(HanziItem(c, '下册', '会认', i++));
  }
  i = 0;
  for (final c in lowerWrite.runes.map(String.fromCharCode)) {
    items.add(HanziItem(c, '下册', '会写', i++));
  }
  return items;
}
