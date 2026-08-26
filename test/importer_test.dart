import 'package:flutter_test/flutter_test.dart';
import 'package:canele/services/universal_importer.dart';

void main() {
  group('UniversalImporter Regex & Parsing Tests', () {
    test('Extracts series title and decimal volume from diverse formats', () {
      final t1 = UniversalImporter.parseTitleAndVolume('86 - Eighty-Six, Vol. 11.5 (Light Novel)');
      expect(t1.seriesTitle, '86 - Eighty-Six');
      expect(t1.volumeNumber, 11.5);

      final t2 = UniversalImporter.parseTitleAndVolume('Frieren: Beyond Journey\'s End, Vol. 10 (Frieren, #10)');
      expect(t2.seriesTitle, 'Frieren: Beyond Journey\'s End');
      expect(t2.volumeNumber, 10.0);

      final t3 = UniversalImporter.parseTitleAndVolume('Spy x Family - Volume 3.5');
      expect(t3.seriesTitle, 'Spy x Family');
      expect(t3.volumeNumber, 3.5);

      final t4 = UniversalImporter.parseTitleAndVolume('Dungeon Meshi #7');
      expect(t4.seriesTitle, 'Dungeon Meshi');
      expect(t4.volumeNumber, 7.0);

      final t5 = UniversalImporter.parseTitleAndVolume('The Apothecary Diaries Book 4 (Light Novel)');
      expect(t5.seriesTitle, 'The Apothecary Diaries');
      expect(t5.volumeNumber, 4.0);
    });

    test('Parses Goodreads CSV export', () {
      const goodreadsCsv = '''
Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies
12345,"86 - Eighty-Six, Vol. 11.5 (Light Novel)","Asato Asato","Asato, Asato",,"=""""","=""""",5,4.8,"Yen Press","Paperback",280,2023,2023,2023/10/15,2023/10/01,,,"read",,,,,1,,,0
67890,"Frieren, Vol. 2 (Manga)","Kanehito Yamada","Yamada, Kanehito",,"=""""","=""""",0,4.9,"VIZ Media","Paperback",190,2021,2021,,2023/11/01,,,"to-read",,,,,0,,,0
''';

      final items = UniversalImporter.parseCsvString(goodreadsCsv);
      expect(items.length, 2);

      expect(items[0].seriesTitle, '86 - Eighty-Six');
      expect(items[0].volumeNumber, 11.5);
      expect(items[0].isOwned, true);
      expect(items[0].status, 'active');
      expect(items[0].sourceFormat, 'goodreads');

      expect(items[1].seriesTitle, 'Frieren');
      expect(items[1].volumeNumber, 2.0);
      expect(items[1].isOwned, false);
      expect(items[1].status, 'wishlist');
    });

    test('Parses StoryGraph CSV export', () {
      const storyGraphCsv = '''
Title,Authors,Contributors,Review,Star Rating,Read Status,Date Added,Last Date Read,Format
"Spy x Family, Vol. 8","Tatsuya Endo",,"Loved it",5.0,"read",2024-01-10,2024-01-15,"print"
"Dungeon Meshi, Vol. 12","Ryoko Kui",,,,"to-read",2024-02-01,,"digital"
''';

      final items = UniversalImporter.parseCsvString(storyGraphCsv);
      expect(items.length, 2);

      expect(items[0].seriesTitle, 'Spy x Family');
      expect(items[0].volumeNumber, 8.0);
      expect(items[0].isOwned, true);

      expect(items[1].seriesTitle, 'Dungeon Meshi');
      expect(items[1].volumeNumber, 12.0);
      expect(items[1].isOwned, false);
      expect(items[1].status, 'wishlist');
    });

    test('Parses Generic CSV export with custom columns', () {
      const genericCsv = '''
Series,Volume,Format,Owned,Price
"The Apothecary Diaries",4,Light Novel,true,14.99
"The Apothecary Diaries",5.5,Light Novel,false,14.99
''';

      final items = UniversalImporter.parseCsvString(genericCsv);
      expect(items.length, 2);
      expect(items[0].seriesTitle, 'The Apothecary Diaries');
      expect(items[0].volumeNumber, 4.0);
      expect(items[0].isOwned, true);
      expect(items[0].price, 14.99);

      expect(items[1].seriesTitle, 'The Apothecary Diaries');
      expect(items[1].volumeNumber, 5.5);
      expect(items[1].isOwned, false);
    });
  });
}
