import 'package:test/test.dart';
import 'package:enumerators/combinators.dart' as c;
import 'package:dartz/dartz.dart';
import 'dart:async';
import 'laws.dart';

void main() {

  test("demo", () {
    final IMap<int, String> intToEnglishMap = imap({1: "one", 2: "two", 3: "three"});
    final IMap<String, String> englishToSwedishMap = imap({"one": "ett", "two": "två"});

    Either<String, int> stringToInt(String intString) => catching(() => int.parse(intString)).leftMap((_) => "could not parse '$intString' to int");
    Either<String, String> intToEnglish(int i) => intToEnglishMap.get(i) % "could not translate '$i' to english";
    Either<String, String> englishToSwedish(String english) => englishToSwedishMap.get(english) % "could not translate '$english' to swedish";
    Either<String, String> intStringToSwedish(String intString) => (stringToInt(intString) >= intToEnglish) >= englishToSwedish;

    expect(intStringToSwedish("1"), right("ett"));
    expect(intStringToSwedish("2"), right("två"));
    expect(intStringToSwedish("fyrtiosjutton"), left("could not parse 'fyrtiosjutton' to int"));
    expect(intStringToSwedish("3"), left("could not translate 'three' to swedish"));
    expect(intStringToSwedish("4"), left("could not translate '4' to english"));
  });

  test("transformer demo", () async {
    final Monad<Future<List<Either>>> M = eitherTMonad(listTMonad(FutureM));
    final stacked = M.map(M.bind(M.map(new Future.sync(() => [right("a"), left("b"), right("c")]),
        (x) => x + "!"),
        (x) => new Future.delayed(new Duration(seconds: 1), () => [right(x), right(x)])),
        (x) => x.toUpperCase());

    expect(await stacked, [right("A!"), right("A!"), left("b"), right("C!"), right("C!")]);
  });

  test("sequencing", () {
    final IList<Either<String, int>> l = ilist([right(1), right(2)]);
    expect(l.sequence(EitherM), right(ilist([1,2])));
    expect(l.sequence(EitherM).sequence(IListM), l);

    final IList<Either<String, int>> l2 = ilist([right(1), left("out of ints..."), right(2)]);
    expect(l2.sequence(EitherM), left("out of ints..."));
    expect(l2.sequence(EitherM).sequence(IListM), ilist([left("out of ints...")]));
  });

  group("EitherM", () => checkMonadLaws(EitherM));

  group("EitherTMonad+Id", () => checkMonadLaws(eitherTMonad(IdM)));

  group("EitherTMonad+IList", () => checkMonadLaws(eitherTMonad(IListM)));

  group("EitherM+Foldable", () => checkFoldableMonadLaws(EitherFo, EitherM));

  final intEithers = c.ints.map((i) => i%2==0 ? right(i) : left(i));

  group("EitherTr", () => checkTraversableLaws(EitherTr, intEithers));
}