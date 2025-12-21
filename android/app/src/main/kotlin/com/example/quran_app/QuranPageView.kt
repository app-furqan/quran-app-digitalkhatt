package com.example.quran_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.widget.FrameLayout
import android.widget.ScrollView
import org.digitalkhatt.quran.renderer.QuranRenderer

class QuranPageView(context: Context) : View(context) {
    private var pageIndex: Int = 0
    private var tajweed: Boolean = true
    private var fontSize: Float = 1.0f
    private var bitmap: Bitmap? = null
    private val renderer = QuranRenderer.getInstance()
    private var baseWidth: Int = 0
    private var baseHeight: Int = 0

    fun setPage(page: Int) {
        if (pageIndex != page) {
            pageIndex = page
            bitmap = null
            requestLayout()
            invalidate()
        }
    }

    fun setTajweed(enabled: Boolean) {
        if (tajweed != enabled) {
            tajweed = enabled
            bitmap = null
            invalidate()
        }
    }

    fun setFontSize(size: Float) {
        if (fontSize != size) {
            fontSize = size
            bitmap = null
            requestLayout()
            invalidate()
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val parentWidth = MeasureSpec.getSize(widthMeasureSpec)
        val parentHeight = MeasureSpec.getSize(heightMeasureSpec)
        
        // Store base dimensions on first measure
        if (baseWidth == 0) baseWidth = parentWidth
        if (baseHeight == 0) baseHeight = parentHeight
        
        // Calculate the scaled dimensions
        val scaledWidth = (baseWidth * fontSize).toInt()
        val scaledHeight = (baseHeight * fontSize).toInt()
        
        setMeasuredDimension(scaledWidth, scaledHeight)
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (width <= 0 || height <= 0) return

        // Render at the current measured size (which is scaled)
        if (bitmap == null || bitmap!!.width != width || bitmap!!.height != height) {
            bitmap?.recycle()
            bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            renderer.drawPage(bitmap!!, pageIndex, tajweed, true)
        }
        
        bitmap?.let { canvas.drawBitmap(it, 0f, 0f, null) }
    }
    
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        bitmap?.recycle()
        bitmap = null
    }
}

// Container that wraps QuranPageView in a ScrollView for scrolling when font is larger
class ScrollableQuranView(context: Context) : FrameLayout(context) {
    private val scrollView: ScrollView
    val quranView: QuranPageView
    
    init {
        scrollView = ScrollView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
            isFillViewport = true
            isVerticalScrollBarEnabled = true
        }
        
        quranView = QuranPageView(context).apply {
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }
        
        scrollView.addView(quranView)
        addView(scrollView)
    }
    
    fun setPage(page: Int) = quranView.setPage(page)
    fun setTajweed(enabled: Boolean) = quranView.setTajweed(enabled)
    fun setFontSize(size: Float) {
        quranView.setFontSize(size)
        // Scroll to top when font size changes
        scrollView.scrollTo(0, 0)
    }
}
