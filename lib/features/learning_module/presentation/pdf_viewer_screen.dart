import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../domain/learning_module.dart';

class PdfViewerScreen extends StatefulWidget {
  final LearningModule module;

  const PdfViewerScreen({
    super.key,
    required this.module,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _retryLoad() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _reloadKey++;
    });
  }

  void _showModuleInfoModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.module.category,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.module.version,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.module.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.module.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ukuran: ${widget.module.formattedFileSize}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                Text(
                  'Pembaruan: ${AppDateFormatter.formatShort(widget.module.updatedAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.tryParse(widget.module.pdfUrl);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.module.version} • Halaman $_currentPage dari ${_pageCount > 0 ? _pageCount : widget.module.totalPages}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Detail Modul',
            onPressed: _showModuleInfoModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang',
            onPressed: _retryLoad,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Buka Eksternal',
            onPressed: _openExternalBrowser,
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.module.pdfUrl,
            key: ValueKey(_reloadKey),
            controller: _pdfViewerController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
                _pageCount = details.document.pages.count;
                _errorMessage = null;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    'Gagal memuat dokumen PDF: ${details.description}.\nSilakan periksa koneksi internet Anda atau coba lagi.';
              });
            },
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.9),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Memuat dokumen PDF modul...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error Overlay with Retry
          if (_errorMessage != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.error),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal Membuka Dokumen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openExternalBrowser,
                          icon: const Icon(Icons.open_in_browser_rounded),
                          label: const Text('Buka di Browser'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _retryLoad,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out_rounded),
                  tooltip: 'Perkecil',
                  onPressed: () {
                    _pdfViewerController.zoomLevel =
                        (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_in_rounded),
                  tooltip: 'Perbesar',
                  onPressed: () {
                    _pdfViewerController.zoomLevel =
                        (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
                  },
                ),
              ],
            ),
            Text(
              'Hal $_currentPage / ${_pageCount > 0 ? _pageCount : widget.module.totalPages}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Halaman Sebelumnya',
                  onPressed: _currentPage > 1
                      ? () => _pdfViewerController.previousPage()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Halaman Selanjutnya',
                  onPressed: _currentPage < (_pageCount > 0 ? _pageCount : widget.module.totalPages)
                      ? () => _pdfViewerController.nextPage()
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
