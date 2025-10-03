package com.zhecent.gromore_ads.views

import android.content.Context
import com.zhecent.gromore_ads.managers.FeedAdManager
import com.zhecent.gromore_ads.utils.AdEventHelper
import com.zhecent.gromore_ads.utils.AdLogger
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * 信息流广告原生视图工厂
 */
class GromoreAdsFeedViewFactory(
    private val messenger: BinaryMessenger,
    private val feedAdManager: FeedAdManager,
    private val eventHelper: AdEventHelper,
    private val logger: AdLogger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any> ?: emptyMap()
        return GromoreAdsFeedView(
            context,
            messenger,
            viewId,
            creationParams,
            feedAdManager,
            eventHelper,
            logger
        )
    }
}
