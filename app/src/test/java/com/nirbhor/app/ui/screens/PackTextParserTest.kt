package com.nirbhor.app.ui.screens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PackTextParserTest {
    @Test fun extractsMedicineNameStrengthAndForm() {
        val parsed = parsePackText("Napa 500 mg Tablet\nBeximco Pharma\nMFG 2026")
        assertEquals("Napa", parsed?.name)
        assertEquals("500 mg", parsed?.strength)
        assertEquals("tablet", parsed?.form)
    }

    @Test fun rejectsTextWithoutAUsableName() {
        assertNull(parsePackText("500 mg\n12345"))
    }

    @Test fun recognizesAllSupportedStrengthUnitsCaseInsensitively() {
        val cases = mapOf(
            "Drug 10 MCG capsule" to "10 MCG",
            "Drug 2.5 ml syrup" to "2.5 ml",
            "Drug 100 IU injection" to "100 IU",
            "Drug 1 g tablet" to "1 g",
            "Drug 20 units injectable" to "20 units",
        )
        cases.forEach { (text, strength) -> assertEquals(strength, parsePackText(text)?.strength) }
    }

    @Test fun recognizesCapsuleSyrupAndInjectionForms() {
        assertEquals("capsule", parsePackText("Ace 10 mg CAPSULE")?.form)
        assertEquals("syrup", parsePackText("Ace 10 mg suspension")?.form)
        assertEquals("injection", parsePackText("Ace 10 mg injectable")?.form)
    }

    @Test fun metadataLinesAreNotSelectedAsMedicineName() {
        val parsed = parsePackText("MFG 2026\nEXP 2028\nNapa 500 mg tablet\nMRP 20")
        assertEquals("Napa", parsed?.name)
    }

    @Test fun commaDecimalStrengthIsAccepted() {
        assertEquals("2,5 mg", parsePackText("Medicine 2,5 mg tablet")?.strength)
    }

    @Test fun extractedNameIsTrimmedAndLengthLimited() {
        val longName = "A".repeat(100)
        val parsed = parsePackText("$longName 5 mg tablet")
        assertEquals(80, parsed?.name?.length)
    }

    @Test fun stableMarkIsDeterministicAndUsesKnownPalette() {
        val first = stableMark("Napa")
        assertEquals(first, stableMark("Napa"))
        assertTrue(first.first in com.nirbhor.app.ui.marks.MarkShape.entries)
        assertNotEquals(0L, first.second)
    }

    @Test fun stableMarkHandlesHashCodeMinimumValueSafely() {
        // This string has Java/Kotlin hashCode Int.MIN_VALUE and previously could create a negative index.
        val minHash = "polygenelubricants"
        assertEquals(Int.MIN_VALUE, minHash.hashCode())
        assertTrue(stableMark(minHash).first in com.nirbhor.app.ui.marks.MarkShape.entries)
    }
}
