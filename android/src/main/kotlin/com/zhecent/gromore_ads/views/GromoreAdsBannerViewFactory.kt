package com.zhecent.gromore_ads.views

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Banner广告原生视图工厂
 * 负责创建Banner广告的PlatformView实例
 */
class GromoreAdsBannerViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any> ?: emptyMap()
        return GromoreAdsBannerView(context, viewId, creationParams)
    }
}