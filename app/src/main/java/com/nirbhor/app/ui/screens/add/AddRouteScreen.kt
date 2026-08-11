package com.nirbhor.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.nirbhor.app.navigation.NavActions
import com.nirbhor.app.ui.components.NbCard
import com.nirbhor.app.ui.components.NirbhorTopBar
import com.nirbhor.app.ui.components.TintPanel
import com.nirbhor.app.ui.components.nbCardShadow
import com.nirbhor.app.ui.i18n.tr
import com.nirbhor.app.ui.theme.Dimens
import com.nirbhor.app.ui.theme.NirbhorTheme

/** Route chooser (3a): scan is the default; prescription photo and search are the fallbacks. */
@Composable
fun AddRouteScreen(actions: NavActions) {
    val colors = NirbhorTheme.colors
    Column(Modifier.fillMaxSize().background(colors.paper)) {
        NirbhorTopBar(title = tr("ওষুধ যোগ করুন", "Add a medicine"), onBack = actions::back)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).navigationBarsPadding()
                .padding(horizontal = Dimens.screenPadding, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(Dimens.cardGap),
        ) {
            // Hero primary card.
            Column(
                Modifier.fillMaxWidth()
                    .nbCardShadow(RoundedCornerShape(18.dp), elevated = false)
                    .clip(RoundedCornerShape(18.dp)).background(colors.calm)
                    .clickable(onClick = actions::addScan).padding(20.dp),
            ) {
                Box(Modifier.clip(RoundedCornerShape(9.dp)).background(colors.calmD).padding(horizontal = 10.dp, vertical = 4.dp)) {
                    Text(tr("সবচেয়ে সহজ", "Easiest"), style = NirbhorTheme.type.statusPill, color = colors.paper)
                }
                Spacer(Modifier.height(14.dp))
                Box(Modifier.size(62.dp).clip(RoundedCornerShape(16.dp)).background(colors.calmD), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.CameraAlt, contentDescription = null, tint = colors.paper, modifier = Modifier.size(30.dp))
                }
                Spacer(Modifier.height(14.dp))
                Text(tr("পাতা বা বাক্স স্ক্যান করুন", "Scan the pack or box"), style = NirbhorTheme.type.header, color = colors.paper)
                Text(tr("ক্যামেরা ধরলেই নাম-শক্তি পড়ে নেবে", "Point the camera; it reads the name and strength"), style = NirbhorTheme.type.body, color = colors.paper.copy(alpha = 0.85f))
            }
            RouteCard(Icons.Filled.PhotoCamera, tr("প্রেসক্রিপশনের ছবি তুলুন", "Take a prescription photo"), tr("একসাথে অনেক ওষুধ যোগ হয়", "Adds several medicines at once"), actions::addPrescription)
            RouteCard(Icons.Filled.Search, tr("নাম দিয়ে খুঁজুন", "Search by name"), tr("টাইপ বা বলে খুঁজুন", "Type or speak the name"), actions::addSearch)
            TintPanel(background = colors.sage) {
                Text(tr("চাইলে পরিবারের কেউ আপনার হয়ে ওষুধ যোগ করে দিতে পারেন।", "A family member can add your medicines for you."), style = NirbhorTheme.type.body, color = colors.ink2)
            }
        }
    }
}

@Composable
private fun RouteCard(icon: ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    val colors = NirbhorTheme.colors
    NbCard(onClick = onClick) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(58.dp).clip(RoundedCornerShape(14.dp)).background(colors.sage), contentAlignment = Alignment.Center) {
                Icon(icon, contentDescription = null, tint = colors.ink2, modifier = Modifier.size(26.dp))
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = NirbhorTheme.type.cardTitlePrimary, color = colors.ink)
                Text(subtitle, style = NirbhorTheme.type.meta, color = colors.ink3)
            }
            Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, contentDescription = null, tint = colors.ink3)
        }
    }
}
