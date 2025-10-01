import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/chart_data.dart';

class InteractiveStockChart extends StatefulWidget {
  final String stockCode;
  final List<CandleData> data;
  final ChartSettings settings;
  final Function(ChartSettings) onSettingsChanged;

  const InteractiveStockChart({
    super.key,
    required this.stockCode,
    required this.data,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<InteractiveStockChart> createState() => _InteractiveStockChartState();
}

class _InteractiveStockChartState extends State<InteractiveStockChart> {
  int _touchedIndex = -1;
  double _zoomLevel = 1.0;
  double _panOffset = 0.0;
  bool _isPanning = false;
  Offset? _lastPanPosition;

  // 차트에 표시할 데이터 범위 계산
  List<CandleData> get _visibleData {
    if (widget.data.isEmpty) return [];
    
    final totalCount = widget.data.length;
    final visibleCount = (totalCount / _zoomLevel).round().clamp(10, totalCount);
    final startIndex = (_panOffset * (totalCount - visibleCount)).round().clamp(0, totalCount - visibleCount);
    final endIndex = (startIndex + visibleCount).clamp(visibleCount, totalCount);
    
    return widget.data.sublist(startIndex, endIndex);
  }

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.settings.zoomLevel;
    _panOffset = widget.settings.panOffset;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // 상단 컨트롤 패널
        _buildControlPanel(),
        
        // 메인 차트 영역
        Expanded(
          flex: 7,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: Listener(
              onPointerSignal: _onPointerSignal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LineChart(_buildChartData()),
              ),
            ),
          ),
        ),
        
        // 거래량 차트 영역  
        if (widget.settings.showVolume)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: BarChart(_buildVolumeData()),
            ),
          ),
        
        // 터치 정보 패널
        if (_touchedIndex >= 0 && _touchedIndex < _visibleData.length)
          _buildTouchInfoPanel(),
      ],
    );
  }

  // 마우스 휠 줌 인/아웃 처리
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {
        if (event.scrollDelta.dy > 0) {
          // 줌 아웃
          _zoomLevel = (_zoomLevel * 0.9).clamp(0.1, 10.0);
        } else {
          // 줌 인
          _zoomLevel = (_zoomLevel * 1.1).clamp(0.1, 10.0);
        }
        
        // 설정 업데이트
        widget.onSettingsChanged(widget.settings.copyWith(zoomLevel: _zoomLevel));
      });
    }
  }

  // 패닝 시작
  void _onPanStart(DragStartDetails details) {
    _isPanning = true;
    _lastPanPosition = details.localPosition;
  }

  // 패닝 업데이트
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPanning || _lastPanPosition == null) return;

    setState(() {
      final deltaX = details.localPosition.dx - _lastPanPosition!.dx;
      final sensitivity = 0.001;
      _panOffset = (_panOffset - deltaX * sensitivity).clamp(0.0, 1.0);
      _lastPanPosition = details.localPosition;
      
      // 설정 업데이트
      widget.onSettingsChanged(widget.settings.copyWith(panOffset: _panOffset));
    });
  }

  // 패닝 종료
  void _onPanEnd(DragEndDetails details) {
    _isPanning = false;
    _lastPanPosition = null;
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // 첫 번째 행: 시간 단위 선택
          Row(
            children: [
              const Text('시간단위: ', style: TextStyle(fontWeight: FontWeight.bold)),
              ...ChartTimeFrame.values.map((timeFrame) => 
                _buildTimeFrameButton(timeFrame)),
            ],
          ),
          const SizedBox(height: 8),
          
          // 두 번째 행: 이동평균선 토글 및 확대/축소 정보
          Row(
            children: [
              const Text('이동평균: ', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildMAToggle('5', widget.settings.showMA5, (value) => 
                widget.onSettingsChanged(widget.settings.copyWith(showMA5: value))),
              _buildMAToggle('20', widget.settings.showMA20, (value) => 
                widget.onSettingsChanged(widget.settings.copyWith(showMA20: value))),
              _buildMAToggle('60', widget.settings.showMA60, (value) => 
                widget.onSettingsChanged(widget.settings.copyWith(showMA60: value))),
              _buildMAToggle('120', widget.settings.showMA120, (value) => 
                widget.onSettingsChanged(widget.settings.copyWith(showMA120: value))),
              
              const Spacer(),
              
              // 줌 레벨 표시
              Text('줌: ${(_zoomLevel * 100).toStringAsFixed(0)}%', 
                   style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 16),
              
              // 리셋 버튼
              ElevatedButton(
                onPressed: _resetView,
                child: const Text('리셋'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameButton(ChartTimeFrame timeFrame) {
    final isSelected = widget.settings.timeFrame == timeFrame;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ChoiceChip(
        label: Text(timeFrame.displayName),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            widget.onSettingsChanged(widget.settings.copyWith(timeFrame: timeFrame));
          }
        },
        selectedColor: Colors.blue.shade100,
        labelStyle: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildMAToggle(String period, bool isSelected, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) => onChanged(value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          GestureDetector(
            onTap: () => onChanged(!isSelected),
            child: Text(
              period,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? _getMAColor(period) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMAColor(String period) {
    switch (period) {
      case '5': return Colors.purple;
      case '20': return Colors.red;
      case '60': return Colors.orange;
      case '120': return Colors.green;
      default: return Colors.blue;
    }
  }

  void _resetView() {
    setState(() {
      _zoomLevel = 1.0;
      _panOffset = 0.0;
      widget.onSettingsChanged(widget.settings.copyWith(
        zoomLevel: 1.0,
        panOffset: 0.0,
      ));
    });
  }

  LineChartData _buildChartData() {
    final visibleData = _visibleData;
    if (visibleData.isEmpty) return LineChartData();

    return LineChartData(
      lineBarsData: [
        // 종가 라인
        LineChartBarData(
          spots: visibleData.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.close);
          }).toList(),
          color: Colors.blue,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
        ),
        
        // 5일 이동평균선
        if (widget.settings.showMA5)
          _buildMALine(visibleData, (data) => data.ma5, _getMAColor('5')),
        
        // 20일 이동평균선
        if (widget.settings.showMA20)
          _buildMALine(visibleData, (data) => data.ma20, _getMAColor('20')),
        
        // 60일 이동평균선
        if (widget.settings.showMA60)
          _buildMALine(visibleData, (data) => data.ma60, _getMAColor('60')),
        
        // 120일 이동평균선
        if (widget.settings.showMA120)
          _buildMALine(visibleData, (data) => data.ma120, _getMAColor('120')),
      ],
      
      // 터치 이벤트 처리
      lineTouchData: LineTouchData(
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          if (!_isPanning) {
            setState(() {
              if (touchResponse != null && touchResponse.lineBarSpots != null) {
                _touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
              } else {
                _touchedIndex = -1;
              }
            });
          }
        },
        handleBuiltInTouches: !_isPanning,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => Colors.black.withOpacity(0.8),
        ),
      ),
      
      // 축 설정
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                NumberFormat('#,###').format(value.toInt()),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: (visibleData.length / 6).ceilToDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < visibleData.length) {
                final date = visibleData[index].dateTime;
                return Text(
                  _formatDateForTimeFrame(date, widget.settings.timeFrame),
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      
      // 격자
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300,
          strokeWidth: 0.5,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.shade300,
          strokeWidth: 0.5,
        ),
      ),
      
      // 테두리
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade400),
      ),
      
      // 축 범위
      minX: 0,
      maxX: (visibleData.length - 1).toDouble(),
      minY: _getMinPrice(visibleData),
      maxY: _getMaxPrice(visibleData),
    );
  }

  LineChartBarData _buildMALine(
    List<CandleData> data,
    double? Function(CandleData) getValue,
    Color color,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final value = getValue(data[i]);
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    
    return LineChartBarData(
      spots: spots,
      color: color,
      barWidth: 1,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
    );
  }

  BarChartData _buildVolumeData() {
    final visibleData = _visibleData;
    if (visibleData.isEmpty) return BarChartData();

    return BarChartData(
      barGroups: visibleData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isUp = data.close >= data.open;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.volume.toDouble(),
              color: isUp ? Colors.red.withOpacity(0.7) : Colors.blue.withOpacity(0.7),
              width: 2,
            ),
          ],
        );
      }).toList(),
      
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatVolume(value.toInt()),
                style: const TextStyle(fontSize: 9),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      
      gridData: FlGridData(show: false),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade400),
      ),
      
      maxY: _getMaxVolume(visibleData),
    );
  }

  Widget _buildTouchInfoPanel() {
    final data = _visibleData[_touchedIndex];
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildInfoItem('날짜', _formatDateTimeForDisplay(data.dateTime, widget.settings.timeFrame)),
          _buildInfoItem('시가', NumberFormat('#,###').format(data.open)),
          _buildInfoItem('고가', NumberFormat('#,###').format(data.high)),
          _buildInfoItem('저가', NumberFormat('#,###').format(data.low)),
          _buildInfoItem('종가', NumberFormat('#,###').format(data.close)),
          _buildInfoItem('거래량', NumberFormat('#,###').format(data.volume)),
          if (data.ma5 != null) _buildInfoItem('5일선', NumberFormat('#,###').format(data.ma5!)),
          if (data.ma20 != null) _buildInfoItem('20일선', NumberFormat('#,###').format(data.ma20!)),
          if (data.ma60 != null) _buildInfoItem('60일선', NumberFormat('#,###').format(data.ma60!)),
          if (data.ma120 != null) _buildInfoItem('120일선', NumberFormat('#,###').format(data.ma120!)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 헬퍼 메서드들
  double _getMinPrice(List<CandleData> data) {
    if (data.isEmpty) return 0;
    return data.map((e) => e.low).reduce((a, b) => a < b ? a : b) * 0.98;
  }

  double _getMaxPrice(List<CandleData> data) {
    if (data.isEmpty) return 100;
    return data.map((e) => e.high).reduce((a, b) => a > b ? a : b) * 1.02;
  }

  double _getMaxVolume(List<CandleData> data) {
    if (data.isEmpty) return 1000;
    return data.map((e) => e.volume).reduce((a, b) => a > b ? a : b).toDouble() * 1.1;
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(0)}K';
    }
    return volume.toString();
  }

  String _formatDateForTimeFrame(DateTime date, ChartTimeFrame timeFrame) {
    switch (timeFrame.periodType) {
      case 'T': // 분/시간
        return DateFormat('HH:mm').format(date);
      case 'D': // 일
        return DateFormat('MM/dd').format(date);
      case 'W': // 주
        return DateFormat('MM/dd').format(date);
      case 'M': // 월
        return DateFormat('yy/MM').format(date);
      default:
        return DateFormat('MM/dd').format(date);
    }
  }

  String _formatDateTimeForDisplay(DateTime date, ChartTimeFrame timeFrame) {
    switch (timeFrame.periodType) {
      case 'T': // 분/시간
        return DateFormat('yyyy-MM-dd HH:mm').format(date);
      case 'D': // 일
        return DateFormat('yyyy-MM-dd').format(date);
      case 'W': // 주
        return DateFormat('yyyy-MM-dd').format(date);
      case 'M': // 월
        return DateFormat('yyyy-MM').format(date);
      default:
        return DateFormat('yyyy-MM-dd').format(date);
    }
  }
}