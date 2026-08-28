# ML Kit ships one text-recogniser artifact per script (Latin, Chinese, Devanagari, Japanese,
# Korean) and the Flutter plugin references all five. Only the Latin one is a dependency here, so
# R8 sees the other four as missing classes and fails the release build. The app never calls them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit resolves its model pipelines reflectively; shrinking their names breaks recognition at
# runtime rather than at build time, which is the worst way to find out.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
