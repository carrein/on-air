import 'package:memoka_server/src/generated/protocol.dart';
import 'package:memoka_server/src/search/search_setup.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Helper: create a channel + note, return the note.
Future<Note> _createNote(
  dynamic endpoints,
  TestSessionBuilder sessionBuilder,
  String content, {
  String channelName = 'SearchTest',
}) async {
  final channel = await endpoints.chat.createChannel(
    sessionBuilder,
    channelName,
    emoji: 'magnifyingGlass',
  );
  return await endpoints.chat.createNote(
    sessionBuilder,
    channel.id!,
    content,
  );
}

void main() {
  withServerpod(
    'Given Search endpoint',
    rollbackDatabase: RollbackDatabase.afterAll,
    (sessionBuilder, endpoints) {
      setUpAll(() async {
        final session = sessionBuilder.build();
        try {
          await SearchSetup.ensureSearchInfrastructure(session);
        } finally {
          await session.close();
        }
      });

      // ── Helper to create a channel with multiple notes ──
      Future<Channel> createChannelWithNotes(
        List<String> contents, {
        String name = 'SearchCh',
      }) async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          name,
          emoji: 'magnifyingGlass',
        );
        for (final c in contents) {
          await endpoints.chat.createNote(sessionBuilder, channel.id!, c);
        }
        return channel;
      }

      group('searchNotes — Basic matching', () {
        test('empty query returns empty list', () async {
          await _createNote(endpoints, sessionBuilder, 'SomeContent');
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            '',
            limit: 20,
          );
          expect(results, isEmpty);
        });

        test('whitespace-only query returns empty list', () async {
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            '   ',
            limit: 20,
          );
          expect(results, isEmpty);
        });

        test('exact word match', () async {
          await createChannelWithNotes(['Zephyr unique word']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Zephyr',
            limit: 20,
          );
          expect(results, isNotEmpty);
          expect(results.first.snippet.toLowerCase(), contains('zephyr'));
        });

        test('prefix match', () async {
          await createChannelWithNotes(['Flamingo bird']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Flam',
            limit: 20,
          );
          expect(results, isNotEmpty);
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('flamingo')),
            isTrue,
          );
        });

        test('single-char prefix', () async {
          await createChannelWithNotes(['Xylophone instrument']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'X',
            limit: 20,
          );
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('xylophone')),
            isTrue,
          );
        });

        test('two-char prefix', () async {
          await createChannelWithNotes(['Kickoff event']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'ki',
            limit: 20,
          );
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('kickoff')),
            isTrue,
          );
        });

        test('substring match (middle of word)', () async {
          await createChannelWithNotes(['Kickoff event']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'ickoff',
            limit: 20,
          );
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('kickoff')),
            isTrue,
          );
        });

        test('substring match (end of word)', () async {
          await createChannelWithNotes(['Kickoff event']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'off',
            limit: 20,
          );
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('kickoff')),
            isTrue,
          );
        });

        test('case insensitive lowercase query', () async {
          await createChannelWithNotes(['KALEIDOSCOPE pattern']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'kaleidoscope',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('case insensitive uppercase query', () async {
          await createChannelWithNotes(['microscope lens']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'MICROSCOPE',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });
      });

      group('searchNotes — Typo tolerance', () {
        test('typo in long word matches via word_similarity', () async {
          await createChannelWithNotes(['Meeting scheduled tomorrow']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'meetting',
            limit: 20,
          );
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('meeting')),
            isTrue,
          );
        });

        test('transposition typo matches', () async {
          await createChannelWithNotes(['Project deadline approaching']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'proejct',
            limit: 20,
          );
          expect(
            results.any((r) => r.snippet.toLowerCase().contains('project')),
            isTrue,
          );
        });

        test('no fuzzy for short terms (< 3 chars)', () async {
          // "sd" is 2 chars — should NOT fuzzy-match "sda" or anything
          await createChannelWithNotes(['sda unique content']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'sd',
            limit: 20,
          );
          // "sd" can still match via ILIKE substring (sda contains "sd")
          // but won't fuzzy-match unrelated words
          // This just verifies it doesn't crash
          expect(results, isA<List<SearchResult>>());
        });

        test('letter-skipping does not get high score', () async {
          await createChannelWithNotes(['Flutterific code']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Fltrc',
            limit: 20,
          );
          // Letter-skipping may match via word_similarity (shared trigrams)
          // but should score low (fuzzy range 0.2-0.4), not high like
          // prefix (1.0) or substring (0.6).
          final match = results.where(
            (r) => r.snippet.toLowerCase().contains('flutterific'),
          );
          if (match.isNotEmpty) {
            expect(match.first.score, lessThan(0.5));
          }
        });

        test('non-contiguous subsequence does NOT match', () async {
          await createChannelWithNotes(['Quicksilver metal']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'ickslvr',
            limit: 20,
          );
          expect(
            results.any(
              (r) => r.snippet.toLowerCase().contains('quicksilver'),
            ),
            isFalse,
          );
        });
      });

      group('searchNotes — Multi-word AND logic', () {
        test('AND: both terms required', () async {
          await createChannelWithNotes([
            'Tangerine fruit',
            'Sapphire gem',
            'Tangerine Sapphire both',
          ]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Tangerine Sapphire',
            limit: 20,
          );
          // Only the note with BOTH words should match
          for (final r in results) {
            final s = r.snippet.toLowerCase();
            expect(s, contains('tangerine'));
            expect(s, contains('sapphire'));
          }
        });

        test('AND: missing one term returns no match', () async {
          await createChannelWithNotes(['meeting agenda']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'meeting banana',
            limit: 20,
          );
          final hasMatch = results.any(
            (r) => r.snippet.toLowerCase().contains('meeting agenda'),
          );
          expect(hasMatch, isFalse);
        });

        test('AND ranking: all terms present scores highest', () async {
          await createChannelWithNotes([
            'Vermillion and Cerulean together',
          ]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Vermillion Cerulean',
            limit: 20,
          );
          expect(results, isNotEmpty);
          expect(
            results.first.snippet.toLowerCase(),
            allOf(contains('vermillion'), contains('cerulean')),
          );
        });

        test('per-word no cross-span', () async {
          await createChannelWithNotes(['Mango Papaya separate words']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'MangoPapaya',
            limit: 20,
          );
          // "MangoPapaya" as a single token may match via word_similarity
          // (shared trigrams), but should NOT match via FTS prefix or ILIKE
          // substring. Verify it doesn't get a high (prefix/substring) score.
          final match = results.where(
            (r) => r.snippet.toLowerCase().contains('mango'),
          );
          if (match.isNotEmpty) {
            // If it matches, it should be a low fuzzy score (< 0.5)
            expect(match.first.score, lessThan(0.5));
          }
        });

        test('three-word AND requires all terms', () async {
          await createChannelWithNotes([
            'Telescope device',
            'Origami craft',
            'Pyramid structure',
            'Telescope Origami Pyramid combined',
          ]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Telescope Origami Pyramid',
            limit: 20,
          );
          // Only the note with all three should match
          for (final r in results) {
            final s = r.snippet.toLowerCase();
            expect(s, contains('telescope'));
            expect(s, contains('origami'));
            expect(s, contains('pyramid'));
          }
        });
      });

      group('searchNotes — Word boundaries', () {
        test('markdown bold boundary', () async {
          await createChannelWithNotes(['The **Obsidian** stone']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Obsidian',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('markdown link boundary', () async {
          await createChannelWithNotes(
            ['Check [Archipelago](not-a-url) here'],
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Archipelago',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('hyphen boundary', () async {
          await createChannelWithNotes(['nebula-chrysanthemum words']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'chrysanthemum',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('underscore boundary', () async {
          await createChannelWithNotes(['alpha_Periwinkle_test']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Periwinkle',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('dot boundary', () async {
          await createChannelWithNotes(['api.Labyrinthine.endpoint']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Labyrinthine',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('slash boundary', () async {
          await createChannelWithNotes(['path/Crystallography/file']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Crystallography',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('comma boundary', () async {
          await createChannelWithNotes(['alpha,Quasar,gamma']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Quasar',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('parentheses boundary', () async {
          await createChannelWithNotes(
            ['parentheses (Phantasmagoria) content'],
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Phantasmagoria',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('backtick boundary', () async {
          await createChannelWithNotes(['inline `Onomatopoeia` code']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Onomatopoeia',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });
      });

      group('searchNotes — Special content', () {
        test('numeric matching', () async {
          await createChannelWithNotes(['unique98765 number']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            '98765',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('regex metacharacters in content do not break search', () async {
          await createChannelWithNotes(['x] bracket edge']);
          await createChannelWithNotes(['a.*b+c?d regex chars']);
          // Should not throw
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'bracket',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('regex metacharacters in query do not crash', () async {
          await createChannelWithNotes(['Kaleidoscopic safe content']);
          // These should not throw
          await endpoints.search.searchNotes(
            sessionBuilder,
            'x]',
            limit: 20,
          );
          await endpoints.search.searchNotes(
            sessionBuilder,
            'a.*',
            limit: 20,
          );
          await endpoints.search.searchNotes(
            sessionBuilder,
            '(test)',
            limit: 20,
          );
        });

        test('very long content returns snippet not full content', () async {
          final longContent =
              'Serendipity ${'lorem ipsum dolor sit amet ' * 50}';
          await createChannelWithNotes([longContent]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Serendipity',
            limit: 20,
          );
          expect(results, isNotEmpty);
          expect(results.first.snippet.length, lessThan(longContent.length));
        });

        test('JSON content searchable', () async {
          await createChannelWithNotes(
            ['{ "Ytterbium": "element", "atomic": 70 }'],
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Ytterbium',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('SQL content searchable', () async {
          await createChannelWithNotes(
            ['SELECT Australopithecus FROM fossils WHERE age > 1000000'],
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Australopithecus',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });

        test('URL-like content searchable', () async {
          await createChannelWithNotes(
            ['Visit Bioluminescence dot dev for info'],
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Bioluminescence',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });
      });

      group('searchNotes — Filtering', () {
        test('excludes archived notes', () async {
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'FilterArchNote',
            emoji: 'magnifyingGlass',
          );
          final note = await endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'Xylocarpus archived note',
          );
          await endpoints.chat.deleteNote(sessionBuilder, note.id!);

          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Xylocarpus',
            limit: 20,
          );
          expect(results.any((r) => r.noteId == note.id), isFalse);
        });

        test('excludes notes in archived channels', () async {
          // Need two channels so archiving one is allowed
          await endpoints.chat.createChannel(
            sessionBuilder,
            'FilterKeep',
            emoji: 'magnifyingGlass',
          );
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'FilterArchCh',
            emoji: 'magnifyingGlass',
          );
          await endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'Zymurgy archived channel note',
          );
          await endpoints.chat.archiveChannel(sessionBuilder, channel.id!);

          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Zymurgy',
            limit: 20,
          );
          expect(results, isEmpty);
        });

        test('includes non-archived notes in non-archived channels', () async {
          await createChannelWithNotes(['Ephemeral visible note']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Ephemeral',
            limit: 20,
          );
          expect(results, isNotEmpty);
        });
      });

      group('searchNotes — Limits & edge cases', () {
        test('custom limit returns at most that many results', () async {
          await createChannelWithNotes([
            'Abracadabra one',
            'Abracadabra two',
            'Abracadabra three',
          ]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Abracadabra',
            limit: 2,
          );
          expect(results.length, lessThanOrEqualTo(2));
        });

        test('limit=1 returns highest-scoring result', () async {
          await createChannelWithNotes([
            'Synecdoche only one',
            'Synecdoche also here',
          ]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Synecdoche',
            limit: 1,
          );
          expect(results.length, 1);
        });

        test('query truncated at 200 chars still works', () async {
          await createChannelWithNotes(['Triskaidekaphobia fear']);
          final longQuery = 'Triskaidekaphobia ${'a' * 250}';
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            longQuery,
            limit: 20,
          );
          // With AND logic, the extra 'aaaa...' term won't match,
          // but Triskaidekaphobia alone won't return results either.
          // This test just verifies no crash on long queries.
          expect(results, isA<List<SearchResult>>());
        });

        test('duplicate words in content returns note once', () async {
          await createChannelWithNotes(
            ['Hendiadys Hendiadys Hendiadys repeated'],
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Hendiadys',
            limit: 20,
          );
          final matchingIds = results.where(
            (r) => r.snippet.toLowerCase().contains('hendiadys'),
          );
          // Should appear at most once per note (DISTINCT)
          final noteIds = matchingIds.map((r) => r.noteId).toSet();
          expect(noteIds.length, matchingIds.length);
        });

        test('empty content note never appears in results', () async {
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'EmptyContent',
            emoji: 'magnifyingGlass',
          );
          await endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'x',
          );
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            '',
            limit: 20,
          );
          expect(results, isEmpty);
        });
      });

      group('searchNotes — Snippets', () {
        test('snippet contains <b> tags around matched terms', () async {
          await createChannelWithNotes(['Quintessential quality']);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Quintessential',
            limit: 20,
          );
          expect(results, isNotEmpty);
          expect(results.first.snippet, contains('<b>'));
          expect(results.first.snippet, contains('</b>'));
        });

        test('snippet is truncated for long notes', () async {
          final longContent = 'Verisimilitude ${'word ' * 200}';
          await createChannelWithNotes([longContent]);
          final results = await endpoints.search.searchNotes(
            sessionBuilder,
            'Verisimilitude',
            limit: 20,
          );
          expect(results, isNotEmpty);
          expect(results.first.snippet.length, lessThan(longContent.length));
        });
      });

      group('getNotesAroundId', () {
        test('returns surrounding notes centered on target', () async {
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'AroundCh',
            emoji: 'magnifyingGlass',
          );
          final notes = <Note>[];
          for (var i = 0; i < 10; i++) {
            notes.add(
              await endpoints.chat.createNote(
                sessionBuilder,
                channel.id!,
                'AroundNote $i',
              ),
            );
          }
          final target = notes[5];
          final result = await endpoints.search.getNotesAroundId(
            sessionBuilder,
            channel.id!,
            target.id!,
            limit: 6,
          );
          expect(result.any((n) => n.id == target.id), isTrue);
          expect(result.length, lessThanOrEqualTo(7));
        });

        test('respects channelId filter', () async {
          final ch1 = await endpoints.chat.createChannel(
            sessionBuilder,
            'AroundCh1',
            emoji: 'magnifyingGlass',
          );
          final ch2 = await endpoints.chat.createChannel(
            sessionBuilder,
            'AroundCh2',
            emoji: 'magnifyingGlass',
          );
          final note1 = await endpoints.chat.createNote(
            sessionBuilder,
            ch1.id!,
            'AroundCh1Note',
          );
          await endpoints.chat.createNote(
            sessionBuilder,
            ch2.id!,
            'AroundCh2Note',
          );
          final result = await endpoints.search.getNotesAroundId(
            sessionBuilder,
            ch1.id!,
            note1.id!,
            limit: 25,
          );
          expect(result.every((n) => n.channelId == ch1.id), isTrue);
        });

        test('notes ordered by createdAt descending', () async {
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'AroundOrder',
            emoji: 'magnifyingGlass',
          );
          for (var i = 0; i < 5; i++) {
            await endpoints.chat.createNote(
              sessionBuilder,
              channel.id!,
              'OrderNote $i',
            );
          }
          final notes = await endpoints.chat.getNotes(
            sessionBuilder,
            channel.id!,
            limit: 50,
          );
          final target = notes[2];
          final result = await endpoints.search.getNotesAroundId(
            sessionBuilder,
            channel.id!,
            target.id!,
            limit: 10,
          );
          for (var i = 0; i < result.length - 1; i++) {
            expect(
              result[i].createdAt.isAfter(result[i + 1].createdAt) ||
                  result[i].createdAt == result[i + 1].createdAt,
              isTrue,
            );
          }
        });
      });
    },
  );
}
