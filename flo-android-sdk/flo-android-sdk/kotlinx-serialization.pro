-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt

-keep,includedescriptorclasses class com.flotechnologies.**$$serializer { *; }
-keepclassmembers class com.flotechnologies.** {
    *** Companion;
}
-keepclasseswithmembers class com.flotechnologies.** {
    kotlinx.serialization.KSerializer serializer(...);
}
