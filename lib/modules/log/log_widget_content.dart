part of 'log_widget.dart';

class LogContent extends StatelessWidget {
  const LogContent({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onUserScroll,
  });

  final LogMixin controller;
  final ScrollController scrollController;
  final Function() onUserScroll;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final patterns = _buildPatterns(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: colors.logBackground,
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            onUserScroll();
            return false;
          },
          child: Obx(
            () => ListView.builder(
              controller: scrollController,
              itemCount: controller.logs.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: EasyRichText(
                  controller.logs[index],
                  patternList: patterns,
                  selectable: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  defaultStyle: _selectStyle(context),
                ),
              ),
            ).paddingAll(10),
          ),
        ),
      ),
    ).constrained(width: double.infinity, height: double.infinity);
  }

  List<EasyRichTextPattern> _buildPatterns(BuildContext context) {
    final colors = OasxColors.of(context);
    const figures = TextStyle(
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return [
      EasyRichTextPattern(
        targetString: 'INFO',
        style: figures.copyWith(color: colors.logInfo),
        suffixInlineSpan: const TextSpan(
          style: figures,
          text: '      ',
        ),
      ),
      EasyRichTextPattern(
        targetString: 'WARNING',
        style: figures.copyWith(color: colors.logWarning),
      ),
      EasyRichTextPattern(
        targetString: 'ERROR',
        style: figures.copyWith(color: colors.logError),
        suffixInlineSpan: const TextSpan(style: figures, text: '    '),
      ),
      EasyRichTextPattern(
        targetString: 'CRITICAL',
        style: figures.copyWith(color: colors.logError),
        suffixInlineSpan: const TextSpan(text: '   '),
      ),
      EasyRichTextPattern(
        targetString: r'(\d{2}:\d{2}:\d{2}\.\d{3})',
        style: figures.copyWith(color: colors.logTimestamp),
      ),
      const EasyRichTextPattern(
        targetString: r'[\{\[\(\)\]\}]',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      EasyRichTextPattern(
        targetString: 'True',
        style: figures.copyWith(color: colors.accent),
      ),
      EasyRichTextPattern(
        targetString: 'False',
        style: figures.copyWith(color: colors.danger),
      ),
      EasyRichTextPattern(
        targetString: 'None',
        style: figures.copyWith(color: colors.textTertiary),
      ),
      EasyRichTextPattern(
        targetString: r'(某喵*某喵)|(~~*~~)',
        style: figures.copyWith(color: colors.accent),
      ),
    ];
  }

  TextStyle _selectStyle(BuildContext context) {
    final size = context.mediaQuery.orientation == Orientation.portrait
        ? 12.0
        : 12.5;
    return OasxText.mono(
      context,
      size: size,
      color: OasxColors.of(context).logText,
      height: 1.5,
    );
  }
}
