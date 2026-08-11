package com.nirbhor.app.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Keyboard
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * Scan & confirm (3b). Opens the REAL device camera (CameraX live preview) inside the reticle.
 * On-device OCR is not wired yet, so the capture control hands off to search-by-name where the
 * patient types what's on the pack — no placeholder medicine data is injected.
 */
@Composable
fun AddScanScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val context = LocalContext.current

    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        )
    }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        hasPermission = it
    }
    LaunchedEffect(Unit) {
        if (!hasPermission) permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    Box(Modifier.fillMaxSize().background(colors.ink)) {
        if (hasPermission) {
            CameraPreview(Modifier.fillMaxSize())
        }

        // Reticle + instruction overlay.
        Column(Modifier.fillMaxSize().systemBarsPadding(), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.fillMaxWidth().padding(16.dp)) {
                Box(
                    Modifier.size(48.dp).clip(CircleShape).background(Color(0x55000000)).clickable(onClick = actions::back),
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = colors.paper) }
            }
            Spacer(Modifier.height(40.dp))
            Text(
                if (hasPermission) tr("পাতা বা বাক্সটি ফ্রেমের ভেতরে ধরুন", "Hold the pack or box inside the frame")
                else tr("ক্যামেরা চালু করতে অনুমতি দিন", "Allow camera access to scan"),
                style = NirbhorTheme.type.body, color = colors.paper.copy(alpha = 0.9f),
                modifier = Modifier.padding(horizontal = 24.dp),
            )
            Spacer(Modifier.height(24.dp))
            Box(
                Modifier.fillMaxWidth().padding(horizontal = 40.dp).height(200.dp)
                    .border(2.dp, colors.paper.copy(alpha = 0.85f), RoundedCornerShape(16.dp)),
            )
            Spacer(Modifier.weight(1f))

            if (!hasPermission) {
                PrimaryButton(
                    tr("অনুমতি দিন", "Allow camera"),
                    { permissionLauncher.launch(Manifest.permission.CAMERA) },
                    height = 60.dp, modifier = Modifier.padding(horizontal = 24.dp).fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))
            }

            // Capture control. (OCR not wired — hands off to typing the name.)
            Box(
                Modifier.size(76.dp).clip(CircleShape).background(colors.paper)
                    .clickable(enabled = hasPermission, onClick = actions::addSearch),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.CameraAlt, contentDescription = tr("ছবি তুলুন", "Capture"), tint = colors.calm, modifier = Modifier.size(34.dp))
            }
            Spacer(Modifier.height(14.dp))
            Box(Modifier.clickable(onClick = actions::addSearch).padding(8.dp), contentAlignment = Alignment.Center) {
                androidx.compose.foundation.layout.Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Keyboard, contentDescription = null, tint = colors.paper.copy(alpha = 0.85f), modifier = Modifier.size(18.dp))
                    Spacer(Modifier.size(6.dp))
                    Text(tr("বরং নাম লিখে দিন", "Type the name instead"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.paper.copy(alpha = 0.85f))
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}

/** Live CameraX preview bound to the composition lifecycle. */
@Composable
private fun CameraPreview(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val previewView = remember { PreviewView(context).apply { scaleType = PreviewView.ScaleType.FILL_CENTER } }

    LaunchedEffect(Unit) {
        val cameraProvider = ProcessCameraProvider.getInstance(context).get()
        val preview = Preview.Builder().build().also { it.setSurfaceProvider(previewView.surfaceProvider) }
        try {
            cameraProvider.unbindAll()
            cameraProvider.bindToLifecycle(lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, preview)
        } catch (_: Exception) {
            // No camera available (e.g. some emulators) — the preview stays black; UI still works.
        }
    }

    AndroidView(factory = { previewView }, modifier = modifier)
}
