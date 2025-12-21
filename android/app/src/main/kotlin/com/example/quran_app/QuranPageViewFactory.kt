package com.example.quran_app

import android.content.Context
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
    
    private val quranView = QuranPageView(context)
    private val methodChannel = MethodChannel(messenger, "quran_page_view_$viewId")

    init {
        methodChannel.setMethodCallHandler(this)
        
        creationParams?.let {
            (it["pageIndex"] as? Int)?.let { page -> quranView.setPage(page) }
            (it["tajweed"] as? Boolean)?.let { tajweed -> quranView.setTajweed(tajweed) }
            (it["fontScale"] as? Double)?.let { scale -> quranView.setFontScale(scale.toFloat()) }
        }
    }

    override fun getView() = quranView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setPage" -> {
                val page = call.argument<Int>("page") ?: 0
                quranView.setPage(page)
                result.success(null)
            }
            "setTajweed" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                quranView.setTajweed(enabled)
                result.success(null)
            }
            "setFontScale" -> {
                val scale = call.argument<Double>("scale") ?: 1.0
                quranView.setFontScale(scale.toFloat())
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
