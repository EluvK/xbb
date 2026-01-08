import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/code_wrapper.dart';
import 'package:xbb/utils/latex.dart';

class NewMarkdownRenderer extends StatelessWidget {
  final String data;
  final List<Comment> comments;

  const NewMarkdownRenderer({super.key, required this.data, this.comments = const []});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);

    // noted: hand write `MarkdownGenerator` parsing to get nodes, thus we can map comments to paragraphs
    // final generator = MarkdownGenerator(inlineSyntaxList: [LatexSyntax()], generators: [latexGenerator]);
    // final List<Widget> contents = generator.buildWidgets(data, config: config);
    final config = (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig).copy(
      configs: [
        isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
      ],
    );

    List<_ParagraphData> paragraphList = [];

    final WidgetVisitor visitor = WidgetVisitor(config: config, generators: [latexGenerator]);
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [LatexSyntax()],
    ).parseLines(data.split(WidgetVisitor.defaultSplitRegExp));
    final spans = visitor.visit(nodes);
    // the length of nodes and spans should be equal
    // print("nodes length: ${nodes.length}, spans length: ${spans.length}");
    spans.asMap().forEach((index, span) {
      final richText = Text.rich(span.build());
      final node = nodes[index];
      final bool canHaveComments = node is md.Element && node.tag == 'p';
      // if (node is md.Element) {
      //   print("[node e] node tag: ${node.tag}, text: ${node.textContent}");
      // }
      final rawText = node.textContent;
      final id = rawText.hashCode.toString(); // todo better fingerprint
      print(
        "[build] paragraph id: $id, index: $index, rawText: $rawText, canHaveComments: $canHaveComments",
      ); // , richText: $richText
      paragraphList.add(_ParagraphData(id: id, widget: richText, rawText: rawText, canHaveComments: canHaveComments));
    });

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...paragraphList.asMap().entries.map((entry) {
            // print("[data] ${entry.value.id} => ${entry.value.rawText}");
            // todo find the corresponding comment for this entry
            // then wrap it together
            return ParagraphWrapper(
              content: entry.value.widget,
              comments: [], // todo find comments for this paragraph
              enableCommentFeature: entry.value.canHaveComments,
            );
          }),
        ],
      ),
    );
  }
}

class _ParagraphData {
  final String id; // fingerprint id
  final Widget widget;
  final String rawText;
  final bool canHaveComments;

  _ParagraphData({required this.id, required this.widget, required this.rawText, required this.canHaveComments});
}

class ParagraphWrapper extends StatelessWidget {
  // final ? key; // we need to identify paragraph for comment mapping
  final Widget content;
  final List<Comment> comments;
  final bool enableCommentFeature;
  const ParagraphWrapper({
    super.key,
    required this.content,
    required this.comments,
    required this.enableCommentFeature,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // some as linesMargin in `MarkdownGenerator` markdown_generator.dart
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        // decoration: BoxDecoration(
        //   border: enableCommentFeature ? Border.all(color: Colors.grey.shade300) : null,
        //   borderRadius: enableCommentFeature ? BorderRadius.circular(4.0) : null,
        // ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            // if (enableCommentFeature) Align(alignment: Alignment.bottomRight, child: CommentInputTrigger()),
            // todo render comments trees if any
          ],
        ),
      ),
    );
  }
}

class CommentInputTrigger extends StatelessWidget {
  const CommentInputTrigger({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.comment, size: 16, color: Colors.grey);
  }
}
