package com.nirbhor.app.ui.screens

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
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
import androidx.compose.runtime.DisposableEffect
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
import com.nirbhor.app.domain.LocalAddDraft
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.NirbhorTheme
import com.nirbhor.app.ui.marks.MarkShape
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File

/**
 * Scan & confirm (3b). Captures the pack with CameraX and extracts its printed name and strength
 * on-device. The patient can fall back to typing when the pack text cannot be read reliably.
 */
@Composable
fun AddScanScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val context = LocalContext.current
    val draft = LocalAddDraft.current
    var imageCapture by remember { mutableStateOf<ImageCapture?>(null) }
    var scanning by remember { mutableStateOf(false) }
    var scanError by remember { mutableStateOf<String?>(null) }
    var permissionDenied by remember { mutableStateOf(false) }
    fun handleRecognizedText(result: String) {
        val parsed = parsePackText(result)
        if (parsed == null) {
            scanning = false
            scanError = if (context.resources.configuration.locales[0].language == "bn") {
                "নাম পড়া যায়নি — আবার চেষ্টা করুন বা নাম লিখুন"
            } else {
                "Couldn't read a medicine name — try again or type it"
            }
            return
        }
        draft.displayName = parsed.name
        draft.packName = parsed.name
        draft.strength = parsed.strength
        draft.form = parsed.form
        stableMark(parsed.name).let { (mark, color) -> draft.mark = mark; draft.markColor = color }
        scanning = false
        actions.addTiming()
    }

    var hasPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        )
    }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) {
        hasPermission = it
        permissionDenied = !it
    }
    val settingsLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) {
        hasPermission = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        permissionDenied = !hasPermission
    }
    val imagePicker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        if (uri != null) {
            scanning = true
            scanError = null
            recognizeImage(context, uri, ::handleRecognizedText) {
                scanning = false
                scanError = if (context.resources.configuration.locales[0].language == "bn") "ছবি পড়া যায়নি" else "Couldn't read that photo"
            }
        }
    }
    LaunchedEffect(Unit) {
        if (!hasPermission) permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    Box(Modifier.fillMaxSize().background(colors.ink)) {
        if (hasPermission) {
            CameraPreview(
                modifier = Modifier.fillMaxSize(),
                onReady = { imageCapture = it },
                onError = { scanError = it },
            )
        }

        // Responsive reticle + instruction overlay.
        BoxWithConstraints(Modifier.fillMaxSize()) {
        val compact = maxHeight < 700.dp
        Column(Modifier.fillMaxSize().systemBarsPadding().navigationBarsPadding(), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(Modifier.fillMaxWidth().padding(16.dp)) {
                Box(
                    Modifier.size(48.dp).clip(CircleShape).background(Color(0x55000000)).clickable(onClick = actions::back),
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back", tint = colors.paper) }
            }
            Spacer(Modifier.height(if (compact) 8.dp else 24.dp))
            Text(
                if (hasPermission) tr("পাতা বা বাক্সটি ফ্রেমের ভেতরে ধরুন", "Hold the pack or box inside the frame")
                else tr("ক্যামেরা চালু করতে অনুমতি দিন", "Allow camera access to scan"),
                style = NirbhorTheme.type.body, color = colors.paper.copy(alpha = 0.9f),
                modifier = Modifier.padding(horizontal = 24.dp),
            )
            Spacer(Modifier.height(if (compact) 10.dp else 20.dp))
            Box(
                Modifier.fillMaxWidth().padding(horizontal = 40.dp).height(if (compact) 130.dp else 190.dp)
                    .border(2.dp, colors.paper.copy(alpha = 0.85f), RoundedCornerShape(16.dp)),
            )
            Spacer(Modifier.weight(1f))

            if (scanning || scanError != null) {
                Text(
                    if (scanning) tr("লেখা পড়া হচ্ছে…", "Reading the pack…")
                    else scanError.orEmpty(),
                    style = NirbhorTheme.type.meta,
                    color = if (scanError == null) colors.paper else colors.warm,
                    modifier = Modifier.padding(horizontal = 24.dp, vertical = 10.dp),
                )
            }

            if (!hasPermission) {
                PrimaryButton(
                    if (permissionDenied) tr("সেটিংস খুলুন", "Open camera settings") else tr("অনুমতি দিন", "Allow camera"),
                    {
                        if (permissionDenied) {
                            settingsLauncher.launch(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}")))
                        } else {
                            permissionLauncher.launch(Manifest.permission.CAMERA)
                        }
                    },
                    height = 60.dp, modifier = Modifier.padding(horizontal = 24.dp).fillMaxWidth(),
                )
                Spacer(Modifier.height(12.dp))
            }

            PrimaryButton(
                if (scanning) tr("পড়া হচ্ছে…", "Reading…") else tr("এখন স্ক্যান করুন", "Scan now"),
                {
                        val capture = imageCapture ?: return@PrimaryButton
                        scanning = true
                        scanError = null
                        recognizePack(
                            context = context,
                            capture = capture,
                            onSuccess = ::handleRecognizedText,
                            onFailure = {
                                scanning = false
                                scanError = if (context.resources.configuration.locales[0].language == "bn") {
                                    "ছবি পড়া যায়নি — আবার চেষ্টা করুন"
                                } else {
                                    "Couldn't read that photo — please try again"
                                }
                            },
                        )
                },
                enabled = hasPermission && imageCapture != null && !scanning,
                height = 64.dp,
                modifier = Modifier.padding(horizontal = 24.dp).fillMaxWidth(),
                leading = { Icon(Icons.Filled.CameraAlt, contentDescription = null, modifier = Modifier.size(24.dp)) },
            )
            Spacer(Modifier.height(8.dp))
            SecondaryButton(
                tr("গ্যালারি থেকে ছবি নিন", "Choose a photo instead"),
                { imagePicker.launch("image/*") },
                enabled = !scanning,
                height = 52.dp,
                modifier = Modifier.padding(horizontal = 24.dp).fillMaxWidth(),
            )
            Box(Modifier.clickable(onClick = actions::addSearch).padding(8.dp), contentAlignment = Alignment.Center) {
                androidx.compose.foundation.layout.Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.Keyboard, contentDescription = null, tint = colors.paper.copy(alpha = 0.85f), modifier = Modifier.size(18.dp))
                    Spacer(Modifier.size(6.dp))
                    Text(tr("বরং নাম লিখে দিন", "Type the name instead"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.paper.copy(alpha = 0.85f))
                }
            }
            Spacer(Modifier.height(if (compact) 4.dp else 12.dp))
        }
        }
    }
}

/** Live CameraX preview and still capture bound to the composition lifecycle. */
@Composable
private fun CameraPreview(
    modifier: Modifier = Modifier,
    onReady: (ImageCapture?) -> Unit,
    onError: (String) -> Unit,
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val previewView = remember { PreviewView(context).apply { scaleType = PreviewView.ScaleType.FILL_CENTER } }

    DisposableEffect(lifecycleOwner) {
        val future = ProcessCameraProvider.getInstance(context)
        val executor = ContextCompat.getMainExecutor(context)
        var provider: ProcessCameraProvider? = null
        var disposed = false
        future.addListener({
            if (disposed) return@addListener
            try {
                provider = future.get()
                val preview = Preview.Builder().build().also { it.setSurfaceProvider(previewView.surfaceProvider) }
                val capture = ImageCapture.Builder()
                    .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                    .build()
                provider?.unbindAll()
                provider?.bindToLifecycle(lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, preview, capture)
                onReady(capture)
            } catch (_: Exception) {
                onReady(null)
                onError("Camera is unavailable")
            }
        }, executor)
        onDispose {
            disposed = true
            onReady(null)
            provider?.unbindAll()
        }
    }

    AndroidView(factory = { previewView }, modifier = modifier)
}

internal data class ParsedPack(val name: String, val strength: String, val form: String)

private val strengthPattern = Regex(
    "\\b\\d+(?:[.,]\\d+)?\\s*(?:mg|mcg|µg|g|ml|iu|units?)\\b",
    RegexOption.IGNORE_CASE,
)
private val formPattern = Regex(
    "(?i)\\b(tablets?|capsules?|syrup|suspension|injection|injectable)\\b",
)
private val metadataPattern = Regex(
    "(?i)\\b(batch|lot|mfg|manufactured|exp|expiry|expires|price|mrp|marketed|distributed|license|reg(?:istration)?|pharma(?:ceuticals?)?)\\b",
)

private fun medicineNameFrom(line: String): String = line
    .replace(strengthPattern, "")
    .replace(formPattern, "")
    .replace(Regex("(?i)\\b(usp|bp|ip)\\b"), "")
    .trim(' ', '-', '·', ':', ',', '.')
    .replace(Regex("\\s{2,}"), " ")
    .take(80)

internal fun parsePackText(text: String): ParsedPack? {
    val lines = text.lineSequence().map { it.trim() }.filter { it.length >= 2 }.toList()
    val strength = lines.firstNotNullOfOrNull { strengthPattern.find(it)?.value }.orEmpty()
    val candidate = lines.withIndex().mapNotNull { (index, line) ->
        if (metadataPattern.containsMatchIn(line)) return@mapNotNull null
        val name = medicineNameFrom(line)
        if (name.length < 2 || name.none(Char::isLetter)) return@mapNotNull null
        var score = if (index < 3) 3 else 0
        if (strengthPattern.containsMatchIn(line)) score += 2
        if (formPattern.containsMatchIn(line)) score += 1
        if (name.length in 3..40) score += 2
        name to score
    }.maxByOrNull { it.second }?.first ?: return null
    val all = lines.joinToString(" ").lowercase()
    val form = when {
        "capsule" in all || "cap." in all -> "capsule"
        "syrup" in all || "suspension" in all -> "syrup"
        "injection" in all || "injectable" in all -> "injection"
        else -> "tablet"
    }
    return ParsedPack(candidate, strength, form)
}

internal fun stableMark(name: String): Pair<MarkShape, Long> {
    val options = listOf(
        MarkShape.FilledCircle to 0xFF2F6B5BL,
        MarkShape.Ring to 0xFF2F6B5BL,
        MarkShape.RoundedSquare to 0xFF7D94A8L,
        MarkShape.Triangle to 0xFFB9975BL,
        MarkShape.Capsule to 0xFFA8788FL,
        MarkShape.HalfFilled to 0xFF2F6B5BL,
    )
    return options[(name.hashCode() and Int.MAX_VALUE) % options.size]
}

private fun recognizePack(
    context: android.content.Context,
    capture: ImageCapture,
    onSuccess: (String) -> Unit,
    onFailure: () -> Unit,
) {
    val file = File.createTempFile("nirbhor-pack-", ".jpg", context.cacheDir)
    val output = ImageCapture.OutputFileOptions.Builder(file).build()
    capture.takePicture(output, ContextCompat.getMainExecutor(context), object : ImageCapture.OnImageSavedCallback {
        override fun onImageSaved(result: ImageCapture.OutputFileResults) {
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            val image = runCatching { InputImage.fromFilePath(context, Uri.fromFile(file)) }.getOrElse {
                file.delete()
                recognizer.close()
                onFailure()
                return
            }
            recognizer.process(image)
                .addOnSuccessListener { onSuccess(it.text) }
                .addOnFailureListener { onFailure() }
                .addOnCompleteListener {
                    recognizer.close()
                    file.delete()
                }
        }

        override fun onError(exception: ImageCaptureException) {
            file.delete()
            onFailure()
        }
    })
}

internal fun recognizeImage(
    context: android.content.Context,
    uri: Uri,
    onSuccess: (String) -> Unit,
    onFailure: () -> Unit,
) {
    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    val image = runCatching { InputImage.fromFilePath(context, uri) }.getOrElse {
        recognizer.close()
        onFailure()
        return
    }
    recognizer.process(image)
        .addOnSuccessListener { onSuccess(it.text) }
        .addOnFailureListener { onFailure() }
        .addOnCompleteListener { recognizer.close() }
}
