import 'package:kantan/quiz_page.dart';
import 'package:test/test.dart';

void main() {
  late QuizController quiz;

  setUp(() {
    quiz = QuizController();
  });

  test('quiz should be initialized with 3 stages', () {
    expect(quiz.stages.length, 3);
  });

  test('quiz should start at stage 0', () {
    expect(quiz.currentStageIndex, 0);
  });

  test('quiz should start at item 0', () {
    expect(quiz.currentItemIndex, 0);
  });


  test('stages should be populated with 3 kanji', () {
    final fakeGetData = (String path) async => [];
      quiz.stages.clear();
  quiz.stages.addAll([
    Stage(name: 'new', items: [
      QuizItem(id:1, kanji:'A', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
    ]),
    Stage(name: 'known', items: [
      QuizItem(id:3, kanji:'C', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
    ]),
  ]);
    for (var stage in quiz.stages) {
      expect(stage.items.length, 3);
    }
  });

test('checkPhoneticSignificance returns radical when onreading matches', () async {
    final fakeGetData = (String path) async => [
        {'onreadings': ['セイ', 'ショウ']}
      ];

    final item = QuizItem(
      id: 1,
      kanji: '情',
      onReadings: ['ジョウ', 'セイ'],
      kunReadings: [],
      meanings: ['emotion'],
      kanjiRadicals: ['青', '忄'],
      userKnownRadicals: ['青', '忄'],
      getData: fakeGetData
    );

    final result = await item.checkPhoneticSignificance();
    expect(result, '青');
  });

  test('checkPhoneticSignificance returns null when no match', () async {
      final fakeGetData = (String path) async => [
        {'onreadings': ['スイ']}
      ];
    final item = QuizItem(
      id: 2,
      kanji: '氷',
      onReadings: ['ヒョウ'],
      kunReadings: [],
      meanings: ['ice'],
      kanjiRadicals: ['丶', '水'],
      userKnownRadicals: ['水'],
      getData: fakeGetData
    );

    final result = await item.checkPhoneticSignificance();
    expect(result, null);
  });

  test('quiz should show onyomi input question for new kanji that are phonetically significant', () async {
     final fakeGetData = (String path) async => [
      {'onreadings': ['セイ', 'ショウ']}
    ];
    quiz.stages.clear();
    quiz.stages.addAll([
      Stage(name: 'new', items: [
        QuizItem(
      id: 1,
      kanji: '情',
      onReadings: ['ジョウ', 'セイ'],
      kunReadings: [],
      meanings: ['emotion'],
      kanjiRadicals: ['青', '忄'],
      userKnownRadicals: ['青', '忄'],
      getData: fakeGetData
    )
    ])]);

    expect(quiz.currentStage.name, 'new');
    expect(quiz.currentItemIndex, 0);
    expect(await quiz.selectQuestionType(null), 0);
    expect(await quiz.selectAnswerType(), 0); 
  });

  //test('quiz should show mulitple choice question for new kanji that are semantically significant', body);
  
  test('quiz shows info-only for kanji neither semantic nor phonetic for new kanji on attempt 0', () async {
    final fakeGetData = (String path) async => [];
    quiz.stages.clear();
    quiz.stages.addAll([
      Stage(name: 'new', items: [
        QuizItem(id:1, kanji:'A', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
        QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      ]),
      Stage(name: 'known', items: [
        QuizItem(id:3, kanji:'C', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      ]),
    ]);

    quiz.currentItem.phoneticRadical = null;
    quiz.currentItem.semanticRadical = null;

    expect(quiz.currentStage.name, 'new');
    expect(quiz.currentItemIndex, 0);
    expect(await quiz.selectQuestionType(null), 3);
    expect(await quiz.selectAnswerType(), 3); 
  });

  test('quiz is marked as over when all stages are finished and each kanji has been attempted thrice', () {
    final fakeGetData = (String path) async => [];

    quiz.stages.clear();
    quiz.stages.addAll([
      Stage(name: 'new', items: [
        QuizItem(id:1, kanji:'A', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
        QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
        QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      ]),
      Stage(name: 'known', items: [
        QuizItem(id:3, kanji:'C', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
        QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
        QuizItem(id:2, kanji:'B', onReadings:[], kunReadings:[], meanings:[], kanjiRadicals:[], getData: fakeGetData),
      ]),
    ]);

    int totalAttempts = 0;
    for (var stage in quiz.stages) {totalAttempts += stage.items.length * 3;}

    for (var i=0; i<totalAttempts; i++) {
      quiz.changeQuestion();
    }

    expect(quiz.quizOver, true);
  });
}