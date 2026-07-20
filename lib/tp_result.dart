import 'package:tradplus_sdk/tradplus_sdk.dart';

final tpResult = TPResult();

class TPResult {
  /// 多条 TradPlus 广告位 ID 按缓存 eCPM 从高到低排序
  Future<List<String>> handleAdUnitId(List<String> adUnitIds) async {
    final result = await TradplusSdk.channel.invokeMethod(
      'tpresult_handleAdUnitId',
      {'adUnitIds': adUnitIds},
    );
    if (result == null) {
      return [];
    }
    return List<String>.from(result);
  }

  /// TradPlus 广告位与第三方自定义价格混合比价，结果从高到低排序
  /// mixAdInfoList 每项传入 adUnitId 或 ecpm 其一即可
  Future<List<Map<String, dynamic>>> handleMix(
      List<Map<String, dynamic>> mixAdInfoList) async {
    final result = await TradplusSdk.channel.invokeMethod(
      'tpresult_handleMix',
      {'mixAdInfoList': mixAdInfoList},
    );
    if (result == null) {
      return [];
    }
    return (result as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
