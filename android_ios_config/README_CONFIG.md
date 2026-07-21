# Configuration native Android & iOS

Ces permissions sont nécessaires pour la **caméra** (scanner de QR) et les
**notifications**. Applique-les après avoir généré les dossiers `android/` et
`ios/` avec `flutter create .` (voir le README principal).

---

## ANDROID

### 1. `android/app/src/main/AndroidManifest.xml`
Ajoute ces lignes **juste avant** la balise `<application>` :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

### 2. `android/app/build.gradle` (ou `build.gradle.kts`)
`mobile_scanner` exige `minSdk 21` minimum :

```gradle
android {
    defaultConfig {
        minSdk = 21   // ou flutter.minSdkVersion s'il vaut déjà >= 21
    }
}
```

---

## iOS

### `ios/Runner/Info.plist`
Ajoute ces clés dans le `<dict>` principal :

```xml
<key>NSCameraUsageDescription</key>
<string>Liste Party utilise la caméra pour scanner les QR codes des billets à l'entrée.</string>
```

Les notifications locales demandent l'autorisation au premier lancement
(rien à ajouter dans l'Info.plist pour ça).

### `ios/Podfile`
Assure-toi que la plateforme minimale est iOS 12 ou plus :

```ruby
platform :ios, '13.0'
```
