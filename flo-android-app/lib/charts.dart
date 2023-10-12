import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:built_collection/built_collection.dart';
import 'package:faker/faker.dart';
import 'package:flotechnologies/themes.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:charts_common/common.dart' as common;
import 'package:charts_flutter/src/text_element.dart';
import 'package:charts_flutter/src/text_style.dart' as style;
import 'package:superpower/superpower.dart';
import 'model/irrigation_schedule.dart';
import 'model/schedule.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/scheduler.dart';

import 'utils.dart';

class TopTooltipSymbolRenderer extends charts.CircleSymbolRenderer {
  TopTooltipSymbolRenderer({
    this.context,
    this.padding = 8.0,
    this.radius = 8.0,
    this.color = charts.Color.white,
    //this.fontSize = 18,
    this.fontSize = 12,
    this.fontFamily,
    //this.boundRight = 580,
    //this.width = 580,
    this.boundRight = 480,
    this.width = 480,
    this.strokeColor,
    this.fillColor,
    this.isSolid,
    this.strokeWidth = 1.0,
  }) : super(isSolid: isSolid);

  final BuildContext context;
  final double padding;
  final double radius;
  final charts.Color color;
  final int fontSize;
  final String fontFamily;
  Color themeColor;
  final double boundRight;
  final double width;
  final bool isSolid;
  final double strokeWidth;

  String value = "";

  final charts.Color fillColor;
  final charts.Color strokeColor;

  @override
  void paint(charts.ChartCanvas canvas, Rectangle<num> bounds, {List<int> dashPattern, charts.Color fillColor, charts.Color strokeColor, double strokeWidthPx}) {
    //super.paint(canvas, bounds, dashPattern: dashPattern, fillColor: fillColor, strokeColor: strokeColor, strokeWidthPx: strokeWidthPx);
    if (value?.isEmpty ?? false) return;
    final text = TextElement(value, style: style.TextStyle()
      ..color = color
      ..fontSize = fontSize);

    final centerX = text.textPainter.width / 2.0;
    //final centerY = text.textPainter.height / 2.0;
    final width = text.textPainter.width + (padding * 2);
    final height = text.textPainter.height + (padding * 2);
    final top = 0 - text.textPainter.height - (padding * 2);
    final right = bounds.left + width;
    var left = max(bounds.left - centerX - (padding * 2), 0);
    //print(bounds.right);
    if (right > boundRight) {
      left = left - (right - boundRight);
    }
    final bgRect = Rectangle(left, top, width, height);

    //canvas.drawRRect(Rectangle(left, top, bounds.width, bounds.height),
    //canvas.drawRRect(Rectangle(bounds.left, bounds.top, bounds.width, bounds.top - bounds.bottom),
    /*
    canvas.drawRRect(bounds,
        fill: toChartColor(Color(0xFF50CDE4)),
        //stroke: strokeColor,
        radius: radius,
        roundTopLeft: true,
        roundTopRight: true,
        roundBottomRight: true,
        roundBottomLeft: true);
    */

    canvas.drawRRect(
        Rectangle(left - strokeWidth, top - strokeWidth, width + (strokeWidth * 2), height + (strokeWidth * 2)),
        fill: this.strokeColor ?? getSolidFillColor(strokeColor),
        stroke: this.strokeColor ?? strokeColor,
        radius: radius,
        roundTopLeft: true,
        roundTopRight: true,
        roundBottomRight: true,
        roundBottomLeft: true);
    canvas.drawRRect(
        bgRect,
        fill: this.fillColor ?? getSolidFillColor(fillColor),
        stroke: this.strokeColor ?? strokeColor,
        radius: radius,
        roundTopLeft: true,
        roundTopRight: true,
        roundBottomRight: true,
        roundBottomLeft: true);
    canvas.drawText(
      text,
      (bgRect.left + 1 + padding).round(),
      (bgRect.top + 3 + padding).round(),
    );
  }
}

class SimpleTimeSeriesChart extends StatelessWidget {
  const SimpleTimeSeriesChart(this.seriesList);

  /// Creates a [TimeSeriesChart] with sample data and no transition.
  factory SimpleTimeSeriesChart.withSampleData() {
    return SimpleTimeSeriesChart(
      _createSampleData(),
    );
  }

  final List<charts.Series<TimeSeriesSales, DateTime>> seriesList;

  @override
  Widget build(BuildContext context) => charts.TimeSeriesChart(
        seriesList,
        animate: false,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        domainAxis: charts.DateTimeAxisSpec(
          tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
            day: charts.TimeFormatterSpec(
              format: 'EEE',
              transitionFormat: 'EEE',
            ),
          ),
        ),
        behaviors: [
          charts.LinePointHighlighter(
              symbolRenderer: TopTooltipSymbolRenderer()
          ),
          charts.DomainHighlighter(),
        ],
      );

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> _createSampleData() {
    final List<TimeSeriesSales> data = <TimeSeriesSales>[
      TimeSeriesSales(DateTime(2019, 1, 7), 5),
      TimeSeriesSales(DateTime(2019, 1, 8), 25),
      TimeSeriesSales(DateTime(2019, 1, 9), 100),
      TimeSeriesSales(DateTime(2019, 1, 10), 75),
    ];

    return <charts.Series<TimeSeriesSales, DateTime>>[
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.value,
        data: data,
      )
    ];
  }
}

class TimeSeriesSales {
  TimeSeriesSales(
      this.time,
      this.value, {
        this.hint,
      }
      );
  final String hint;
  final DateTime time;
  final int value;
}

class TimeSeries {
  TimeSeries(
      this.time,
      this.value, {
        this.tooltip,
      }
    );
  final String tooltip;
  final DateTime time;
  final double value;
}

class IrrigationScheduleChart extends StatefulWidget {
  const IrrigationScheduleChart(
      this.times, {
        this.padding = 8.0,
        this.radius,
        this.tooltipColor,
        this.fontSize,
        this.color,
        this.width = 400,
    }
  );

  final double padding;
  final double radius;
  final Color color;
  final Color tooltipColor;
  final double fontSize;
  final double width;

  final BuiltList<BuiltList<String>> times;
  //final List<charts.Series<TimeSeries, DateTime>> seriesList;


  factory IrrigationScheduleChart.withSampleData() {
    return IrrigationScheduleChart(sampleSchedule.times);
  }

  @override
  _IrrigationScheduleChartState createState() => _IrrigationScheduleChartState();


  static Schedule get sampleSchedule {
    return Schedule((b) => b
        ..times = ListBuilder<BuiltList<String>>([
          //BuiltList<String>([ "0:48:19", "1:49:20" ]),
          //BuiltList<String>([ "11:08:09", "11:35:12" ]),
          BuiltList<String>([ "18:08:09", "23:35:12" ]),
        ])
      );
  }

  static List<charts.Series<TimeSeries, DateTime>> get sampleData {
    return <charts.Series<TimeSeries, DateTime>>[
      charts.Series<TimeSeries, DateTime>(
        id: 'Irrigation',
        //colorFn: (_, __) => toChartColor(floBlue2),
        areaColorFn: (_, __) => toChartColor(floBlue2),
        domainFn: (TimeSeries series, _) => series.time,
        measureFn: (TimeSeries series, _) => series.value,
        data: toTimeSeries(toLocalDateTimesBuilt(sampleSchedule.times)),
      )
    ];
  }
}

class _IrrigationScheduleChartState extends State<IrrigationScheduleChart> {
  DateTime _sliderDomainValue;
  String _sliderDragState;
  Point<int> _sliderPosition;
  TopTooltipSymbolRenderer _topTooltipSymbolRenderer;
  List<charts.Series<TimeSeries, DateTime>> data;

  @override
  void initState() {
    super.initState();
    _topTooltipSymbolRenderer = TopTooltipSymbolRenderer(
      //context: context,
      padding: widget.padding,
      //radius: widget.radius,
      color: widget.tooltipColor != null ? toChartColor(widget.tooltipColor) : charts.Color.white,
      fontSize: widget?.fontSize?.round() ?? 12,
      boundRight: widget.width,
    );

    data = <charts.Series<TimeSeries, DateTime>>[
      charts.Series<TimeSeries, DateTime>(
        id: 'Irrigation',
        colorFn: (_, __) => toChartColor(widget.color) ?? toChartColor(floBlue2),
        areaColorFn: (_, __) => toChartColor(widget.color) ?? toChartColor(floBlue2),
        domainFn: (TimeSeries series, _) => series.time,
        measureFn: (TimeSeries series, _) => series.value,
        data: toTimeSeries(toLocalDateTimesBuilt(widget.times)),
      )
    ];
  }

  // Handles callbacks when the user drags the slider.
  _onSliderChange(
      Point<int> point,
      dynamic domain, String roleId,
      charts.SliderListenerDragState dragState) {
    // Request a build.
    void rebuild(_) {
      //final domain2 = domain as DateTime;

      setState(() {
        //_sliderDomainValue = (domain * 10).round() / 10;
        _sliderDomainValue = domain;
        _sliderDragState = dragState.toString();
        _sliderPosition = point;
      });
    }

    //SchedulerBinding.instance.addPostFrameCallback(rebuild);
    rebuild(null);
  }
  /*
  charts.LayoutConfig(
      leftMarginSpec: charts.MarginSpec.fromPixel(0),
      topMarginSpec: charts.MarginSpec.fromPixel(0),
      rightMarginSpec: charts.MarginSpec.fromPixel(0),
      bottomMarginSpec: charts.MarginSpec.fromPixel(0),
    )
    */

  @override
  Widget build(BuildContext context) => charts.TimeSeriesChart(
        data,
        layoutConfig: charts.LayoutConfig(
          leftMarginSpec: charts.MarginSpec.fromPixel(minPixel: 5, maxPixel: 5),
          topMarginSpec: charts.MarginSpec.fromPixel(minPixel: 10, maxPixel: 10),
          rightMarginSpec: charts.MarginSpec.fromPixel(minPixel: 10, maxPixel: 10),
          bottomMarginSpec: charts.MarginSpec.fromPixel(minPixel: 0, maxPixel: 0),
        ),
        animate: true,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        defaultRenderer: charts.LineRendererConfig(
          includeArea: true,
          radiusPx: 8.5,
          strokeWidthPx: 0.0,
          includeLine: false,
          includePoints: false,
        ),
        domainAxis: charts.DateTimeAxisSpec(
          showAxisLine: false,
          renderSpec: charts.NoneRenderSpec(),
          //tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
          //  hour: charts.TimeFormatterSpec(
          //    format: 'hh a',
          //    transitionFormat: 'hh a',
          //  ),
          //),
        ),
        primaryMeasureAxis: charts.NumericAxisSpec(renderSpec: charts.NoneRenderSpec()),
        behaviors: [
          charts.LinePointHighlighter(
            showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType.none,
            showVerticalFollowLine: charts.LinePointHighlighterFollowLineType.none,
            symbolRenderer: _topTooltipSymbolRenderer
          ),
          charts.SelectNearest(eventTrigger: charts.SelectionTrigger.tapAndDrag),
          //charts.Slider(initialDomainValue: DateTime.now(), onChangeCallback: _onSliderChange)
        ],
        selectionModels: [
          charts.SelectionModelConfig(
            changedListener: (model) {
              if (model.hasDatumSelection) {
                //selectedData.tooltip
                //final selectedData = model.selectedSeries[0].data[model.selectedSeries[0].seriesIndex] as TimeSeries;
                final selectedData = model.selectedSeries[0].data[model.selectedDatum[0].index] as TimeSeries;
                //_topTooltipSymbolRenderer.value = model.selectedSeries[0].domainFn(model.selectedDatum[0].index).toString();
                //_topTooltipSymbolRenderer.value = model.selectedSeries[0].displayName ?? "";
                _topTooltipSymbolRenderer.value = selectedData.tooltip ?? "";
                //  print(model.selectedSeries[0].measureFn(model.selectedDatum[0].index));
                print(model.selectedSeries[0].domainFn(model.selectedDatum[0].index));
              }
            }
        )
      ],
      );
}

charts.Color toChartColor(Color color) {
  return charts.Color(
      r: color.red,
      g: color.green,
      b: color.blue,
      a: color.alpha);
}

List<DateTime> toLocalDateTimesBuilt(BuiltList<BuiltList<String>> times) {
  return toLocalDateTimes($(times)
      .map((it) => it.toList())
      .toList());
}

List<DateTime> toLocalDateTimes(List<List<String>> times) {
  final now = DateTime.now();

  return $(times)
      .flatMap((it) => it)
//.onEach((it) => print(it))
      .map((it) => it.padLeft(8, '0')) // Fix "1:00:00" to "01:00:00" to avoid parse failure
      .map((time) {
    final date = DateFormat('yyyy-MM-dd').format(now);
    return DateTime.tryParse("${date}T${time}Z");
  })
      .whereNotNull()
      .map((datetime) => datetime.toLocal())
      .map((it) => DateTime(now.year, now.month, now.day, it.hour, it.minute, it.second, it.millisecond, it.microsecond))
      .toList();
}

List<TimeSeries> toTimeSeries(List<DateTime> localDateTimes) {
  final now = DateTime.now();
  final List<TimeSeries> list = $(localDateTimes).windowed(2, (it) {
    final tooltip = "${DateFormat.jm().format(it.first)} - ${DateFormat.jm().format(it.second)}";
    return [
      TimeSeries(it.first.add(Duration(milliseconds: 0)), 0, tooltip: tooltip),
      TimeSeries(it.first, 10, tooltip: tooltip),
      TimeSeries(it.second, 10, tooltip: tooltip),
      TimeSeries(it.second.add(Duration(milliseconds: 0)), 0, tooltip: tooltip),
    ];
  }, step: 2)
      .flatMap((it) => it)
      .toList();

  final list2 = [
    [ TimeSeries(DateTime.tryParse("${DateFormat('yyyy-MM-dd').format(now)} 00:00:00"), 0), ],
    list,
    [ TimeSeries(DateTime.tryParse("${DateFormat('yyyy-MM-dd').format(now)} 23:59:59"), 0), ]
  ];

  return $(list2).flatMap((it) => it)
      .sortedBy((it) => it.time.millisecondsSinceEpoch)
      .toList();
}

List<charts.Series<TimeSeries, DateTime>> toChartTimeSeriesBuilt(BuiltList<BuiltList<String>> times) {
  return <charts.Series<TimeSeries, DateTime>>[
    charts.Series<TimeSeries, DateTime>(
      id: 'Irrigation',
      colorFn: (_, __) => toChartColor(floBlue2),
      areaColorFn: (_, __) => toChartColor(floBlue2),
      domainFn: (TimeSeries series, _) => series.time,
      measureFn: (TimeSeries series, _) => series.value,
      data: toTimeSeries(toLocalDateTimesBuilt(times)),
    )
  ];
}

class WaterUsageBarChart extends StatefulWidget {
  const WaterUsageBarChart(
      this.times, {
        Key key,
        this.padding = 8.0,
        this.radius,
        this.tooltipColor,
        this.fontSize,
        this.color,
        this.width = 400,
        this.tooltipFillColor,
        this.tooltipStrokeColor,
      }) : super (key: key);

  final double padding;
  final double radius;
  final Color color;
  final Color tooltipColor;
  final Color tooltipFillColor;
  final Color tooltipStrokeColor;
  final double fontSize;
  final double width;

  final List<TimeSeries> times;
  //final List<charts.Series<TimeSeries, DateTime>> seriesList;

  static List<TimeSeries> get sample7 {
    final today = DateTimes.lastWeekday(6);
    return Iterable<int>.generate(7).map((it) => TimeSeries(
        today.add(Duration(days: it)), faker.randomGenerator.decimal(scale: 5),
        tooltip: "${DateFormat.EEEE().format(today.add(Duration(days: it)))}"
    )).toList();
  }

  static List<TimeSeries> get sample24 {
    final today = DateTimes.today();
    return Iterable<int>.generate(24).map((it) => TimeSeries(
        today.add(Duration(hours: it)), faker.randomGenerator.decimal(scale: 5),
        tooltip: "${DateFormat('h a').format(today.add(Duration(hours: it)))}"
    )).toList();
  }

  static List<TimeSeries> get sample {
    final now = DateTime.now();
    //Iterable<int>.generate(24).map((it) => TimeSeries(
    //    today.add(Duration(hours: it)), it.toDouble(),
    //    tooltip: "${today.add(Duration(hours: it))}"
    //)).toList();
    return [
      TimeSeries(now.add(Duration(hours: 0)), 5, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 1)), 8, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 2)), 8, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 3)), 3, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 4)), 2, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 5)), 1, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 6)), 5, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 7)), 8, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 8)), 3, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 9)), 2, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 10)), 1, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 11)), 5, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 12)), 8, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 13)), 3, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 14)), 2, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 15)), 1, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 16)), 2, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 17)), 1, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 18)), 4, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 19)), 1, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 20)), 3, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 21)), 2, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 22)), 3, tooltip: now.toIso8601String()),
      TimeSeries(now.add(Duration(hours: 23)), 4, tooltip: now.toIso8601String()),
    ];
  }

  factory WaterUsageBarChart.withSampleData() {
    return WaterUsageBarChart(sample);
  }

  @override
  _WaterUsageBarChartState createState() => _WaterUsageBarChartState();
}

class _WaterUsageBarChartState extends State<WaterUsageBarChart> with AfterLayoutMixin<WaterUsageBarChart> {
  DateTime _sliderDomainValue;
  String _sliderDragState;
  Point<int> _sliderPosition;
  TopTooltipSymbolRenderer _topTooltipSymbolRenderer;
  List<charts.Series<TimeSeries, DateTime>> _data;
  bool _animate;

  @override
  void initState() {
    super.initState();
    _topTooltipSymbolRenderer = TopTooltipSymbolRenderer(
      //context: context,
      padding: widget.padding,
      //radius: widget.radius,
      color: widget.tooltipColor != null ? toChartColor(widget.tooltipColor) : charts.Color.white,
      fillColor: widget.tooltipFillColor != null ? toChartColor(widget.tooltipFillColor) : null,
      strokeColor: widget.tooltipStrokeColor != null ? toChartColor(widget.tooltipStrokeColor) : null,
      fontSize: widget?.fontSize?.round() ?? 12,
      boundRight: widget.width,
      isSolid: false,
    );
    _data = <charts.Series<TimeSeries, DateTime>>[
      charts.Series<TimeSeries, DateTime>(
        id: 'WaterUsage',
        colorFn: (series, value) {
          return toChartColor(widget.color ?? floBlue2);
        },
        areaColorFn: (_, __) => toChartColor(widget.color ?? floBlue2),
        domainFn: (TimeSeries series, _) => series.time,
        measureFn: (TimeSeries series, _) => series.value,
        data: widget.times ?? [],
      )
    ];
    _animate = true;
    _loading = false;
  }

  Timer _debounce;

  @override
  void didUpdateWidget(WaterUsageBarChart oldWidget) {
    if (!(_debounce?.isActive ?? false)) {
      if (oldWidget.times != widget.times) {
        _animate = true;
        _data = <charts.Series<TimeSeries, DateTime>>[
          charts.Series<TimeSeries, DateTime>(
            id: 'WaterUsage',
            colorFn: (series, value) {
              return toChartColor(widget.color ?? floBlue2);
            },
            areaColorFn: (_, __) => toChartColor(widget.color ?? floBlue2),
            domainFn: (TimeSeries series, _) => series.time,
            measureFn: (TimeSeries series, _) => series.value,
            data: widget.times ?? [],
          )
        ];
        invalidate(context);
      } else {
        //_animate = false;
      }
    } else {
      _debounce = Timer(const Duration(milliseconds: 1000), () {});
    }
    super.didUpdateWidget(oldWidget);
  }

  void invalidate(BuildContext context, {Duration duration = const Duration(milliseconds: 500)}) {
    if (_loading) return;
    _loading = true;
    Future.delayed(duration, () {
      _chart = charts.TimeSeriesChart(
        _data,
        defaultRenderer: charts.BarRendererConfig(
          cornerStrategy: charts.ConstCornerStrategy(8),
        ),
        defaultInteractions: true,
        layoutConfig: charts.LayoutConfig(
          leftMarginSpec: charts.MarginSpec.fromPixel(minPixel: 0, maxPixel: 0),
          topMarginSpec: charts.MarginSpec.fromPixel(
              minPixel: 10, maxPixel: 10),
          rightMarginSpec: charts.MarginSpec.fromPixel(
              minPixel: 0, maxPixel: 0),
          bottomMarginSpec: charts.MarginSpec.fromPixel(
              minPixel: 0, maxPixel: 0),
        ),
        animate: _animate,
        dateTimeFactory: const charts.LocalDateTimeFactory(),
        domainAxis: charts.DateTimeAxisSpec(
          showAxisLine: false,
          renderSpec: charts.NoneRenderSpec(),
          //tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
          //  hour: charts.TimeFormatterSpec(
          //    format: 'hh a',
          //    transitionFormat: 'hh a',
          //  ),
          //),
        ),
        primaryMeasureAxis: charts.NumericAxisSpec(
            renderSpec: charts.NoneRenderSpec()),
        behaviors: [
          charts.LinePointHighlighter(
            showHorizontalFollowLine: charts.LinePointHighlighterFollowLineType
                .none,
            showVerticalFollowLine: charts.LinePointHighlighterFollowLineType
                .none,
            symbolRenderer: _topTooltipSymbolRenderer,
          ),
          charts.SelectNearest(
              eventTrigger: charts.SelectionTrigger.tapAndDrag),
          //charts.Slider(initialDomainValue: DateTime.now(), onChangeCallback: _onSliderChange)
        ],
        selectionModels: [
          charts.SelectionModelConfig(
              changedListener: (model) {
                if (model.hasDatumSelection) {
                  //selectedData.tooltip
                  //final selectedData = model.selectedSeries[0].data[model.selectedSeries[0].seriesIndex] as TimeSeries;
                  final selectedData = model.selectedSeries[0].data[model
                      .selectedDatum[0].index] as TimeSeries;
                  //_topTooltipSymbolRenderer.value = model.selectedSeries[0].domainFn(model.selectedDatum[0].index).toString();
                  //_topTooltipSymbolRenderer.value = model.selectedSeries[0].displayName ?? "";
                  _topTooltipSymbolRenderer.value = selectedData.tooltip ?? "";
                  //  print(model.selectedSeries[0].measureFn(model.selectedDatum[0].index));
                  print(model.selectedSeries[0].domainFn(
                      model.selectedDatum[0].index));
                }
              }
          )
        ],
      );
      _loading = false;
      setState(() {});
    });
  }

  Widget _chart;
  bool _loading;

  @override
  Widget build(BuildContext context) {
    return _chart ?? Container();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    invalidate(context, duration: Duration.zero);
  }
}
