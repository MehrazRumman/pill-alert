package com.nirbhor.app.ui.screens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
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
}
