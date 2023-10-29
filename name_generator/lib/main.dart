import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  void getNext() {
    // Add the current word pair to the history.
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    // Get a new word pair.
    current = WordPair.random();
    // Make a call to update widgets that depend on MyAppState.
    notifyListeners();
  }

  // List to store the favorited word pairs.
  Set<WordPair> favorites = {};

  // Add or remove a word pair from the favorites list. Calls notify Listeners to tell widgets that this data updated.
  void toggleFavorite([WordPair? pair]) {
    // if no word pair was passed in as an argument, we toggle the currently displayed wordpair (current).
    pair = pair ?? current;
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }

  // Removes a WordPair from from favorites.
  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Determines which Page is showing. 0 = Home, 1 = Favorites.
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget selectedPage;
    switch (selectedIndex) {
      // Not sure why there does not need to be break statements below ...
      case 0:
        selectedPage = GeneratorPage();
      // ... here ...
      case 1:
        selectedPage = FavoritesPage();
      // ... and here.
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // The navigation menu items, for display in different menu layouts.
    final List<Map<String, dynamic>> navigationItems = [
      {
        'icon': Icon(Icons.home),
        'label': 'Home',
      },
      {
        'icon': Icon(Icons.favorite),
        'label': 'Favorites',
      },
    ];

    // The container for the current page, with its background color and subtle switching animation.
    var mainArea = ColoredBox(
      color: colorScheme.surfaceVariant,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: selectedPage,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 450) {
          // Use a more mobile-friendly layout with BottomNavigationBar on narrow screen.
          return Column(
            children: [
              Expanded(child: mainArea),
              SafeArea(
                child: BottomNavigationBar(
                  items: navigationItems
                      .map((item) => BottomNavigationBarItem(
                            icon: item['icon'],
                            label: item['label'],
                          ))
                      .toList(),
                  currentIndex: selectedIndex,
                  onTap: (value) => setState(() {
                    selectedIndex = value;
                  }),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: navigationItems
                      .map((item) => NavigationRailDestination(
                            icon: item['icon'],
                            label: Text(item['label']),
                          ))
                      .toList(),
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(child: mainArea),
            ],
          );
        }
      }),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    // Heart icon indicating whether or not the current pair was favorited.
    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        // Make the column elements vertically centered in the column.
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: HistoryListView(),
          ),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          // Add a button below the text.
          Row(
            // MainAxisSize.min makes the parameter mainAxisSize shrink to fit the elemets it contains.
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
          // This Spacer is to make the Row item be in the middle of the screen.
          Spacer(flex: 2),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    // Color theme.
    final theme = Theme.of(context);
    // Text style.
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        // TODO: Don't know what MergeSemantics does.
        child: MergeSemantics(
          child: Wrap(
            // Increased the font size so that you can see the word wrap working.
            // By default, there are no [fontSize] parameters used in the Text Widgets.
            children: [
              Text(
                pair.first,
                style: style.copyWith(
                  fontSize: 80,
                  fontWeight: FontWeight.w200,
                ),
                // semanticsLabel tells the phone what actual raw text is displayed here if you were to read it.
                semanticsLabel: pair.first,
              ),
              Text(
                pair.second,
                style: style.copyWith(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                ),
                // semanticsLabel tells the phone what actual raw text is displayed here if you were to read it.
                semanticsLabel: pair.second,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return Column(
      // crossAxisAlignment: ,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have ${appState.favorites.length}'
              ' favorite${appState.favorites.length == 1 ? '' : 's'}'),
        ),
        Expanded(
          // Make better use of wide windows with a grid.
          child: GridView(
            // Make the grid elements as wide as possible across the width of the grid while the vertical height remains the same.
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({Key? key}) : super(key: key);

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
}

class _HistoryListViewState extends State<HistoryListView> {
  // Needed so that [MyAppState] can tell [AnimatedList] below to animate new items.
  final _key = GlobalKey();

  // Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient) and applies it to the destiantion (i.e. our animated list)
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                label: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
                onPressed: () {
                  appState.toggleFavorite(pair);
                },
                icon: appState.favorites.contains(pair)
                    ? Icon(
                        Icons.favorite,
                        size: 12,
                      )
                    : SizedBox(),
              ),
            ),
          );
        },
      ),
    );
  }
}
