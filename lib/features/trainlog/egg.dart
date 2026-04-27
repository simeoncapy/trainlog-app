import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

Future<ui.Image> loadImage(String asset) async {
  final data = await rootBundle.load(asset);
  final bytes = data.buffer.asUint8List();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame>
    with WidgetsBindingObserver {
  int gridWidth = 0;
  int gridHeight = 0;
  static const int tickMs = 180;
  ui.Image? snakeHeadImage;
  ui.Image? snakeBodyImage;
  ui.Image? snakeBodyCornerImage;
  ui.Image? foodImage;

  final Random _rng = Random();
  Timer? _timer;

  List<Offset> snake = [const Offset(10, 10)];
  Offset food = Offset.zero;
  Offset direction = const Offset(1, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAssets();
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }

  Future<void> _loadAssets() async {
    snakeHeadImage = await loadImage('assets/images/loco.png');
    snakeBodyImage = await loadImage('assets/images/coach.png');
    snakeBodyCornerImage = await loadImage('assets/images/coach_corner.png');
    foodImage = await loadImage('assets/images/passenger.png');
    setState(() {});
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: tickMs),
      (_) => _tick(),
    );
  }

  void _tick() {
    if (gridWidth == 0 || gridHeight == 0) return;
    setState(() {
      Offset head = snake.first + direction;

      // Wrap around screen edges
      head = Offset(
        (head.dx + gridWidth) % gridWidth,
        (head.dy + gridHeight) % gridHeight,
      );

      // Self-collision only
      if (snake.contains(head)) {
        _reset();
        return;
      }

      snake.insert(0, head);

      if (head == food) {
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _reset() {
    snake = [const Offset(10, 10)];
    direction = const Offset(1, 0);
    _spawnFood();
  }

  void _spawnFood() {
    if (gridWidth <= 0 || gridHeight <= 0) return;

    Offset newFood;
    do {
      newFood = Offset(
        _rng.nextInt(gridWidth).toDouble(),
        _rng.nextInt(gridHeight).toDouble(),
      );
    } while (snake.contains(newFood));

    food = newFood;
  }

  void _onSwipe(DragUpdateDetails d) {
    Offset newDirection;

    if (d.delta.dx.abs() > d.delta.dy.abs()) {
      newDirection = d.delta.dx > 0
          ? const Offset(1, 0)
          : const Offset(-1, 0);
    } else {
      newDirection = d.delta.dy > 0
          ? const Offset(0, 1)
          : const Offset(0, -1);
    }

    // Prevent 180° turn
    if (!_isOpposite(direction, newDirection)) {
      direction = newDirection;
    }
  }

  bool _isOpposite(Offset a, Offset b) {
    return a.dx + b.dx == 0 && a.dy + b.dy == 0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.nbrPassengers(snake.length-1)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: Colors.grey[850],
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;

            // Choose cell size (adjust for density / speed)
            const double cellSize = 30;

            gridWidth = (size.width / cellSize).floor();
            gridHeight = (size.height / cellSize).floor();

            if (gridWidth > 0 && gridHeight > 0 && food == Offset.zero) {
              _spawnFood();
            }

            return GestureDetector(
              onPanUpdate: (DragUpdateDetails d) {
                // Ignore tiny movements (jitter)
                if (d.delta.distance > 2.0) {
                  _onSwipe(d);
                }
              },
              child: CustomPaint(
                size: Size(
                  gridWidth * cellSize,
                  gridHeight * cellSize,
                ),
                painter: _SnakePainter(
                  snake: snake,
                  food: food,
                  gridWidth: gridWidth,
                  gridHeight: gridHeight,
                  direction: direction,
                  headImage: snakeHeadImage,
                  bodyImage: snakeBodyImage,
                  cornerImage: snakeBodyCornerImage,
                  foodImage: foodImage,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


class _SnakePainter extends CustomPainter {
  final List<Offset> snake;
  final Offset food;
  final int gridWidth;
  final int gridHeight;
  final Offset direction;
  final ui.Image? headImage;
  final ui.Image? bodyImage;
  final ui.Image? cornerImage;
  final ui.Image? foodImage;

  _SnakePainter({
    required this.snake,
    required this.food,
    required this.gridWidth,
    required this.gridHeight,
    required this.direction,
    required this.headImage,
    required this.bodyImage,
    required this.cornerImage,
    required this.foodImage,
  });

  double directionToAngle(Offset dir) {
    if (dir == const Offset(1, 0)) return 0;            // right
    if (dir == const Offset(0, 1)) return pi / 2;       // down
    if (dir == const Offset(-1, 0)) return pi;          // left
    if (dir == const Offset(0, -1)) return -pi / 2;     // up
    return 0;
  }

  double getCornerRotation(Offset p, Offset n) {
    // Summing the vectors from 'curr' to 'prev' and 'curr' to 'next'
    // gives us a diagonal vector representing the corner's "elbow".
    double dx = p.dx + n.dx;
    double dy = p.dy + n.dy;

    // Sprite is naturally Left (-1, 0) and Down (0, 1)
    // Total vector: (-1, 1)
    
    if (dx == -1 && dy == 1) return 0;         // Left-Down (Default)
    if (dx == -1 && dy == -1) return pi / 2;  // Left-Up (Rotate 90° CW)
    if (dx == 1 && dy == -1) return pi;       // Right-Up (Rotate 180°)
    if (dx == 1 && dy == 1) return -pi / 2;   // Right-Down (Rotate 270° CW)
    
    return 0;
  }

  Offset normalize(Offset d) {
    double dx = d.dx;
    double dy = d.dy;
    
    // If the distance is > 1, it means it wrapped around the screen
    if (dx.abs() > 1) dx = -dx.sign; 
    if (dy.abs() > 1) dy = -dy.sign;
    
    return Offset(dx, dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (headImage == null || bodyImage == null || foodImage == null) return;

    final cellW = size.width / gridWidth;
    final cellH = size.height / gridHeight;

    // Draw snake
    for (int i = 0; i < snake.length; i++) {
      final p = snake[i];
      final isHead = i == 0;
      ui.Image img = isHead ? headImage! : bodyImage!;

      final dst = Rect.fromLTWH(
        p.dx * cellW,
        p.dy * cellH,
        cellW,
        cellH,
      );

      double angle = 0.0;

      if (isHead) {
        angle = directionToAngle(direction);
      } else {
        final prev = snake[i - 1];
        final curr = snake[i];
        final dPrev = normalize(prev - curr);

        if (i > 0 && i + 1 < snake.length) {          
          final dNext = normalize(snake[i + 1] - curr);

          if (dPrev.dx != dNext.dx && dPrev.dy != dNext.dy) {
            img = cornerImage!;
            angle = getCornerRotation(dPrev, dNext);
          } else {
            // Straight segment: use the direction towards the previous piece
            angle = directionToAngle(dPrev);
          }
        }
        else {
          angle = directionToAngle(dPrev);
        }
      }

        canvas.save();

        // Move pivot to center of the cell
        canvas.translate(
          dst.left + dst.width / 2,
          dst.top + dst.height / 2,
        );

        canvas.rotate(angle);

        // Draw centered
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(
            0,
            0,
            img.width.toDouble(),
            img.height.toDouble(),
          ),
          Rect.fromCenter(
            center: Offset.zero,
            width: dst.width,
            height: dst.height,
          ),
          Paint(),//..filterQuality = FilterQuality.none,
        );

        canvas.restore();
    }
    // Draw food
    canvas.drawImageRect(
      foodImage!,
      Rect.fromLTWH(
        0,
        0,
        foodImage!.width.toDouble(),
        foodImage!.height.toDouble(),
      ),
      Rect.fromLTWH(
        food.dx * cellW,
        food.dy * cellH,
        cellW,
        cellH,
      ),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
