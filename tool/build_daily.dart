// Генерирует документы `daily/{yyyy-MM-dd}` из встроенного контента.
//
//   dart run tool/build_daily.dart [--from 2026-11-19] [--days 120] [--out build/daily.json]
//
// Затем загрузка в Firestore: `npm --prefix functions run seed -- --project <ID>`.
import 'dart:convert';
import 'dart:io';

import 'package:astra/features/today/data/mock_content.dart';

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final now = DateTime.now();
  final from = DateTime.tryParse(opt('from') ?? '') ?? DateTime(now.year, now.month, now.day);
  final days = int.tryParse(opt('days') ?? '') ?? 120;
  final out = File(opt('out') ?? 'build/daily.json');

  final docs = [
    for (var i = 0; i < days; i++)
      mockDailyBuilder.build(DateTime(from.year, from.month, from.day + i)).toJson(),
  ];
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(docs));
  stdout.writeln(
    '✦ ${docs.length} дней (${docs.first['day']} … ${docs.last['day']}) → ${out.path}',
  );
}
