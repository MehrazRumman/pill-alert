package com.nirbhor.app.ui.screens

import android.content.Intent
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.nirbhor.app.BuildConfig
import com.nirbhor.app.data.NirbhorRepository
import com.nirbhor.app.navigation.LocalAppContainer
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.NbSwitch
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.PrimaryButton
import com.nirbhor.app.ui.components.SecondaryButton
import com.nirbhor.app.ui.components.SegmentedControl
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.i18n.num
import com.nirbhor.app.ui.i18n.percent
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.marks.MedicineMark
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme
import java.io.File
import java.time.LocalDate

/** Doctor report preview + share (6c). The report is the patient's own record, not a measurement. */
@Composable
fun DoctorReportScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    val repo = LocalAppContainer.current.repository
    val context = LocalContext.current
    var rangeIdx by remember { mutableStateOf(0) }
    val days = listOf(30, 90, 365)[rangeIdx]
    var latinNames by remember { mutableStateOf(true) }
    val reportFailed = tr("রিপোর্ট বানানো যায়নি", "Couldn't create the report")
    var pendingSave by remember { mutableStateOf<File?>(null) }
    var exportMessage by remember { mutableStateOf<String?>(null) }
    val saveLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("application/pdf"),
    ) { uri ->
        val source = pendingSave
        if (uri != null && source != null) {
            exportMessage = runCatching {
                context.contentResolver.openOutputStream(uri)?.use { output -> source.inputStream().use { it.copyTo(output) } }
                    ?: error("Unable to open destination")
                if (context.resources.configuration.locales[0].language == "bn") "রিপোর্ট সেভ হয়েছে" else "Report saved"
            }.getOrElse {
                if (context.resources.configuration.locales[0].language == "bn") "রিপোর্ট সেভ করা যায়নি" else "Couldn't save the report"
            }
        }
        pendingSave = null
    }

    var window by remember { mutableStateOf<NirbhorRepository.AdherenceWindow?>(null) }
    var perMed by remember { mutableStateOf<List<NirbhorRepository.MedAdherence>>(emptyList()) }
    LaunchedEffect(days) {
        window = repo.adherenceOver(days)
        perMed = repo.perMedicineAdherence(days)
    }

    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("ডাক্তারের রিপোর্ট", "Doctor report"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding().padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.groupGap),
        ) {
            SegmentedControl(
                options = listOf(tr("১ মাস", "1 month"), tr("৩ মাস", "3 months"), tr("১ বছর", "1 year")),
                selectedIndex = rangeIdx, onSelect = { rangeIdx = it },
            )

            // Scaled PDF page preview.
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color.White).border(1.dp, colors.line, RoundedCornerShape(12.dp)).padding(18.dp)) {
                Text(tr("নির্ভর · ওষুধের হিসাব", "Nirbhor · Medication record"), fontSize = 16.sp, fontWeight = FontWeight(700), color = Color(0xFF1B2A26))
                Text(tr("রোগীর নিজের হিসাব · গত ${num(days)} দিন", "Patient's own record · last $days days"), fontSize = 12.sp, color = Color(0xFF4A5C56))
                Spacer(Modifier.height(14.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    StatTile(colors.calmSoft, colors.calmD, num(window?.taken ?: 0), tr("নেওয়া", "Taken"), Modifier.weight(1f))
                    StatTile(colors.warmSoft, colors.warmD, num(window?.missed ?: 0), tr("বাদ", "Missed"), Modifier.weight(1f))
                    StatTile(colors.sage, colors.ink, percent(window?.percent ?: 0), tr("সময়মতো", "On time"), Modifier.weight(1f))
                }
                Spacer(Modifier.height(14.dp))
                perMed.filter { it.total > 0 }.forEach { m ->
                    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                        MedicineMark(m.medicine.mark, Color(m.medicine.markColor), size = 18.dp)
                        Spacer(Modifier.width(8.dp))
                        Text(if (latinNames) m.medicine.packName else m.medicine.displayName, fontSize = 12.sp, color = Color(0xFF1B2A26), modifier = Modifier.width(110.dp))
                        Box(Modifier.weight(1f).height(9.dp).clip(RoundedCornerShape(5.dp)).background(colors.sage)) {
                            Box(Modifier.fillMaxWidth(m.percent / 100f).height(9.dp).clip(RoundedCornerShape(5.dp)).background(if (m.percent >= 80) colors.calm else colors.warm))
                        }
                        Spacer(Modifier.width(8.dp))
                        Text(percent(m.percent), fontSize = 12.sp, color = Color(0xFF4A5C56))
                    }
                }
                Spacer(Modifier.height(10.dp))
                Text(
                    tr("এটি রোগীর নিজের রাখা হিসাব — কোনো ক্লিনিক্যাল পরিমাপ নয়।", "This is the patient's own record, not a clinical measurement."),
                    fontSize = 11.sp, color = Color(0xFF8B9A94),
                )
            }

            NbCard {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(Modifier.weight(1f)) {
                        Text(tr("ওষুধের নাম ইংরেজিতে", "Medicine names in English"), style = NirbhorTheme.type.cardTitleSecondary, color = colors.ink)
                        Text(tr("ডাক্তার সাধারণত ল্যাটিন নাম পড়েন", "Doctors usually read the Latin names"), style = NirbhorTheme.type.meta, color = colors.ink3)
                    }
                    NbSwitch(checked = latinNames, onCheckedChange = { latinNames = it })
                }
            }

            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                PrimaryButton(
                    tr("পাঠান", "Send"),
                    {
                        runCatching { createReportPdf(context, days, window, perMed, latinNames) }
                            .onSuccess { file ->
                                val uri = FileProvider.getUriForFile(context, "${BuildConfig.APPLICATION_ID}.fileprovider", file)
                                val share = Intent(Intent.ACTION_SEND).apply {
                                    type = "application/pdf"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                context.startActivity(Intent.createChooser(share, context.getString(com.nirbhor.app.R.string.app_name)))
                            }
                            .onFailure { exportMessage = reportFailed }
                    },
                    height = 60.dp, modifier = Modifier.weight(1f),
                )
                SecondaryButton(
                    tr("সেভ করুন", "Save"),
                    {
                        runCatching { createReportPdf(context, days, window, perMed, latinNames) }
                            .onSuccess { file ->
                                pendingSave = file
                                saveLauncher.launch("nirbhor-medication-report-$days-days.pdf")
                            }
                            .onFailure { exportMessage = reportFailed }
                    },
                    height = 60.dp, modifier = Modifier.width(112.dp),
                )
            }
            exportMessage?.let { Text(it, style = NirbhorTheme.type.meta, color = colors.calmD) }
        }
    }
}

private fun createReportPdf(
    context: android.content.Context,
    days: Int,
    window: NirbhorRepository.AdherenceWindow?,
    medicines: List<NirbhorRepository.MedAdherence>,
    latinNames: Boolean,
): File {
    val directory = File(context.cacheDir, "reports").apply { mkdirs() }
    val output = File(directory, "nirbhor-medication-report.pdf")
    val document = PdfDocument()
    val titlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = android.graphics.Color.rgb(27, 42, 38)
        textSize = 22f
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }
    val bodyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = android.graphics.Color.rgb(74, 92, 86)
        textSize = 12f
    }
    val strongPaint = Paint(bodyPaint).apply { typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD) }
    val linePaint = Paint().apply { color = android.graphics.Color.rgb(219, 228, 223); strokeWidth = 1f }
    var pageNumber = 0
    var page: PdfDocument.Page? = null
    var y = 0f

    fun startPage() {
        page?.let(document::finishPage)
        pageNumber++
        page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, pageNumber).create())
        val canvas = requireNotNull(page).canvas
        canvas.drawColor(android.graphics.Color.WHITE)
        canvas.drawText("Nirbhor - Medication record", 48f, 58f, titlePaint)
        canvas.drawText("Patient-maintained record - last $days days - ${LocalDate.now()}", 48f, 82f, bodyPaint)
        canvas.drawLine(48f, 98f, 547f, 98f, linePaint)
        y = 126f
    }

    startPage()
    val canvas = { requireNotNull(page).canvas }
    canvas().drawText("Taken: ${window?.taken ?: 0}", 48f, y, strongPaint)
    canvas().drawText("Missed: ${window?.missed ?: 0}", 198f, y, strongPaint)
    canvas().drawText("Adherence: ${window?.percent ?: 0}%", 348f, y, strongPaint)
    y += 34f
    canvas().drawText("Medicine", 48f, y, strongPaint)
    canvas().drawText("Taken / counted", 330f, y, strongPaint)
    canvas().drawText("Rate", 490f, y, strongPaint)
    y += 12f
    canvas().drawLine(48f, y, 547f, y, linePaint)
    y += 24f

    medicines.filter { it.total > 0 }.forEach { item ->
        if (y > 790f) startPage()
        val rawName = if (latinNames) item.medicine.packName.ifBlank { item.medicine.displayName } else item.medicine.displayName
        val name = if (rawName.length > 42) rawName.take(39) + "..." else rawName
        canvas().drawText(name, 48f, y, bodyPaint)
        canvas().drawText("${item.taken} / ${item.total}", 330f, y, bodyPaint)
        canvas().drawText("${item.percent}%", 490f, y, strongPaint)
        y += 26f
        canvas().drawLine(48f, y - 10f, 547f, y - 10f, linePaint)
    }
    if (medicines.none { it.total > 0 }) canvas().drawText("No completed doses in this period.", 48f, y, bodyPaint)
    page?.let(document::finishPage)
    output.outputStream().use(document::writeTo)
    document.close()
    return output
}

@Composable
private fun StatTile(bg: Color, fg: Color, value: String, label: String, modifier: Modifier) {
    Column(modifier.clip(RoundedCornerShape(10.dp)).background(bg).padding(12.dp)) {
        Text(value, fontSize = 30.sp, fontWeight = FontWeight(700), color = fg)
        Text(label, fontSize = 11.sp, color = fg)
    }
}
