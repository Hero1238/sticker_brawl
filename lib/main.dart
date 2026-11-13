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

class GameConfig {
  static bool isOnline = false;
  static bool isHost = true;
  static String roomCode = '';
  static bool vipUnlocked = false;
  static int wins = 0;
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
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
                GameConfig.isOnline = true;
                GameConfig.isHost = true;
                GameConfig.roomCode = (1000 + Random().nextInt(9000)).toString();
                Navigator.push(context, MaterialPageRoute(builder: (c) => const BattleScreen())).then((v) => loadData());
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
                  GameConfig.isOnline = true;
                  GameConfig.isHost = false;
                  GameConfig.roomCode = codeCtrl.text;
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const BattleScreen())).then((v) => loadData());
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

  void showVipShop() {
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
            if (GameConfig.vipUnlocked)
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
                      setState(() => GameConfig.vipUnlocked = true);
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
                  Chip(avatar: const Icon(Icons.emoji_events, size: 18), label: Text('Побед: ${GameConfig.wins}')),
                  FilledButton.tonalIcon(onPressed: showVipShop, icon: Icon(GameConfig.vipUnlocked ? Icons.verified : Icons.lock_open), label: Text(GameConfig.vipUnlocked ? 'VIP Активен' : 'VIP Пак')),
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
                onPressed: showOnlineDialog,
                icon: const Icon(Icons.wifi_tethering),
                label: const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Text('Играть с другом (Онлайн)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () {
                  
