package com.nirbhor.app.ui.marks

import org.junit.Assert.assertEquals
import org.junit.Test

class MarkShapeTest {
    @Test fun everyStoredEnumNameRoundTrips() {
        MarkShape.entries.forEach { assertEquals(it, MarkShape.fromName(it.name)) }
    }

    @Test fun nullUnknownAndWrongCaseNamesUseSafeDefault() {
        assertEquals(MarkShape.FilledCircle, MarkShape.fromName(null))
        assertEquals(MarkShape.FilledCircle, MarkShape.fromName("unknown"))
        assertEquals(MarkShape.FilledCircle, MarkShape.fromName("ring"))
    }
}
