import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const StickerBrawlApp());

class StickerBrawlApp extends StatelessWidget {
  const StickerBrawlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Стикер Бой',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple, brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const MainMenuScreen(),
    );
  }
}

class StickerCard {
  final String id, name, asset, abilityType;
  final int atk;
  final bool isVip;
  const StickerCard({required this.id, required this.name, required this.asset, required this.atk, required this.abilityType, this.isVip = false});
}

const List<StickerCard> allStickers = [
  StickerCard(id: 's1', name: 'Похититель', asset: 'assets/stickers/s1.png', atk: 20, abilityType: 'heal'),
  StickerCard(id: 's2', name: 'Охотники', asset: 'assets/stickers/s2.png', atk: 15, abilityType: 'shield'),
  StickerCard(id: 's3', name: 'Владыка Мира', asset: 'assets/stickers/s3.png', atk: 24, abilityType: 'crit'),
  StickerCard(id: 's4', name: 'Магнус 6.17', asset: 'assets/stickers/s4.png', atk: 30, abilityType: 'fast'),
  StickerCard(id: 'vip1', name: 'Король Скелетов', asset: 'assets/stickers/vip1.png', atk: 34, abilityType: 'vip', isVip: true),
];

const List<String> validPromoCodes = ['KING777', 'VIP2026', 'SKELET1', 'BRAWL99', 'MEGA888', 'HERO100', 'BOSS555', 'ALMAZ77', 'STEVE99', 'MAGNUS6'];

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool vipUnlocked = false;
  int wins = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vipUnlocked = prefs.getBool('vip_unlocked') ?? false;
      wins = prefs.getInt('wins') ?? 0;
    });
  }

  void _showOnlineDialog() {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Онлайн-битва с другом', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                final code = (1000 + Random().nextInt(9000)).toString();
                Navigator.push(context, MaterialPageRoute(builder: (_) => BattleScreen(isOnline: true, isHost: true, roomCode: code, vipUnlocked: vipUnlocked, onWin: _loadData)));
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Создать комнату', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.bold),
              decoration: InputDecoration(hintText: '0000', labelText: 'Код комнаты друга', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                if (codeCtrl.text.length == 4) {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BattleScreen(isOnline: true, isHost: false, roomCode: codeCtrl.text, vipUnlocked: vipUnlocked, onWin: _loadData)));
                }
              },
              icon: const Icon(Icons.login),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Войти по коду', style: TextStyle(fontSize: 16))),
            ),
          ],
        ),
      ),
    );
  }

  void _showVipShop() {
    final promoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/stickers/vip1.png', height: 130, width: 130, fit: BoxFit.cover)),
            const SizedBox(height: 12),
            Text('VIP: Король Скелетов', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Супер-карта с 34 ATK, лечением и двойным уроном!', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (vipUnlocked)
              const Text('VIP-пак уже активирован!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
            else ...[
              TextField(
                controller: promoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: 'Введи промокод из ТГК', border: OutlineInputBorder(borderRadius: BorderRadius.circular(18))),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (validPromoCodes.contains(promoCtrl.text.trim().toUpperCase())) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('vip_unlocked', true);
                      setState(() => vipUnlocked = true);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Король Скелетов разблокирован!')));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Неверный промокод! Ищи код в ТГК')));
                    }
                  },
                  child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Активировать код')),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(avatar: const Icon(Icons.emoji_events, size: 18), label: Text('Побед: $wins')),
                  FilledButton.tonalIcon(onPressed: _showVipShop, icon: Icon(vipUnlocked ? Icons.verified : Icons.lock_open), label: Text(vipUnlocked ? 'VIP Активен' : 'VIP Пак')),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(32)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/stickers/s1.png', height: 140, width: 140, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 20),
              Text('СТИКЕР БОЙ', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: colors.primary)),
              const SizedBox(height: 8),
              Text('Выбирай мемы и сокрушай соперников', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _showOnlineDialog,
                icon: const Icon(Icons.wifi_tethering),
                label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Играть с другом (Онлайн)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BattleScreen(isOnline: false, isHost: true, roomCode: '', vipUnlocked: vipUnlocked, onWin: _loadData))),
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Тренировка с ботом', style: TextStyle(fontSize: 17))),
),
],
),
),
),
);
}
}
class BattleScreen extends StatefulWidget {
final bool isOnline, isHost, vipUnlocked;
final String roomCode;
final VoidCallback onWin;
const BattleScreen({super.key, required this.isOnline, required this.isHost, required this.roomCode, required this.vipUnlocked, required this.onWin});
@override
State createState() => _BattleScreenState();
}
class _BattleScreenState extends State {
int myHp = 120, enemyHp = 120;
bool myTurn = true, opponentConnected = false;
String statusText = 'Выбери стикер для атаки!';
StickerCard? lastCard;
MqttServerClient? client;
late List myDeck;
@override
void initState() {
super.initState();
myDeck = allStickers.where((s) => !s.isVip || widget.vipUnlocked).toList();
if (!widget.isOnline) {
opponentConnected = true;
} else {
myTurn = widget.isHost;
statusText = widget.isHost ? 'Код комнаты: ${widget.roomCode}. Ждём друга...' : 'Подключаемся к комнате ${widget.roomCode}...';
_connectMqtt();
}
}
Future connectMqtt() async {
client = MqttServerClient('broker.emqx.io', 'sb${Random().nextInt(999999)}')..port = 1883..keepAlivePeriod = 20..logging(on: false);
try {
await client!.connect();
client!.subscribe('sticker_brawl_ru/room/${widget.roomCode}', MqttQos.atLeastOnce);
client!.updates!.listen((c) {
final msg = c[0].payload as MqttPublishMessage;
_handleNet(jsonDecode(MqttPublishPayload.bytesToStringAsString(msg.payload.message)));
});
if (!widget.isHost) {
send({'type': 'join'});
setState(() { opponentConnected = true; statusText = 'Друг найден! Ждём его ход...'; });
}
} catch () {
if (mounted) setState(() => statusText = 'Ошибка сети. Проверь интернет!');
}
}
void _send(Map<String, dynamic> data) {
if (client?.connectionStatus?.state != MqttConnectionState.connected) return;
data['sender'] = widget.isHost ? 'host' : 'guest';
final b = MqttClientPayloadBuilder()..addString(jsonEncode(data));
client!.publishMessage('sticker_brawl_ru/room/${widget.roomCode}', MqttQos.atLeastOnce, b.payload!);
}
void _handleNet(Map<String, dynamic> data) {
if (data['sender'] == (widget.isHost ? 'host' : 'guest')) return;
if (data['type'] == 'join' && widget.isHost) {
setState(() { opponentConnected = true; statusText = 'Друг зашёл! Твой ход!'; });
} else if (data['type'] == 'attack') {
final card = allStickers.firstWhere((s) => s.id == data['cardId'], orElse: () => allStickers[0]);
HapticFeedback.heavyImpact();
setState(() {
lastCard = card;
myHp = max(0, myHp - (data['damage'] as int));
enemyHp = min(150, enemyHp + (data['heal'] as int));
myTurn = true;
statusText = 'Враг ударил «${card.name}» (-${data['damage']} HP)! Твой ход!';
});
_checkWin();
}
}
void _playCard(StickerCard card) {
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
if (widget.isOnline) _send({'type': 'attack', 'cardId': card.id, 'damage': dmg, 'heal': heal});
if (_checkWin() || widget.isOnline) return;
Future.delayed(const Duration(milliseconds: 1000), () {
if (!mounted || enemyHp <= 0) return;
final bot = allStickers[Random().nextInt(4)];
HapticFeedback.heavyImpact();
setState(() { lastCard = bot; myHp = max(0, myHp - bot.atk); myTurn = true; statusText = 'Бот ответил «${bot.name}» (-${bot.atk} HP)! Твой ход!'; });
_checkWin();
});
}
bool _checkWin() {
if (enemyHp > 0 && myHp > 0) return false;
final won = enemyHp <= 0;
if (won) SharedPreferences.getInstance().then((p) { p.setInt('wins', (p.getInt('wins') ?? 0) + 1); widget.onWin(); });
showDialog(
context: context,
barrierDismissible: false,
builder: (ctx) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
title: Text(won ? 'Победа!' : 'Поражение', textAlign: TextAlign.center),
content: Text(won ? 'Ты сокрушил соперника!' : 'Попробуй ещё раз!', textAlign: TextAlign.center),
actionsAlignment: MainAxisAlignment.center,
actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('В меню'))],
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
appBar: AppBar(title: Text(widget.isOnline ? 'Комната: ${widget.roomCode}' : 'Бой с ботом'), centerTitle: true),
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
Card(
elevation: 0,
color: colors.errorContainer.withOpacity(0.5),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(children: [
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Соперник', style: TextStyle(fontWeight: FontWeight.bold)), Text('$enemyHp HP', style: const TextStyle(fontWeight: FontWeight.w900))]),
const SizedBox(height: 6),
ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: enemyHp / 120, minHeight: 10, color: colors.error)),
]),
),
),
const Spacer(),
if (lastCard != null) Column(children: [
ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset(lastCard!.asset, height: 140, width: 140, fit: BoxFit.cover)),
const SizedBox(height: 6),
Text(lastCard!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
]) else Container(height: 140, width: 140, decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.flash_on, size: 48)),
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(20)),
child: Text(statusText, textAlign: TextAlign.center, style: TextStyle(color: colors.onSecondaryContainer, fontWeight: FontWeight.w600)),
),
const Spacer(),
Card(
elevation: 0,
color: colors.primaryContainer.withOpacity(0.5),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(children: [
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Твоё здоровье', style: TextStyle(fontWeight: FontWeight.bold)), Text('$myHp HP', style: const TextStyle(fontWeight: FontWeight.w900))]),
const SizedBox(height: 6),
ClipRRect(borderRadius: BorderRadius.circular(12), child: LinearProgressIndicator(value: myHp / 120, minHeight: 10, color: colors.primary)),
]),
),
),
const SizedBox(height: 12),
SizedBox(
height: 160,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: myDeck.length,
separatorBuilder: (, __) => const SizedBox(width: 10),
itemBuilder: (, i) {
final c = myDeck[i];
return GestureDetector(
onTap: () => _playCard(c),
child: AnimatedOpacity(
duration: const Duration(milliseconds: 200),
opacity: (myTurn && opponentConnected) ? 1.0 : 0.45,
child: Container(
width: 120,
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: c.isVip ? colors.tertiaryContainer : colors.surfaceContainerHigh,
borderRadius: BorderRadius.circular(24),
border: Border.all(color: c.isVip ? colors.tertiary : colors.outlineVariant, width: c.isVip ? 2 : 1),
),
child: Column(children: [
Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset(c.asset, width: double.infinity, fit: BoxFit.cover))),
const SizedBox(height: 6),
Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
Text('⚔️ ${c.atk} ATK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: colors.primary)),
]),
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
