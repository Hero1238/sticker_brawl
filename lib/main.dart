import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(StickerBrawlApp());

class StickerBrawlApp extends StatelessWidget {
  StickerBrawlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Стикер Бой',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: MainMenuScreen(),
    );
  }
}

class StickerCard {
  final String id, name, asset, abilityType;
  final int atk;
  final bool isVip;
  StickerCard({required this.id, required this.name, required this.asset, required this.atk, required this.abilityType, this.isVip = false});
}

final List<StickerCard> allStickers = [
  StickerCard(id: 's1', name: 'Похититель', asset: 'assets/stickers/s1.png', atk: 20, abilityType: 'heal'),
  StickerCard(id: 's2', name: 'Охотники', asset: 'assets/stickers/s2.png', atk: 15, abilityType: 'shield'),
  StickerCard(id: 's3', name: 'Владыка Мира', asset: 'assets/stickers/s3.png', atk: 24, abilityType: 'crit'),
  StickerCard(id: 's4', name: 'Магнус 6.17', asset: 'assets/stickers/s4.png', atk: 30, abilityType: 'fast'),
  StickerCard(id: 'vip1', name: 'Король Скелетов', asset: 'assets/stickers/vip1.png', atk: 34, abilityType: 'vip', isVip: true),
];

final List<String> validPromoCodes = ['KING777', 'VIP2026', 'SKELET1', 'BRAWL99', 'MEGA888', 'HERO100', 'BOSS555', 'ALMAZ77', 'STEVE99', 'MAGNUS6'];

class GameConfig {
  static bool isOnline = false;
  static bool isHost = true;
  static String roomCode = '';
  static bool vipUnlocked = false;
  static int wins = 0;
}

class MainMenuScreen extends StatefulWidget {
  MainMenuScreen({super.key});
  @override
  State createState() => MainMenuState();
}

class MainMenuState extends State {
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      GameConfig.vipUnlocked = prefs.getBool('vip_unlocked') ?? false;
      GameConfig.wins = prefs.getInt('wins') ?? 0;
    });
  }

  void showOnlineDialog() {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Онлайн-битва с другом', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                GameConfig.isOnline = true;
                GameConfig.isHost = true;
                GameConfig.roomCode = (1000 + Random().nextInt(9000)).toString();
                Navigator.push(context, MaterialPageRoute(builder: (c) => BattleScreen())).then((v) => loadData());
              },
              icon: Icon(Icons.add_circle_outline),
              label: Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Создать комнату', style: TextStyle(fontSize: 16))),
            ),
            SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
              decoration: InputDecoration(hintText: '0000', labelText: 'Код комнаты друга', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
            ),
            SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                if (codeCtrl.text.length == 4) {
                  Navigator.pop(ctx);
                  GameConfig.isOnline = true;
                  GameConfig.isHost = false;
                  GameConfig.roomCode = codeCtrl.text;
                  Navigator.push(context, MaterialPageRoute(builder: (c) => BattleScreen())).then((v) => loadData());
                }
              },
              icon: Icon(Icons.login),
              label: Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Войти по коду', style: TextStyle(fontSize: 16))),
            ),
          ],
        ),
      ),
    );
  }

  void showVipShop() {
    final promoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/stickers/vip1.png', height: 130, width: 130, fit: BoxFit.cover)),
            SizedBox(height: 12),
            Text('VIP: Король Скелетов', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Супер-карта с 34 ATK, лечением и двойным уроном!', textAlign: TextAlign.center),
            SizedBox(height: 16),
            if (GameConfig.vipUnlocked)
              Text('VIP-пак уже активирован!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
            else ...[
              TextField(
                controller: promoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'Введи промокод из ТГК', border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (validPromoCodes.contains(promoCtrl.text.trim().toUpperCase())) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('vip_unlocked', true);
                      setState(() => GameConfig.vipUnlocked = true);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Король Скелетов разблокирован!')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Неверный промокод! Ищи код в ТГК')));
                    }
                  },
                  child: Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Активировать код')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(avatar: Icon(Icons.emoji_events, size: 18), label: Text('Побед: ${GameConfig.wins}')),
                  FilledButton.tonalIcon(onPressed: showVipShop, icon: Icon(GameConfig.vipUnlocked ? Icons.verified : Icons.lock_open), label: Text(GameConfig.vipUnlocked ? 'VIP Активен' : 'VIP Пак')),
                ],
              ),
              Spacer(),
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(32)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/stickers/s1.png', height: 140, width: 140, fit: BoxFit.cover)),
                ),
              ),
              SizedBox(height: 20),
              Text('СТИКЕР БОЙ', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colors.primary)),
              SizedBox(height: 8),
              Text('Выбирай мемы и сокрушай соперников', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
              Spacer(),
              FilledButton.icon(
                onPressed: showOnlineDialog,
                icon: Icon(Icons.wifi_tethering),
                label: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Играть с другом (Онлайн)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
              ),
              SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  GameConfig.isOnline = false;
                  Navigator.push(context, MaterialPageRoute(builder: (c) => BattleScreen())).then((v) => loadData());
                },

icon: Icon(Icons.smart_toy_outlined),
label: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Тренировка с ботом', style: TextStyle(fontSize: 17))),
),
],
),
),
),
);
}
}
class BattleScreen extends StatefulWidget {
BattleScreen({super.key});
@override
State createState() => BattleState();
}
class BattleState extends State {
int myHp = 120, enemyHp = 120;
bool myTurn = true, opponentConnected = false;
String statusText = 'Выбери стикер для атаки!';
StickerCard? lastCard;
MqttServerClient? client;
late List myDeck;
@override
void initState() {
super.initState();
myDeck = allStickers.where((s) => !s.isVip || GameConfig.vipUnlocked).toList();
if (!GameConfig.isOnline) {
opponentConnected = true;
} else {
myTurn = GameConfig.isHost;
statusText = GameConfig.isHost ? 'Код комнаты: ${GameConfig.roomCode}. Ждём друга...' : 'Подключаемся к комнате ${GameConfig.roomCode}...';
connectMqtt();
}
}
Future connectMqtt() async {
client = MqttServerClient('broker.emqx.io', 'sb_${Random().nextInt(999999)}')..port = 1883..keepAlivePeriod = 20..logging(on: false);
try {
await client!.connect();
client!.subscribe('sticker_brawl_ru/room/${GameConfig.roomCode}', MqttQos.atLeastOnce);
client!.updates!.listen((c) {
final msg = c.first.payload as MqttPublishMessage;
handleNet(jsonDecode(MqttPublishPayload.bytesToStringAsString(msg.payload.message)));
});
if (!GameConfig.isHost) {
sendMsg({'type': 'join'});
setState(() { opponentConnected = true; statusText = 'Друг найден! Ждём его ход...'; });
}
} catch (e) {
if (mounted) setState(() => statusText = 'Ошибка сети. Проверь интернет!');
}
}
void sendMsg(Map data) {
if (client?.connectionStatus?.state != MqttConnectionState.connected) return;
data['sender'] = GameConfig.isHost ? 'host' : 'guest';
final b = MqttClientPayloadBuilder()..addString(jsonEncode(data));
client!.publishMessage('sticker_brawl_ru/room/${GameConfig.roomCode}', MqttQos.atLeastOnce, b.payload!);
}
void handleNet(Map data) {
if (data['sender'] == (GameConfig.isHost ? 'host' : 'guest')) return;
if (data['type'] == 'join' && GameConfig.isHost) {
setState(() { opponentConnected = true; statusText = 'Друг зашёл! Твой ход!'; });
} else if (data['type'] == 'attack') {
final card = allStickers.firstWhere((s) => s.id == data['cardId'], orElse: () => allStickers.first);
HapticFeedback.heavyImpact();
setState(() {
lastCard = card;
myHp = max(0, myHp - (data['damage'] as int));
enemyHp = min(150, enemyHp + (data['heal'] as int));
myTurn = true;
statusText = 'Враг ударил «${card.name}» (-${data['damage']} HP)! Твой ход!';
});
checkWin();
}
}
void playCard(StickerCard card) {
if (!opponentConnected || !myTurn || myHp <= 0 || enemyHp <= 0) return;
HapticFeedback.mediumImpact();
int dmg = card.atk + (card.abilityType == 'crit' && Random().nextBool() ? 10 : 0) + (card.abilityType == 'vip' ? 12 : 0);
int heal = card.abilityType == 'heal' ? 6 : (card.abilityType == 'shield' ? 8 : (card.abilityType == 'vip' ? 8 : 0));
setState(() {
lastCard = card;
enemyHp = max(0, enemyHp - dmg);
myHp = min(150, myHp + heal);
myTurn = false;
statusText = 'Ты ударил «${card.name}» (-$dmg HP)! Ход соперника...';
});
if (GameConfig.isOnline) sendMsg({'type': 'attack', 'cardId': card.id, 'damage': dmg, 'heal': heal});
if (checkWin() || GameConfig.isOnline) return;
Future.delayed(Duration(milliseconds: 1000), () {
if (!mounted || enemyHp <= 0) return;
final bot = allStickers[Random().nextInt(4)];
HapticFeedback.heavyImpact();
setState(() { lastCard = bot; myHp = max(0, myHp - bot.atk); myTurn = true; statusText = 'Бот ответил «${bot.name}» (-${bot.atk} HP)! Твой ход!'; });
checkWin();
});
}
bool checkWin() {
if (enemyHp > 0 && myHp > 0) return false;
final won = enemyHp <= 0;
if (won) SharedPreferences.getInstance().then((p) => p.setInt('wins', (p.getInt('wins') ?? 0) + 1));
showDialog(
context: context,
barrierDismissible: false,
builder: (ctx) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
title: Text(won ? 'Победа!' : 'Поражение', textAlign: TextAlign.center),
content: Text(won ? 'Ты сокрушил соперника!' : 'Попробуй ещё раз!', textAlign: TextAlign.center),
actionsAlignment: MainAxisAlignment.center,
actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: Text('В меню'))],
),
);
return true;
}
@override
void dispose() { client?.disconnect(); super.dispose(); }
@override
Widget build(BuildContext context) {
final colors = Theme.of(context).colorScheme;
return Scaffold(
appBar: AppBar(title: Text(GameConfig.isOnline ? 'Комната: ${GameConfig.roomCode}' : 'Бой с ботом'), centerTitle: true),
body: SafeArea(
child: Padding(
padding: EdgeInsets.all(16),
child: Column(
children: [
Card(
elevation: 0,
color: colors.errorContainer.withOpacity(0.5),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
child: Padding(
padding: EdgeInsets.all(14),
child: Column(children: [
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Соперник', style: TextStyle(fontWeight: FontWeight.bold)), Text('$enemyHp HP', style: TextStyle(fontWeight: FontWeight.w900))]),
SizedBox(height: 6),
ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: enemyHp / 120, minHeight: 10, color: colors.error)),
]),
),
),
Spacer(),
if (lastCard != null) Column(children: [
ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset(lastCard!.asset, height: 140, width: 140, fit: BoxFit.cover)),
SizedBox(height: 6),
Text(lastCard!.name, style: TextStyle(fontWeight: FontWeight.bold)),
]) else Container(height: 140, width: 140, decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(28)), child: Icon(Icons.flash_on, size: 48)),
SizedBox(height: 12),
Container(
padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(20)),
child: Text(statusText, textAlign: TextAlign.center, style: TextStyle(color: colors.onSecondaryContainer, fontWeight: FontWeight.w600)),
),
Spacer(),
Card(
elevation: 0,
color: colors.primaryContainer.withOpacity(0.5),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
child: Padding(
padding: EdgeInsets.all(14),
child: Column(children: [
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Твоё здоровье', style: TextStyle(fontWeight: FontWeight.bold)), Text('$myHp HP', style: TextStyle(fontWeight: FontWeight.w900))]),
SizedBox(height: 6),
ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: myHp / 120, minHeight: 10, color: colors.primary)),
]),
),
),
SizedBox(height: 12),
SizedBox(
height: 160,
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: myDeck.length,
itemBuilder: (ctx, idx) {
final StickerCard c = myDeck[idx];
return Padding(
padding: EdgeInsets.only(right: 10),
child: GestureDetector(
onTap: () => playCard(c),
child: AnimatedOpacity(
duration: Duration(milliseconds: 200),
opacity: (myTurn && opponentConnected) ? 1.0 : 0.45,
child: Container(
width: 120,
padding: EdgeInsets.all(8),
decoration: BoxDecoration(
color: c.isVip ? colors.tertiaryContainer : colors.surfaceContainerHigh,
borderRadius: BorderRadius.circular(24),
border: Border.all(color: c.isVip ? colors.tertiary : colors.outlineVariant, width: c.isVip ? 2 : 1),
),
child: Column(children: [
Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(c.asset, width: double.infinity, fit: BoxFit.cover))),
SizedBox(height: 6),
Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
Text('⚔️ ${c.atk} ATK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: colors.primary)),
]),
),
),
),
);
},
),
),
],
),
),
),
);
}
}
