import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/utils/code_wrapper.dart';
import 'package:xbb/utils/latex.dart';

class SimpleMarkdownRenderer extends StatelessWidget {
  final String data;

  const SimpleMarkdownRenderer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);
    return MarkdownBlock(
      data: data,
      generator: MarkdownGenerator(inlineSyntaxList: [LatexSyntax()], generators: [latexGenerator]),
      config: config.copy(
        configs: [
          isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
        ],
      ),
    );
  }
}

class MarkdownWithComments extends StatelessWidget {
  final String data;
  final String postId;
  final String repoOwnedId;
  final List<Permission> permissions;

  const MarkdownWithComments({
    super.key,
    required this.data,
    required this.postId,
    required this.repoOwnedId,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleMarkdownRenderer(data: data);
  }
}
