import 'package:astra/core/astro/moon_phase.dart';
import 'package:astra/core/astro/zodiac.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ZodiacSign.fromDate', () {
    test('границы знаков', () {
      expect(ZodiacSign.fromDate(DateTime(2000, 3, 20)), ZodiacSign.pisces);
      expect(ZodiacSign.fromDate(DateTime(2000, 3, 21)), ZodiacSign.aries);
      expect(ZodiacSign.fromDate(DateTime(2000, 4, 19)), ZodiacSign.aries);
      expect(ZodiacSign.fromDate(DateTime(2000, 4, 20)), ZodiacSign.taurus);
      expect(ZodiacSign.fromDate(DateTime(2000, 11, 21)), ZodiacSign.scorpio);
      expect(ZodiacSign.fromDate(DateTime(2000, 11, 22)), ZodiacSign.sagittarius);
    });

    test('Козерог через Новый год', () {
      expect(ZodiacSign.fromDate(DateTime(1999, 12, 22)), ZodiacSign.capricorn);
      expect(ZodiacSign.fromDate(DateTime(2000, 1, 1)), ZodiacSign.capricorn);
      expect(ZodiacSign.fromDate(DateTime(2000, 1, 19)), ZodiacSign.capricorn);
      expect(ZodiacSign.fromDate(DateTime(2000, 1, 20)), ZodiacSign.aquarius);
    });

    test('каждый день года принадлежит ровно одному знаку', () {
      var d = DateTime(2024); // високосный
      while (d.year == 2024) {
        expect(() => ZodiacSign.fromDate(d), returnsNormally);
        d = d.add(const Duration(days: 1));
      }
    });

    test('созвездия ссылаются на существующие звёзды', () {
      for (final s in ZodiacSign.values) {
        final c = s.constellation;
        for (final (a, b) in c.lines) {
          expect(a, lessThan(c.stars.length), reason: s.name);
          expect(b, lessThan(c.stars.length), reason: s.name);
        }
        expect(c.brightest, lessThan(c.stars.length));
      }
    });
  });

  group('MoonPhase', () {
    // Моменты фаз — из таблиц NASA / USNO.
    test('полнолуние 25.01.2024 17:54 UTC', () {
      final m = MoonPhase.at(DateTime.utc(2024, 1, 25, 17, 54));
      expect(m.illumination, greaterThan(0.995));
      expect(m.name, MoonPhaseName.fullMoon);
      // Луна в Льве (~125° тропической долготы)
      expect(m.sign, ZodiacSign.leo);
    });

    test('новолуние 11.01.2024 11:57 UTC', () {
      final m = MoonPhase.at(DateTime.utc(2024, 1, 11, 11, 57));
      expect(m.illumination, lessThan(0.005));
      expect(m.name, MoonPhaseName.newMoon);
      expect(m.sign, ZodiacSign.capricorn);
    });

    test('первая четверть 18.01.2024 03:52 UTC', () {
      final m = MoonPhase.at(DateTime.utc(2024, 1, 18, 3, 52));
      expect(m.illumination, closeTo(0.5, 0.02));
      expect(m.isWaxing, isTrue);
      expect(m.name, MoonPhaseName.firstQuarter);
    });

    test('последняя четверть 02.02.2024 23:18 UTC', () {
      final m = MoonPhase.at(DateTime.utc(2024, 2, 2, 23, 18));
      expect(m.illumination, closeTo(0.5, 0.02));
      expect(m.isWaxing, isFalse);
      expect(m.name, MoonPhaseName.lastQuarter);
    });

    test('лунный день в диапазоне 1..30', () {
      var d = DateTime.utc(2025);
      for (var i = 0; i < 400; i++) {
        final day = MoonPhase.at(d).lunarDay;
        expect(day, inInclusiveRange(1, 30));
        d = d.add(const Duration(hours: 22));
      }
    });
  });
}
