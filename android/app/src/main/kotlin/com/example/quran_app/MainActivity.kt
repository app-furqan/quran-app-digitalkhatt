package com.example.quran_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import org.digitalkhatt.quran.renderer.QuranRenderer

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize the Quran renderer with font from assets
        QuranRenderer.getInstance().initialize(assets, "fonts/quran.otf")

        // Register the platform view factory
        flutterEngine.platformViewsController.registry
            .registerViewFactory(
                "quran-page-view",
                QuranPageViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }
}
