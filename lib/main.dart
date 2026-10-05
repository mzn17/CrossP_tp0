import 'dart:math'; // needed for min() and Random()

import 'package:flutter/material.dart';

// ---------- GLOBAL SETTINGS ----------
// null = RANDOM mode (default): every rectangle gets its own random color
final ValueNotifier<MaterialColor?> selectedColor = ValueNotifier(null);
final ValueNotifier<double> borderWidth = ValueNotifier(
  1,
); // border thickness (0 to 10)
final ValueNotifier<double> radiusPercent = ValueNotifier(
  0,
); // roundness in % (0 to 100)
final ValueNotifier<double> spacing = ValueNotifier(
  0,
); // NEW: gap between rectangles (0 to 20)
final ValueNotifier<bool> reverseShade = ValueNotifier(
  false,
); // NEW: false = dark -> light, true = light -> dark
final ValueNotifier<int> resetCount = ValueNotifier(
  0,
); // each +1 rebuilds everything from scratch

// One object that listens to ALL settings at once (shorter code later)
final Listenable allSettings = Listenable.merge([
  selectedColor,
  borderWidth,
  radiusPercent,
  spacing,
  reverseShade,
]);

// The shades used from the darkest (900) to the lightest (50)
const List<int> shades = [900, 800, 700, 600, 500, 400, 300, 200, 100, 50];

// Returns the shade of a color for a given depth (level of division)
Color shadeFor(MaterialColor color, int depth) {
  int index = min(depth, shades.length - 1); // never go past the last shade
  if (reverseShade.value)
    index = shades.length - 1 - index; // flip the order if needed
  return color[shades[index]]!;
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white, // header background: white
          foregroundColor: Colors.black, // title and icons: black
          surfaceTintColor: Colors.white, // avoids a color tint on the header
          title: const Text('rectongle app'),
          actions: [
            // NEW: reset button on the right of the header
            TextButton(
              onPressed: () =>
                  resetCount.value++, // +1 = new key = everything restarts
              child: const Text('Reset'),
            ),
          ],
        ),
        drawer: const SettingsDrawer(), // side menu (menu button added automatically on the left)
        // Rebuild the SplitBox from zero every time resetCount changes
        body: ValueListenableBuilder<int>(
          valueListenable: resetCount,
          builder: (context, n, _) => SplitBox(key: ValueKey(n), depth: 0),
        ),
      ),
    );
  }
}

// ---------- SIDE MENU ----------
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  // The 4 colors the user can choose from
  static final List<MaterialColor> colors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.yellow,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width:
          MediaQuery.of(context).size.width *
          0.3, // menu = 30% of the screen width
      child: ListenableBuilder(
        listenable: allSettings, // redraw the menu when any setting changes
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ----- Setting 1: color -----
              const Text(
                '1. Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // NEW: "random" circle (default)
                  GestureDetector(
                    onTap: () => selectedColor.value = null, // null = random
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(
                        // check mark if random is selected, otherwise a shuffle icon
                        selectedColor.value == null
                            ? Icons.check
                            : Icons.shuffle,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  for (final c in colors) // one circle per color
                    GestureDetector(
                      onTap: () => selectedColor.value = c,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: c,
                        child: selectedColor.value == c
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
              const Divider(height: 32),

              // ----- Setting 2: borders -----
              Text(
                '2. Borders: ${borderWidth.value.toStringAsFixed(0)} px',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: borderWidth.value,
                min: 0,
                max: 10,
                onChanged: (v) => borderWidth.value = v,
              ),
              const Divider(height: 32),

              // ----- Setting 3: radius in % -----
              Text(
                '3. Radius: ${radiusPercent.value.toStringAsFixed(0)} %',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: radiusPercent.value,
                min: 0,
                max: 100,
                onChanged: (v) => radiusPercent.value = v,
              ),
              const Divider(height: 32),

              // ----- Setting 4 (NEW): spacing between rectangles -----
              Text(
                '4. Spacing: ${spacing.value.toStringAsFixed(0)} px',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                value: spacing.value,
                min: 0,
                max: 20,
                onChanged: (v) => spacing.value = v,
              ),
              const Divider(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ---------- THE RECTANGLE THAT SPLITS ----------
class SplitBox extends StatefulWidget {
  final int
  depth; // how many times we already divided (0 = the first big rectangle)
  const SplitBox({super.key, required this.depth});

  @override
  State<SplitBox> createState() => _SplitBoxState();
}

class _SplitBoxState extends State<SplitBox> {
  bool isSplit = false; // false = one rectangle, true = divided in 2

  // This rectangle's own random color, picked once when it is created
  final MaterialColor randomColor =
      Colors.primaries[Random().nextInt(Colors.primaries.length)];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Case 1: not split yet -> a clickable rectangle
        if (!isSplit) {
          return GestureDetector(
            onTap: () => setState(() => isSplit = true), // click = split
            child: ListenableBuilder(
              listenable: allSettings, // redraw when a setting changes
              builder: (context, _) {
                // Selected color, or this rectangle's random color if none selected
                final color = selectedColor.value ?? randomColor;

                // Biggest possible radius = half of the smallest side
                final maxRadius =
                    min(constraints.maxWidth, constraints.maxHeight) / 2;
                final radius = maxRadius * radiusPercent.value / 100;

                return Padding(
                  // Spacing: half of the gap on each side (two neighbors = full gap)
                  padding: EdgeInsets.all(spacing.value / 2),
                  child: Container(
                    decoration: BoxDecoration(
                      // Gradient between this level's shade and the next level's shade
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          shadeFor(color, widget.depth),
                          shadeFor(color, widget.depth + 1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: Colors.white,
                        width: borderWidth.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        // Case 2: split -> 2 new SplitBox, one level deeper (depth + 1)
        final children = [
          Expanded(child: SplitBox(depth: widget.depth + 1)),
          Expanded(child: SplitBox(depth: widget.depth + 1)),
        ];

        // Cut along the longest side to get squares
        return constraints.maxWidth > constraints.maxHeight
            ? Row(children: children)
            : Column(children: children);
      },
    );
  }
}
