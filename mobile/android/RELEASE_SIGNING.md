# Android release signing

The repository deliberately contains no keystore, password, alias, or signing configuration. The checked-in Android release build uses the Android debug signing configuration only for local development and demonstrations; it must not be distributed as a production release.

Before any external Android distribution, create and protect a private release keystore outside the repository, configure the Android `release` signing configuration through the secure build environment, and verify the signed artifact on a physical device. Never commit the keystore, `key.properties`, passwords, or certificate material.
