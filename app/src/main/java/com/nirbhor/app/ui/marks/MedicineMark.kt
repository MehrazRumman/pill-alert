package com.nirbhor.app.ui.marks

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * The six medicine marks (README > Medicine Marks). Every medicine is assigned ONE mark at
 * creation; the same mark represents it on every screen (timeline, cabinet, alarm, record, email).
 * It is the primary non-textual identifier for low-literacy users, so it is stored on the medicine
 * record — never derived.
 *
 * Geometry is authored in a 30×30 box and scaled to the requested [size]. Colour is passed in so
 * callers can use the stored markColor, or the lightened variants on the dark alarm background.
 */
enum class MarkShape {
    FilledCircle,   // circle r=13            — default calm
    Ring,           // circle r=11.5, sw 3.5  — default calm
    HalfFilled,     // ring + right half fill — default calm
    RoundedSquare,  // rect 24×24, r=7        — default slate
    Triangle,       // M15 3.5 L27 26 H3 Z    — default ochre
    Capsule;        // rect 22×10, r=5        — default mauve

    companion object {
        fun fromName(name: String?): MarkShape =
            entries.firstOrNull { it.name == name } ?: FilledCircle
    }
}

@Composable
fun MedicineMark(
    shape: MarkShape,
    color: Color,
    modifier: Modifier = Modifier,
    size: Dp = 30.dp,
) {
    Canvas(modifier = modifier.size(size)) {
        val k = this.size.minDimension / 30f // design box is 30×30
        fun p(v: Float) = v * k
        when (shape) {
            MarkShape.FilledCircle ->
                drawCircle(color = color, radius = p(13f), center = Offset(p(15f), p(15f)))

            MarkShape.Ring ->
                drawCircle(
                    color = color, radius = p(11.5f), center = Offset(p(15f), p(15f)),
                    style = Stroke(width = p(3.5f)),
                )

            MarkShape.HalfFilled -> {
                // Right half solid, then the full ring on top.
                clipRect(left = p(15f), top = 0f, right = this.size.width, bottom = this.size.height) {
                    drawCircle(color = color, radius = p(11.5f), center = Offset(p(15f), p(15f)))
                }
                drawCircle(
                    color = color, radius = p(11.5f), center = Offset(p(15f), p(15f)),
                    style = Stroke(width = p(3.5f)),
                )
            }

            MarkShape.RoundedSquare ->
                drawRoundRect(
                    color = color,
                    topLeft = Offset(p(3f), p(3f)),
                    size = Size(p(24f), p(24f)),
                    cornerRadius = CornerRadius(p(7f), p(7f)),
                )

            MarkShape.Triangle ->
                drawPath(
                    color = color,
                    path = Path().apply {
                        moveTo(p(15f), p(3.5f))
                        lineTo(p(27f), p(26f))
                        lineTo(p(3f), p(26f))
                        close()
                    },
                )

            MarkShape.Capsule ->
                drawRoundRect(
                    color = color,
                    topLeft = Offset(p(4f), p(10f)),
                    size = Size(p(22f), p(10f)),
                    cornerRadius = CornerRadius(p(5f), p(5f)),
                )
        }
    }
}
