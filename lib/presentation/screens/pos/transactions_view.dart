import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';

/// Halaman Transaksi Kato POS sesuai persis dengan referensi gambar terbaru.
/// Menampilkan:
/// 1. Top bar ungu (#5247A1) dengan tombol kembali (<-) dan judul "Transaksi"
/// 2. Filter & pencarian: Search input produk/SKU, Rentang Tanggal, Status, & Metode Pembayaran
/// 3. Tabel Riwayat Transaksi (Sisi Kiri) dengan header ungu dan badge warna status/metode
/// 4. Panel "Detail Pesanan" (Sisi Kanan) dengan rincian item, detail pembayaran,
///    pilihan format struk ("Dengan Total" & "Tanpa Total"), serta tombol "Unduh Struk".
class TransactionsView extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;

  const TransactionsView({
    super.key,
    this.onBackPressed,
  });

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _selectedStatus = 'Semua Status';
  String _selectedMethod = 'Metode Pembayaran';
  SaleRecord? _selectedSale;
  String _receiptFormat = 'A'; // 'A' = Dengan Total, 'B' = Tanpa Total
  bool _isDetailClosed = true;

  @override
  void initState() {
    super.initState();
    // Tarik data riwayat transaksi terkini dari backend API Kato POS (/api/v1/sales)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(salesProvider.notifier).fetchSalesFromApi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5247A1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  List<SaleRecord> _filterSales(List<SaleRecord> allSales) {
    return allSales.where((sale) {
      // 1. Filter Search (Invoice / Nama Produk / SKU)
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final matchesInvoice = sale.invoiceNumber.toLowerCase().contains(query);
        final matchesItem = sale.items.any((item) =>
            item.productName.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query));
        if (!matchesInvoice && !matchesItem) return false;
      }

      // 2. Filter Status
      if (_selectedStatus != 'Semua Status') {
        final statusStr = sale.status.name.toLowerCase();
        if (_selectedStatus == 'Completed' && statusStr != 'completed') {
          return false;
        }
        if (_selectedStatus == 'Pending' && statusStr != 'pending') {
          return false;
        }
        if (_selectedStatus == 'Cancelled' && statusStr != 'cancelled') {
          return false;
        }
      }

      // 3. Filter Metode Pembayaran
      if (_selectedMethod != 'Metode Pembayaran' && _selectedMethod != 'Semua Metode') {
        if (_selectedMethod == 'Tunai' && sale.paymentMethod != PaymentMethod.cash) {
          return false;
        }
        if (_selectedMethod == 'QRIS' && sale.paymentMethod != PaymentMethod.qris) {
          return false;
        }
      }

      // 4. Filter Rentang Tanggal
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (sale.createdAt.isBefore(start) || sale.createdAt.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allSales = ref.watch(salesProvider);
    final filteredSales = _filterSales(allSales);

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Column(
        children: [
          // -------------------------------------------------------------------
          // 1. Top Bar Ungu Transaksi (Sesuai Screenshot: #5247A1)
          // -------------------------------------------------------------------
          Container(
            color: const Color(0xFF5247A1),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Kembali ke Beranda',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Transaksi',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // -------------------------------------------------------------------
          // 2. Area Konten Utama (Tabel di Kiri & Detail di Kanan Side-by-Side)
          // -------------------------------------------------------------------
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              left: true,
              right: true,
              child: screenWidth >= 700
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sisi Kiri: Filter Bar + Tabel Transaksi
                        Expanded(
                          child: Column(
                            children: [
                              _buildFilterBar(),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                  child: _buildTransactionsTable(
                                    filteredSales,
                                    _selectedSale,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sisi Kanan: Panel Detail Pesanan (jika aktif) - Menempel di kanan berdampingan
                        if (_selectedSale != null && !_isDetailClosed)
                          Container(
                            width: 360,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                left: BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: _buildOrderDetailCard(_selectedSale!),
                          ),
                      ],
                    )
                  : Stack(
                      children: [
                        Column(
                          children: [
                            _buildFilterBar(),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: _buildTransactionsTable(
                                  filteredSales,
                                  _selectedSale,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedSale != null && !_isDetailClosed) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => setState(() => _isDetailClosed = true),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            bottom: 0,
                            right: 0,
                            width: screenWidth * 0.9,
                            child: _buildOrderDetailCard(_selectedSale!),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Bar Filter & Pencarian
  // ---------------------------------------------------------------------------
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final searchWidget = Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cari nama produk atau SKU',
                hintStyle: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 13.5,
                color: Color(0xFF1E293B),
              ),
            ),
          );

          final dateWidget = InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedDateRange != null
                          ? '${_selectedDateRange!.start.day} ${_shortMonth(_selectedDateRange!.start.month)} - ${_selectedDateRange!.end.day} ${_shortMonth(_selectedDateRange!.end.month)}'
                          : 'Pilih rentang tanggal',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 13,
                        color: _selectedDateRange != null
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          );

          final statusWidget = Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Semua Status',
                    child: Text('Semua Status'),
                  ),
                  DropdownMenuItem(
                    value: 'Completed',
                    child: Text('Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'Pending',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem(
                    value: 'Cancelled',
                    child: Text('Cancelled'),
                  ),
                ],
              ),
            ),
          );

          final methodWidget = Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMethod,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMethod = val);
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Metode Pembayaran',
                    child: Text('Metode Pembayaran'),
                  ),
                  DropdownMenuItem(
                    value: 'Tunai',
                    child: Text('Tunai'),
                  ),
                  DropdownMenuItem(
                    value: 'QRIS',
                    child: Text('QRIS'),
                  ),
                ],
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchWidget,
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      SizedBox(width: 180, child: dateWidget),
                      const SizedBox(width: 8),
                      SizedBox(width: 130, child: statusWidget),
                      const SizedBox(width: 8),
                      SizedBox(width: 160, child: methodWidget),
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 7, child: searchWidget),
              const SizedBox(width: 8),
              Expanded(flex: 7, child: dateWidget),
              const SizedBox(width: 8),
              Expanded(flex: 3, child: statusWidget),
              const SizedBox(width: 8),
              Expanded(flex: 4, child: methodWidget),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Tabel Riwayat Transaksi (Sisi Kiri)
  // ---------------------------------------------------------------------------
  Widget _buildTransactionsTable(
    List<SaleRecord> sales,
    SaleRecord? selectedSale,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Tabel Ungu (#5247A1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF5247A1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'No. Transaksi',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Waktu Transaksi',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Metode Pembayaran',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Baris-Baris Data Transaksi
          Expanded(
            child: sales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada data transaksi yang sesuai.',
                          style: TextStyle(
                            fontFamily: 'Open Sans',
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: sales.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final sale = sales[index];
                      final isSelected = selectedSale?.id == sale.id;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSale = sale;
                            _isDetailClosed = false;
                          });
                        },
                        child: Container(
                          color: isSelected
                              ? const Color(0xFFF5F3FF)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // 1. No. Transaksi
                              Expanded(
                                flex: 1,
                                child: Text(
                                  sale.invoiceNumber,
                                  style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),

                              // 2. Waktu Transaksi
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppFormatters.formatFullDate(sale.createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppFormatters.formatTimeOnly(sale.createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Metode Pembayaran (Badge Capsule)
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F0FA),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      sale.paymentMethod == PaymentMethod.qris
                                          ? 'QRIS'
                                          : 'Tunai',
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5247A1),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 4. Status (Badge Capsule)
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sale.status == TransactionStatus.completed
                                          ? const Color(0xFFE8F8EE)
                                          : (sale.status == TransactionStatus.pending
                                              ? const Color(0xFFFEF3C7)
                                              : const Color(0xFFFEE2E2)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _displayStatus(sale.status),
                                      style: TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: sale.status == TransactionStatus.completed
                                            ? const Color(0xFF28A555)
                                            : (sale.status == TransactionStatus.pending
                                                ? const Color(0xFFD97706)
                                                : const Color(0xFFDC2626)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // 5. Total
                              Expanded(
                                flex: 1,
                                child: Text(
                                  AppFormatters.formatRupiah(sale.totalAmount),
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Panel "Detail Pesanan" (Sisi Kanan)
  // ---------------------------------------------------------------------------
  Widget _buildOrderDetailCard(SaleRecord sale) {
    final isCash = sale.paymentMethod == PaymentMethod.cash;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Judul "Detail Pesanan" dan Tombol Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Pesanan',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isDetailClosed = true),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metadata Transaksi & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.invoiceNumber,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppFormatters.formatFullDateTimeWib(sale.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sale.cashierName.isNotEmpty ? sale.cashierName : 'Sekarisma Putri',
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF28A555),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // -----------------------------------------------------------------
            // Daftar Pesanan
            // -----------------------------------------------------------------
            const Text(
              'Daftar Pesanan',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Header Mini Tabel
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Produk',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            'SKU',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            'Qty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            'Harga',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Subtotal',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Daftar Item Pesanan
                  for (var i = 0; i < sale.items.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              sale.items[i].productName,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12.5,
                                color: Color(0xFF1E293B),
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text(
                              sale.items[i].sku.isNotEmpty
                                  ? sale.items[i].sku
                                  : 'P000${i + 1}',
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${sale.items[i].qty}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              AppFormatters.formatRupiah(sale.items[i].unitPrice),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              AppFormatters.formatRupiah(sale.items[i].subtotal),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Open Sans',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // -----------------------------------------------------------------
            // Detail Pembayaran
            // -----------------------------------------------------------------
            const Text(
              'Detail Pembayaran',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildPaymentSummaryRow(
                    'Subtotal',
                    AppFormatters.formatRupiah(sale.totalAmount),
                  ),
                  const SizedBox(height: 8),

                  // Garis Putus-putus
                  _buildDashedDivider(),
                  const SizedBox(height: 8),

                  _buildPaymentSummaryRow(
                    'Total',
                    AppFormatters.formatRupiah(sale.totalAmount),
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentSummaryRow(
                    'Metode Pembayaran',
                    isCash ? 'Tunai' : 'QRIS',
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentSummaryRow(
                    'Uang Diterima',
                    AppFormatters.formatRupiah(
                      sale.amountPaid > 0 ? sale.amountPaid : sale.totalAmount,
                    ),
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentSummaryRow(
                    'Uang Kembalian',
                    AppFormatters.formatRupiah(sale.changeAmount),
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // -----------------------------------------------------------------
            // Pilih Format Struk (Dengan Total & Tanpa Total)
            // -----------------------------------------------------------------
            const Text(
              'Pilih Format Struk',
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildRadioOption('Dengan Total', 'A'),
                const SizedBox(width: 16),
                _buildRadioOption('Tanpa Total', 'B'),
              ],
            ),
            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // Tombol Unduh Struk (Filled Purple #5247A1)
            // -----------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  showSaleReceiptDialog(
                    context,
                    sale,
                    showTotals: _receiptFormat == 'A',
                  );
                },
                icon: const Icon(
                  Icons.file_download_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text(
                  'Unduh Struk',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5247A1),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildRadioOption(String label, String value) {
    final isSelected = _receiptFormat == value;

    return InkWell(
      onTap: () => setState(() => _receiptFormat = value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5247A1)
                      : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF5247A1),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Open Sans',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _shortMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}
