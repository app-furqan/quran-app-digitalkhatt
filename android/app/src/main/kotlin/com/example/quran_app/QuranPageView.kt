package com.example.quran_app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.view.View
import android.widget.ScrollView
import org.digitalkhatt.quran.renderer.QuranRenderer

class QuranPageView(context: Context) : View(context) {
    private var pageIndex: Int = 0
    private var tajweed: Boolean = true
    private var fontScale: Float = 1.0f
    private var bitmap: Bitmap? = null
    private val renderer = QuranRenderer.getInstance()
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
    private val matrix = Matrix()
    private var baseWidth: Int = 0
    private var baseHeight: Int = 0

    fun setPage(page: Int) {
        if (pageIndex != page) {
            pageIndex = page
            bitmap = null
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

    fun setFontScale(scale: Float) {
        if (fontScale != scale) {
            fontScale = scale
            bitmap = null
            invalidate()
        }
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        // Store the base dimensions on first layout
        if (baseWidth == 0 || baseHeight == 0) {
            baseWidth = w
            baseHeight = h
        }
        bitmap = null
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (width <= 0 || height <= 0) return

        // Use stored base dimensions for rendering
        val renderWidth = if (baseWidth > 0) baseWidth else width
        val renderHeight = if (baseHeight > 0) baseHeight else height

        if (bitmap == null || bitmap!!.width != renderWidth || bitmap!!.height != renderHeight) {
            bitmap?.recycle()
            bitmap = Bitmap.createBitmap(renderWidth, renderHeight, Bitmap.Config.ARGB_8888)
            renderer.drawPage(bitmap!!, pageIndex, tajweed, true)
        }
        
        // Apply uniform scaling from the center-top
        matrix.reset()
        val scaledWidth = renderWidth * fontScale
        val offsetX = (width - scaledWidth) / 2f
        matrix.postScale(fontScale, fontScale)
        matrix.postTranslate(offsetX, 0f)
        
        bitmap?.let { canvas.drawBitmap(it, matrix, paint) }
    }
}
