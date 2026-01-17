import 'package:flutter/material.dart';
import 'package:searvo/features/discover/theme/discover_theme.dart';

class EditorialDivider extends StatelessWidget {
  final double horizontalPadding;

  const EditorialDivider({Key? key, this.horizontalPadding = 32})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = DiscoverTheme.colors(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1400),
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 32,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, colors.divider],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(
                Icons.diamond_outlined,
                size: 12,
                color: colors.accent,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.divider, Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
