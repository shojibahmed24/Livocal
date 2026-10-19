# Flutter ProGuard / R8 Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# WebRTC & CallKit
-keep class com.cloudwebrtc.webrtc.** { *; }
-keep class org.webrtc.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.** { *; }

# Isar
-keep class io.isar.** { *; }

# Suppress R8 missing class warnings
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.OpenSSLProvider
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
-dontwarn com.fasterxml.jackson.**
-dontwarn org.bouncycastle.**
-dontwarn javax.annotation.**
-dontwarn okhttp3.**

# Keep models & annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter Sound & Audio Session
-keep class com.dooboolab.fluttersound.** { *; }
-dontwarn com.dooboolab.fluttersound.**
-keep class com.ryanheise.audio_session.** { *; }
-dontwarn com.ryanheise.audio_session.**
-dontwarn com.hiennv.flutter_callkit_incoming.**

# Photo Manager & Glide (Media Picker)
-keep class com.fluttercandies.photo_manager.** { *; }
-dontwarn com.fluttercandies.photo_manager.**
-keep public class * implements com.bumptech.glide.module.AppGlideModule
-keep public class * extends com.bumptech.glide.module.AppGlideModule
-keep public class * implements com.bumptech.glide.module.LibraryGlideModule
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**
