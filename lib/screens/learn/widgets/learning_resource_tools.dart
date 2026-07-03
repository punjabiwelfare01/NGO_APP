import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/colors.dart';
import '../../../models/learning_resource.dart';
import '../../../repositories/api_client.dart';
import '../../../repositories/course_repository.dart';
import '../../../utils/file_download.dart';
import '../../../utils/platform_video.dart';

class LessonTextContent extends StatelessWidget {
  const LessonTextContent({this.text, super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.trim().isEmpty) {
      return const _EmptyInlineMessage('No content available for this lesson.');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Text(
        text!,
        style: const TextStyle(fontSize: 15, color: AppColors.ink, height: 1.7),
      ),
    );
  }
}

class LessonVideoContent extends StatelessWidget {
  const LessonVideoContent({this.url, this.maxHeight, super.key});

  final String? url;
  final double? maxHeight;

  static String? extractVideoId(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
      return uri.pathSegments[1];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = extractVideoId(url);
    if (videoId != null) {
      return _VideoFrame(
        maxHeight: maxHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: buildYouTubeEmbed(videoId),
        ),
      );
    }
    final resolvedUrl = _resolvedVideoUrl;
    if (resolvedUrl != null) {
      return _VideoFrame(
        maxHeight: maxHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: buildNetworkVideo(resolvedUrl),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.play_circle_outline_rounded,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            url == null || url!.trim().isEmpty
                ? 'No preview video available.'
                : url!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  String? get _resolvedVideoUrl {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    return ApiClient.resolveUrl(value);
  }
}

class _VideoFrame extends StatelessWidget {
  const _VideoFrame({required this.child, this.maxHeight});

  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    if (maxHeight == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight!),
      child: child,
    );
  }
}

class LearningResourceTile extends StatelessWidget {
  const LearningResourceTile({
    required this.resource,
    this.onDelete,
    super.key,
  });

  final LearningResource resource;
  final VoidCallback? onDelete;

  String? get _fullUrl {
    final fileUrl = resource.fileUrl;
    if (fileUrl == null || fileUrl.trim().isEmpty) return null;
    return ApiClient.resolveUrl(fileUrl);
  }

  String get _downloadName {
    final url = _fullUrl;
    if (url == null) return resource.title;
    final parsed = Uri.tryParse(url);
    final path = parsed?.pathSegments.isNotEmpty == true
        ? parsed!.pathSegments.last
        : '';
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return resource.title;
    final extension = path.substring(dotIndex);
    if (resource.title.toLowerCase().endsWith(extension.toLowerCase())) {
      return resource.title;
    }
    return '${resource.title}$extension';
  }

  bool get _canPreview =>
      resource.type == 'note' ||
      resource.type == 'image' ||
      resource.type == 'video' ||
      resource.type == 'pdf' ||
      resource.type == 'pdf_notes' ||
      resource.type == 'link';

  Future<void> _download(BuildContext context) async {
    final url = _fullUrl;
    if (url == null) return;
    final ok = await downloadFile(url, _downloadName);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Download started for offline access.'
              : 'Could not start download.',
        ),
      ),
    );
    if (!ok) {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    }
  }

  void _preview(BuildContext context) {
    if (resource.type == 'note') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NotePreviewSheet(
          title: resource.title,
          content: resource.textContent ?? 'No content.',
        ),
      );
      return;
    }

    final url = _fullUrl;
    if (url == null) return;
    showDialog(
      context: context,
      builder: (_) => _ResourcePreviewDialog(
        resource: resource,
        url: url,
        onDownload: () => _download(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _fullUrl;
    final canDownload = url != null;
    final canPreview = _canPreview && (resource.type == 'note' || url != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(resource.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  resource.typeLabel,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (canPreview)
            IconButton(
              tooltip: 'Preview',
              onPressed: () => _preview(context),
              icon: const Icon(Icons.visibility_outlined),
              color: AppColors.primary,
            ),
          if (canDownload)
            IconButton(
              tooltip: 'Download',
              onPressed: () => _download(context),
              icon: const Icon(Icons.download_rounded),
              color: AppColors.secondary,
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete resource',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.softRed,
            ),
        ],
      ),
    );
  }
}

class AddResourceSheet extends StatefulWidget {
  const AddResourceSheet({
    required this.courseId,
    required this.lessonId,
    super.key,
  });

  final int courseId;
  final int lessonId;

  @override
  State<AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends State<AddResourceSheet> {
  static const _types = [
    'link',
    'pdf',
    'pdf_notes',
    'image',
    'video',
    'note',
    'zip',
    'code_file',
  ];
  static const _fileTypes = {
    'pdf',
    'pdf_notes',
    'image',
    'video',
    'zip',
    'code_file',
  };

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _type = 'link';
  String? _pickedFileName;
  List<int>? _pickedFileBytes;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _needsFilePick => _fileTypes.contains(_type);
  bool get _needsUrl => _type == 'link';
  bool get _needsNote => _type == 'note';

  Future<void> _pickFile() async {
    FileType fileType;
    List<String>? allowedExtensions;
    switch (_type) {
      case 'pdf':
      case 'pdf_notes':
        fileType = FileType.custom;
        allowedExtensions = ['pdf'];
      case 'zip':
        fileType = FileType.custom;
        allowedExtensions = ['zip'];
      case 'code_file':
        fileType = FileType.custom;
        allowedExtensions = ['py', 'js', 'dart', 'html', 'css', 'txt', 'json'];
      case 'image':
        fileType = FileType.image;
      case 'video':
        fileType = FileType.video;
      default:
        fileType = FileType.any;
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedFileName = result.files.single.name;
        _pickedFileBytes = result.files.single.bytes!.toList();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_needsFilePick && _pickedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a file first.'),
          backgroundColor: AppColors.softRed,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      String? fileUrl;
      if (_pickedFileBytes != null && _pickedFileName != null) {
        fileUrl = await CourseRepository.uploadFile(
          bytes: _pickedFileBytes!,
          fileName: _pickedFileName!,
        );
      } else if (_needsUrl && _urlCtrl.text.trim().isNotEmpty) {
        fileUrl = _urlCtrl.text.trim();
      }

      final resource = await CourseRepository.createResource(
        widget.courseId,
        widget.lessonId,
        type: _type,
        title: _titleCtrl.text.trim(),
        fileUrl: fileUrl,
        textContent: _needsNote && _noteCtrl.text.trim().isNotEmpty
            ? _noteCtrl.text.trim()
            : null,
      );
      if (mounted) Navigator.of(context).pop(resource);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not add resource. Please try again.'),
            backgroundColor: AppColors.softRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const Text(
                'Add Resource',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),
              const _SheetLabel('Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((t) {
                  final selected = _type == t;
                  return ChoiceChip(
                    label: Text(t[0].toUpperCase() + t.substring(1)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _type = t;
                      _pickedFileName = null;
                      _pickedFileBytes = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : AppColors.muted,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primary
                          : AppColors.muted.withValues(alpha: 0.25),
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const _SheetLabel('Title'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: _needsFilePick ? null : TextInputAction.next,
                onEditingComplete: _needsFilePick
                    ? null
                    : () => FocusScope.of(context).nextFocus(),
                decoration: _inputDeco('e.g. Android Basics PDF'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_needsFilePick) ...[
                const _SheetLabel('File'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: _pickedFileName != null
                            ? AppColors.secondary
                            : AppColors.muted.withValues(alpha: 0.25),
                        width: _pickedFileName != null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _pickedFileName != null
                              ? Icons.check_circle_outline_rounded
                              : Icons.upload_file_rounded,
                          size: 20,
                          color: _pickedFileName != null
                              ? AppColors.secondary
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedFileName ?? 'Tap to pick a file',
                            style: TextStyle(
                              fontSize: 13,
                              color: _pickedFileName != null
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (_needsUrl) ...[
                const _SheetLabel('URL'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _urlCtrl,
                  decoration: _inputDeco('https://...'),
                  keyboardType: TextInputType.url,
                ),
              ],
              if (_needsNote) ...[
                const _SheetLabel('Note Content'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: _inputDeco('Write your note here...'),
                  maxLines: 4,
                  minLines: 3,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Resource'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

class _ResourcePreviewDialog extends StatelessWidget {
  const _ResourcePreviewDialog({
    required this.resource,
    required this.url,
    required this.onDownload,
  });

  final LearningResource resource;
  final String url;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(resource.icon, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      resource.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(child: _previewBody()),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewBody() {
    if (resource.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const _EmptyInlineMessage('Could not load image preview.'),
          ),
        ),
      );
    }
    if (resource.type == 'video') {
      return LessonVideoContent(url: url);
    }
    if (resource.type == 'pdf' || resource.type == 'pdf_notes') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: buildDocumentEmbed(url),
      );
    }
    return _PreviewPlaceholder(icon: Icons.link_rounded, text: url);
  }
}

class _NotePreviewSheet extends StatelessWidget {
  const _NotePreviewSheet({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  height: 1.75,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EmptyInlineMessage extends StatelessWidget {
  const _EmptyInlineMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: const TextStyle(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}
