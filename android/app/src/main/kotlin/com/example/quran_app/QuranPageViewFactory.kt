package com.example.quran_app

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class QuranPageViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any?>
        return QuranPlatformView(context, viewId, creationParams, messenger)
    }
}

class QuranPlatformView(
    context: Context,
    private val viewId: Int,
    creationParams: Map<String, Any?>?,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {
    
    private val scrollableView = ScrollableQuranView(context)
    private val methodChannel = MethodChannel(messenger, "quran_page_view_$viewId")

    init {
        methodChannel.setMethodCallHandler(this)
        
        creationParams?.let {
            (it["pageIndex"] as? Int)?.let { page -> scrollableView.setPage(page) }
            (it["tajweed"] as? Boolean)?.let { tajweed -> scrollableView.setTajweed(tajweed) }
            (it["fontSize"] as? Double)?.let { size -> scrollableView.setFontSize(size.toFloat()) }
        }
    }

    override fun getView(): View = scrollableView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setPage" -> {
                val page = call.argument<Int>("page") ?: 0
                scrollableView.setPage(page)
                result.success(null)
            }
            "setTajweed" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                scrollableView.setTajweed(enabled)
                result.success(null)
            }
            "setFontSize" -> {
                val size = call.argument<Double>("size") ?: 1.0
                scrollableView.setFontSize(size.toFloat())
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
