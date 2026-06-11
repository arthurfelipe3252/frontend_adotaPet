// ignore_for_file: unnecessary_import

import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

import 'package:adota_pet/core/errors/failure.dart';
import 'package:adota_pet/domain/entities/dashboard_data.dart';
import 'package:adota_pet/domain/repositories/reports_repository.dart';

enum ReportsPeriod { threeMonths, sixMonths, twelveMonths, twentyFour }

extension ReportsPeriodExt on ReportsPeriod {
  int get months {
    switch (this) {
      case ReportsPeriod.threeMonths:
        return 3;
      case ReportsPeriod.sixMonths:
        return 6;
      case ReportsPeriod.twelveMonths:
        return 12;
      case ReportsPeriod.twentyFour:
        return 24;
    }
  }

  String get label {
    switch (this) {
      case ReportsPeriod.threeMonths:
        return '3 meses';
      case ReportsPeriod.sixMonths:
        return '6 meses';
      case ReportsPeriod.twelveMonths:
        return '12 meses';
      case ReportsPeriod.twentyFour:
        return '24 meses';
    }
  }
}

class ReportsViewModel extends ChangeNotifier {
  final ReportsRepository repository;

  ReportsViewModel(this.repository);

  bool isLoading = false;
  bool isExporting = false;
  String? error;
  String? exportError;
  DashboardData? data;
  ReportsPeriod period = ReportsPeriod.twelveMonths;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      data = await repository.getDashboard(
        months: period.months,
        topLimit: 10,
        staleDays: 30,
      );
    } catch (e) {
      error =
          e is Failure ? e.message : 'Não foi possível carregar os relatórios.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setPeriod(ReportsPeriod p) async {
    if (period == p) return;
    period = p;
    notifyListeners();
    await load();
  }

  /// Gera o xlsx em memória e retorna os bytes para download.
  Future<Uint8List?> buildXlsx() async {
    isExporting = true;
    exportError = null;
    notifyListeners();

    try {
      final d = data;
      if (d == null) throw Failure('Carregue os dados antes de exportar.');

      final excel = Excel.createExcel();

      // ── Aba: KPIs ──────────────────────────────────────────────────────
      final kpisSheet = excel['KPIs'];
      excel.setDefaultSheet('KPIs');
      _writeKpis(kpisSheet, d.kpis);

      // ── Aba: Adoções por Mês ───────────────────────────────────────────
      final adoptSheet = excel['Adoções por Mês'];
      _writeTimeline(adoptSheet, d.adoptionsTimeline, 'Adoções');

      // ── Aba: Solicitações por Mês ──────────────────────────────────────
      final reqSheet = excel['Solicitações por Mês'];
      _writeTimeline(reqSheet, d.requestsTimeline, 'Solicitações');

      // ── Aba: Funil ─────────────────────────────────────────────────────
      final funnelSheet = excel['Funil de Adoção'];
      _writeFunnel(funnelSheet, d.funnel);

      // ── Aba: Top Pets ──────────────────────────────────────────────────
      final topSheet = excel['Top Pets'];
      _writeTopPets(topSheet, d.topPets);

      // ── Aba: Pets Parados ──────────────────────────────────────────────
      final staleSheet = excel['Pets Parados'];
      _writeStalePets(staleSheet, d.stalePets);

      // Remove aba padrão vazia criada pelo excel
      excel.delete('Sheet1');

      final bytes = excel.encode();
      if (bytes == null) throw Failure('Falha ao codificar o relatório.');
      return Uint8List.fromList(bytes);
    } catch (e) {
      exportError =
          e is Failure ? e.message : 'Erro ao gerar o relatório XLSX.';
      return null;
    } finally {
      isExporting = false;
      notifyListeners();
    }
  }

  // ── Helpers de escrita ───────────────────────────────────────────────────

  static final CellStyle _headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#D2693A'),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
  );

  void _header(Sheet s, int row, List<String> cols) {
    for (var i = 0; i < cols.length; i++) {
      final cell = s.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
      cell.value = TextCellValue(cols[i]);
      cell.cellStyle = _headerStyle;
    }
  }

  void _writeKpis(Sheet s, DashboardKpis k) {
    _header(s, 0, ['Indicador', 'Valor']);
    final rows = [
      ['Pets disponíveis', k.petsDisponivel],
      ['Pets em processo', k.petsEmProcesso],
      ['Pets adotados (total)', k.petsAdotadoTotal],
      ['Pets adotados (mês atual)', k.petsAdotadoMesAtual],
      ['Solicitações pendentes', k.solicitacoesPendentes],
      ['Conversas ativas', k.conversasAtivas],
      ['Mensagens não lidas', k.mensagensNaoLidas],
      ['Taxa de conversão (%)', k.taxaConversaoPct ?? '—'],
      ['Tempo médio de adoção (dias)', k.tempoMedioAdocaoDias ?? '—'],
    ];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(r[0].toString());
      final v = r[1];
      s.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = v is num
          ? DoubleCellValue(v.toDouble())
          : TextCellValue(v.toString());
    }
  }

  void _writeTimeline(Sheet s, List<TimelinePoint> pts, String colLabel) {
    _header(s, 0, ['Mês', colLabel]);
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final month =
          '${p.monthStart.year}-${p.monthStart.month.toString().padLeft(2, '0')}';
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(month);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = IntCellValue(p.count);
    }
  }

  void _writeFunnel(Sheet s, AdoptionFunnel f) {
    _header(s, 0, ['Etapa', 'Quantidade', '% do Total']);
    final total = f.total == 0 ? 1 : f.total;
    final rows = [
      ['Recebidas', f.received],
      ['Em análise', f.inAnalysis],
      ['Aprovadas', f.approved],
      ['Rejeitadas', f.rejected],
    ];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(r[0].toString());
      final qty = r[1] as int;
      s.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = IntCellValue(qty);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          .value = DoubleCellValue((qty / total * 100).roundToDouble());
    }
  }

  void _writeTopPets(Sheet s, List<TopPet> pets) {
    _header(s, 0, ['#', 'Nome', 'Espécie', 'Porte', 'Status', 'Solicitações']);
    for (var i = 0; i < pets.length; i++) {
      final p = pets[i];
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = IntCellValue(i + 1);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = TextCellValue(p.nome);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          .value = TextCellValue(p.especieLabel);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
          .value = TextCellValue(p.porte);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
          .value = TextCellValue(p.status);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1))
          .value = IntCellValue(p.totalRequests);
    }
  }

  void _writeStalePets(Sheet s, List<StalePet> pets) {
    _header(s, 0, ['Nome', 'Espécie', 'Porte', 'Cadastrado em', 'Dias no catálogo']);
    for (var i = 0; i < pets.length; i++) {
      final p = pets[i];
      s.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(p.nome);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = TextCellValue(p.especieLabel);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
          .value = TextCellValue(p.porte);
      final created =
          '${p.createdAt.day.toString().padLeft(2, '0')}/${p.createdAt.month.toString().padLeft(2, '0')}/${p.createdAt.year}';
      s.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
          .value = TextCellValue(created);
      s.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
          .value = IntCellValue(p.diasNoCatalogo);
    }
  }
}