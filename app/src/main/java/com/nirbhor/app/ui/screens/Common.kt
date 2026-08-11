package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.theme.NirbhorTheme

/**
 * Temporary placeholder shown until a screen is implemented. Every real screen replaces the body of
 * its own file; this keeps the NavHost wired and the app runnable while screens are built in parallel.
 */
@Composable
fun ScreenPlaceholder(
    title: String,
    onBack: (() -> Unit)? = null,
    note: String = "এই স্ক্রিনটি তৈরি হচ্ছে · Screen under construction",
) {
    val colors = NirbhorTheme.colors
    Column(Modifier.fillMaxSize().background(colors.paper)) {
        if (onBack != null) NirbhorTopBar(title = title, onBack = onBack)
        Box(Modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(title, style = NirbhorTheme.type.titleHero, color = colors.ink, textAlign = TextAlign.Center)
                Text(note, style = NirbhorTheme.type.body, color = colors.ink3, textAlign = TextAlign.Center)
            }
        }
    }
}
