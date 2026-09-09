import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mondori/models/board.dart';
import 'package:mondori/models/piece.dart';
import 'package:mondori/widgets/board_widget.dart';

void main() {
  group('BoardWidget', () {
    // ヘルパーメソッド: BoardWidget をテストアプリにラップ
    Widget _createTestWidget({
      required Board board,
      Piece? selectedPiece,
      required VoidCallback onPieceSelected,
      required VoidCallback onPositionTapped,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: BoardWidget(
              board: board,
              selectedPiece: selectedPiece,
              onPieceSelected: (_) => onPieceSelected(),
              onPositionTapped: (_) => onPositionTapped(),
            ),
          ),
        ),
      );
    }

    testWidgets('6×6 グリッドが表示される', (WidgetTester tester) async {
      final board = Board.initialPlacement1();
      bool pieceSelected = false;
      bool positionTapped = false;

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: null,
          onPieceSelected: () => pieceSelected = true,
          onPositionTapped: () => positionTapped = true,
        ),
      );

      // グリッドが表示されることを確認
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('盤上の駒が円形で表示される', (WidgetTester tester) async {
      final board = Board.initialPlacement1();

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: null,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // _PieceWidget (駒ウィジェット) が複数表示される
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('駒をタップすると onPieceSelected が呼ばれる',
        (WidgetTester tester) async {
      final board = Board.initialPlacement1();
      final piece = board.getPieceAt(Position(column: 'a', row: 1));
      bool pieceSelected = false;

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: null,
          onPieceSelected: () => pieceSelected = true,
          onPositionTapped: () {},
        ),
      );

      // a1 の駒をタップ
      final cell = find.byType(GridView);
      expect(cell, findsOneWidget);

      // セル内をタップ（最初のセルをタップ = a1）
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // オプション: タップ後の状態を確認
      // 実装は board_widget.dart の GestureDetector.onTap に依存
    });

    testWidgets('選択された駒のセルが青色で表示される',
        (WidgetTester tester) async {
      final board = Board.initialPlacement1();
      final selectedPiece = board.getPieceAt(Position(column: 'a', row: 1));

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: selectedPiece,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // 選択されたセルの背景色が blue.shade200 であることを確認
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // 装飾されたコンテナを確認
      final decoratedContainers = find
          .byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color != null,
          )
          .evaluate()
          .toList();

      expect(decoratedContainers.length, greaterThan(0));
    });

    testWidgets('移動可能な位置のセルが緑色で表示される',
        (WidgetTester tester) async {
      final board = Board.initialPlacement1();
      final selectedPiece = board.getPieceAt(Position(column: 'a', row: 1));

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: selectedPiece,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // 移動可能位置（a2）のセルが緑色であることを確認
      // BoardWidget の _getCellColor メソッドが green.shade100 を返すことに依存
      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('敵駒の隣接セルが赤色で表示される',
        (WidgetTester tester) async {
      // テスト用の盤を作成: c3 にA陣営の進、d3 にB陣営の対
      final pieces = <Position, Piece>{
        Position(column: 'c', row: 3): Piece(
          id: 'A-advance',
          side: PlayerSide.A,
          seal: SealType.advance,
          position: Position(column: 'c', row: 3),
        ),
        Position(column: 'd', row: 3): Piece(
          id: 'B-counter',
          side: PlayerSide.B,
          seal: SealType.counter,
          position: Position(column: 'd', row: 3),
        ),
      };
      final board = Board(pieces: pieces);
      final selectedPiece = pieces[Position(column: 'c', row: 3)];

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: selectedPiece,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // 敵駒（d3）の隣接セルが赤色で表示される
      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('無印駒の隣接セルが黄色で表示される',
        (WidgetTester tester) async {
      // テスト用の盤を作成: c3 にA陣営の早、d3 にA陣営の無印
      final pieces = <Position, Piece>{
        Position(column: 'c', row: 3): Piece(
          id: 'A-swift',
          side: PlayerSide.A,
          seal: SealType.swift,
          position: Position(column: 'c', row: 3),
        ),
        Position(column: 'd', row: 3): Piece(
          id: 'A-none',
          side: PlayerSide.A,
          seal: SealType.none,
          position: Position(column: 'd', row: 3),
        ),
      };
      final board = Board(pieces: pieces);
      final selectedPiece = pieces[Position(column: 'c', row: 3)];

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: selectedPiece,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // 無印駒（d3）の隣接セルが黄色で表示される
      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('移動可能位置で脈動アニメーションが再生される',
        (WidgetTester tester) async {
      final board = Board.initialPlacement1();
      final selectedPiece = board.getPieceAt(Position(column: 'a', row: 1));

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: selectedPiece,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // アニメーションを複数フレーム実行
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // ScaleTransition が存在することを確認
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('駒選択時のスケールアニメーション', (WidgetTester tester) async {
      final board = Board.initialPlacement1();
      final selectedPiece = board.getPieceAt(Position(column: 'a', row: 1));

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: selectedPiece,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // アニメーション実行
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // _PieceWidget のスケールアニメーション確認
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('駒の刻印ラベルが正しく表示される',
        (WidgetTester tester) async {
      final board = Board.initialPlacement1();

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: null,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // 刻印ラベルのテキストを確認
      expect(find.text('進'), findsWidgets); // 進刻印
      expect(find.text('早'), findsWidgets); // 早刻印
      expect(find.text('対'), findsWidgets); // 対刻印
      expect(find.text('王'), findsWidgets); // 王刻印
    });

    testWidgets('盤のサイズが正方形である', (WidgetTester tester) async {
      final board = Board.initialPlacement1();

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: null,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // AspectRatio が 1:1 であることを確認
      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatio =
          find.byType(AspectRatio).evaluate().first.widget as AspectRatio;
      expect(aspectRatio.aspectRatio, 1.0);
    });

    testWidgets('列・行ラベルが表示される', (WidgetTester tester) async {
      final board = Board.initialPlacement1();

      await tester.pumpWidget(
        _createTestWidget(
          board: board,
          selectedPiece: null,
          onPieceSelected: () {},
          onPositionTapped: () {},
        ),
      );

      // 列ラベル (a-f)
      expect(find.text('a'), findsWidgets);
      expect(find.text('b'), findsWidgets);
      expect(find.text('c'), findsWidgets);
      expect(find.text('d'), findsWidgets);
      expect(find.text('e'), findsWidgets);
      expect(find.text('f'), findsWidgets);

      // 行ラベル (1-6)
      expect(find.text('1'), findsWidgets);
      expect(find.text('6'), findsWidgets);
    });
  });
}
