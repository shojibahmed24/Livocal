import 'package:flutter/material.dart';
import 'package:livocal/theme/color_theme.dart';
import 'package:livocal/theme/theme.dart';

class ScaffoldWithSearch extends StatefulWidget {
  final AppBar appBar;
  final int searchIconActionIndex;
  final String hintText;
  final TextEditingController searchController;
  final Function(String value) onChanged;
  final Function() onCloseBtnPressed;
  final Widget child;

  const ScaffoldWithSearch({
    super.key,
    required this.appBar,
    this.hintText = 'Search...',
    this.searchIconActionIndex = 0,
    required this.searchController,
    required this.onChanged,
    required this.onCloseBtnPressed,
    required this.child,
  });

  @override
  State<ScaffoldWithSearch> createState() => _ScaffoldWithSearchState();
}

class _ScaffoldWithSearchState extends State<ScaffoldWithSearch> {
  int appBarIndex = 0;
  Widget? _showCross = const Text('');
  late List<Widget> _defaultActions;

  @override
  void initState() {
    super.initState();
    _buildActions();
  }

  @override
  void didUpdateWidget(ScaffoldWithSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appBar != widget.appBar ||
        oldWidget.searchIconActionIndex != widget.searchIconActionIndex) {
      _buildActions();
    }
  }

  void _buildActions() {
    final actions = List<Widget>.from(widget.appBar.actions ?? []);
    final searchButton = IconButton(
      onPressed: () {
        setState(() {
          appBarIndex = 1;
        });
      },
      icon: const Icon(Icons.search),
      tooltip: 'Search',
    );
    if (widget.searchIconActionIndex >= 0 &&
        widget.searchIconActionIndex <= actions.length) {
      actions.insert(widget.searchIconActionIndex, searchButton);
    } else {
      actions.add(searchButton);
    }
    _defaultActions = actions;
  }

  AppBar _buildDefaultAppBar() {
    return AppBar(
      key: widget.appBar.key,
      leading: widget.appBar.leading,
      automaticallyImplyLeading: widget.appBar.automaticallyImplyLeading,
      title: widget.appBar.title,
      actions: _defaultActions,
      flexibleSpace: widget.appBar.flexibleSpace,
      bottom: widget.appBar.bottom,
      elevation: widget.appBar.elevation,
      scrolledUnderElevation: widget.appBar.scrolledUnderElevation,
      shadowColor: widget.appBar.shadowColor,
      surfaceTintColor: widget.appBar.surfaceTintColor,
      shape: widget.appBar.shape,
      backgroundColor: widget.appBar.backgroundColor,
      foregroundColor: widget.appBar.foregroundColor,
      iconTheme: widget.appBar.iconTheme,
      actionsIconTheme: widget.appBar.actionsIconTheme,
      primary: widget.appBar.primary,
      centerTitle: widget.appBar.centerTitle,
      titleSpacing: widget.appBar.titleSpacing,
      toolbarOpacity: widget.appBar.toolbarOpacity,
      bottomOpacity: widget.appBar.bottomOpacity,
      toolbarHeight: widget.appBar.toolbarHeight,
      leadingWidth: widget.appBar.leadingWidth,
      toolbarTextStyle: widget.appBar.toolbarTextStyle,
      titleTextStyle: widget.appBar.titleTextStyle,
      systemOverlayStyle: widget.appBar.systemOverlayStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchAppBar = AppBar(
      elevation: 0.0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      title: TextField(
        onChanged: (value) {
          if (value.isNotEmpty) {
            _showCross = null;
          } else {
            _showCross = const Text('');
          }

          widget.onChanged(value);
        },
        autofocus: true,
        controller: widget.searchController,
        style: Theme.of(context)
            .custom
            .textTheme
            .subtitle1
            .copyWith(color: Colors.white),
        cursorColor: Theme.of(context).custom.colorTheme.greenColor,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Theme.of(context)
              .custom
              .textTheme
              .subtitle1
              .copyWith(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
      leading: IconButton(
        onPressed: () {
          setState(() {
            appBarIndex = 0;
          });
          widget.onChanged('');
        },
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        _showCross ??
            IconButton(
              onPressed: () {
                widget.onCloseBtnPressed();
                setState(() {
                  _showCross = const Text('');
                });
              },
              icon: const Icon(Icons.close),
            ),
      ],
      centerTitle: false,
    );

    return Scaffold(
      appBar: appBarIndex == 0 ? _buildDefaultAppBar() : searchAppBar,
      body: widget.child,
    );
  }
}
