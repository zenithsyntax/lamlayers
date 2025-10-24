package com.zenithsyntax.lamlayers

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.lamlayers/deep_links"
    private var methodChannel: MethodChannel? = null
    private var pendingOpenedPath: String? = null
    private var isDartReady: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, _ ->
            if (call.method == "ready") {
                isDartReady = true
                pendingOpenedPath?.let { path ->
                    notifyOpenedFile(mapOf("path" to path))
                    pendingOpenedPath = null
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_VIEW == intent.action) {
            val uri: Uri? = intent.data
            if (uri == null) return
            
            android.util.Log.d("MainActivity", "Received intent with URI: $uri")
            android.util.Log.d("MainActivity", "URI scheme: ${uri.scheme}")
            android.util.Log.d("MainActivity", "URI path: ${uri.path}")
            
            val resolvedPath = resolveToLocalPath(uri)
            if (resolvedPath != null) {
                android.util.Log.d("MainActivity", "Resolved path: $resolvedPath")
                // Queue until Dart signals readiness to avoid losing the event on cold start
                if (isDartReady && notifyOpenedFile(mapOf("path" to resolvedPath))) {
                    pendingOpenedPath = null
                } else {
                    pendingOpenedPath = resolvedPath
                }
            } else {
                // Fallback to passing the URI string if we couldn't resolve
                val uriString = uri.toString()
                android.util.Log.d("MainActivity", "Using URI string fallback: $uriString")
                if (isDartReady && notifyOpenedFile(mapOf("uri" to uriString))) {
                    pendingOpenedPath = null
                } else {
                    pendingOpenedPath = uriString
                }
            }
        }
        // Also capture shared streams if needed in future
    }

    private fun notifyOpenedFile(payload: Map<String, Any>): Boolean {
        return try {
            methodChannel?.invokeMethod("openedFile", payload)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun resolveToLocalPath(uri: Uri): String? {
        return try {
            when (uri.scheme?.lowercase()) {
                "file" -> uri.path
                "content" -> copyContentUriToCache(uri)
                else -> null
            }
        } catch (_: Throwable) { null }
    }

    private fun copyContentUriToCache(uri: Uri): String? {
        val resolver = applicationContext.contentResolver
        val fileName = (uri.lastPathSegment ?: "shared").substringAfterLast('/')
        val safeName = if (fileName.contains('.')) fileName else ensureExtension(fileName, uri)
        val outFile = File(cacheDir, safeName)
        
        try {
            resolver.openInputStream(uri)?.use { input ->
                FileOutputStream(outFile).use { output ->
                    input.copyTo(output)
                }
            } ?: return null
            
            // Log success
            android.util.Log.d("MainActivity", "Successfully copied file: ${outFile.absolutePath}, size: ${outFile.length()} bytes")
            return outFile.absolutePath
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to copy content URI: $e")
            return null
        }
    }

    private fun ensureExtension(base: String, uri: Uri): String {
        val lower = uri.toString().lowercase()
        return when {
            lower.endsWith(".lambook") -> base + ".lambook"
            lower.endsWith(".lamlayers") -> base + ".lamlayers"
            else -> {
                // Check if the base name already has an extension
                if (base.contains(".")) base else base + ".lambook"
            }
        }
    }
}
