package com.tradplus.flutter;

import android.text.TextUtils;

import com.tradplus.ads.base.bean.MixAdInfo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TPResult {
    private final com.tradplus.ads.mgr.TPResult mNativeResult;

    public TPResult() {
        mNativeResult = new com.tradplus.ads.mgr.TPResult();
    }

    public List<String> handleAdUnitId(List<String> adUnitIds) {
        return mNativeResult.handleAdUnitId(adUnitIds);
    }

    public List<Map<String, Object>> handleMix(List<Map<String, Object>> mixAdInfoList) {
        List<MixAdInfo> mixList = toMixAdInfoList(mixAdInfoList);
        List<MixAdInfo> result = mNativeResult.handleMix(mixList);
        return toMapList(result);
    }

    private List<MixAdInfo> toMixAdInfoList(List<Map<String, Object>> mixAdInfoList) {
        ArrayList<MixAdInfo> mixList = new ArrayList<>();
        if (mixAdInfoList == null) {
            return mixList;
        }
        for (Map<String, Object> map : mixAdInfoList) {
            if (map == null) {
                continue;
            }
            MixAdInfo info = new MixAdInfo();
            Object adUnitId = map.get("adUnitId");
            if (adUnitId instanceof String && !TextUtils.isEmpty((String) adUnitId)) {
                info.setAdUnitId((String) adUnitId);
            } else {
                Object ecpm = map.get("ecpm");
                if (ecpm instanceof Number) {
                    info.setEcpm(((Number) ecpm).doubleValue());
                }
            }
            mixList.add(info);
        }
        return mixList;
    }

    private List<Map<String, Object>> toMapList(List<MixAdInfo> mixAdInfoList) {
        ArrayList<Map<String, Object>> mapList = new ArrayList<>();
        if (mixAdInfoList == null) {
            return mapList;
        }
        for (MixAdInfo info : mixAdInfoList) {
            if (info == null) {
                continue;
            }
            HashMap<String, Object> map = new HashMap<>();
            String adUnitId = info.getAdUnitId();
            if (!TextUtils.isEmpty(adUnitId)) {
                map.put("adUnitId", adUnitId);
            } else {
                map.put("ecpm", info.getEcpm());
            }
            mapList.add(map);
        }
        return mapList;
    }
}
