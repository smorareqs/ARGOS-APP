# Cómo desarrollar y probar la app

Guía para dejar lista tu computadora y correr la app ARGOS. Si algo falla, corre
`flutter doctor` y te dice qué falta.

## 1. Programas que necesitas

| Programa | Para qué | Windows | Mac |
| --- | --- | --- | --- |
| Git | Bajar y subir el código | [git-scm.com](https://git-scm.com/downloads) | Viene con Xcode o `xcode-select --install` |
| Flutter SDK 3.35.x, la misma versión del equipo (incluye Dart) | Compilar y correr la app | [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) | Igual |
| VS Code + extensiones **Flutter** y **Dart** | Escribir código y correr la app con F5 | [code.visualstudio.com](https://code.visualstudio.com/) | Igual |
| Android Studio | SDK de Android y emulador | [developer.android.com/studio](https://developer.android.com/studio) | Igual |
| Xcode + CocoaPods | Simulador de iPhone | No disponible | App Store; luego `sudo gem install cocoapods` |
| Docker Desktop | Correr el backend en tu compu (cuando conectemos al servidor real) | [docker.com](https://www.docker.com/products/docker-desktop/) | Igual |

En Windows casi todo se instala desde PowerShell con `winget`:

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Google.AndroidStudio -e
winget install --id Docker.DockerDesktop -e
```

Flutter no está en `winget`: descarga el zip de **Flutter 3.35.7 (stable)** desde el archivo
de versiones de Flutter (https://docs.flutter.dev/install/archive), descomprímelo en
`C:\src\flutter-3.35.7` y agrega `C:\src\flutter-3.35.7\bin` al `Path` de tu usuario
(Configuración → "Editar las variables de entorno"). Activa también el **Modo de desarrollador** de Windows
(Configuración → Sistema → Para programadores), que Flutter necesita para los plugins.

**Java:** el proyecto usa Gradle 8.12, que necesita Java 17 a 21 (el Java 25 que trae Android
Studio no sirve). Instala Temurin 17 (`winget install --id EclipseAdoptium.Temurin.17.JDK -e`)
y corre `flutter config --jdk-dir="<ruta del JDK 17>"`.

Después de instalar Android Studio, ábrelo una vez y en *More Actions → SDK Manager*
instala "Android SDK Command-line Tools". Luego en la terminal:

```sh
flutter doctor --android-licenses   # acepta todo con "y"
flutter doctor                      # todo en verde (Xcode solo importa en Mac)
```

Crea un emulador en Android Studio: *More Actions → Virtual Device Manager → Create
device* (por ejemplo un Pixel con la versión más nueva de Android).

## 2. Bajar el proyecto

```sh
git clone https://github.com/smorareqs/ARGOS-APP.git
cd ARGOS-APP
git checkout staging
git checkout -b dev-chris   # tu rama de trabajo
flutter pub get
```

Abre la carpeta en VS Code (`code .`).

## 3. Correr la app

1. Prende el emulador (o conecta tu Android con "depuración USB" activada).
2. En VS Code abre la pestaña *Run and Debug* (el ícono de play con un bicho).
3. Elige una configuración y presiona **F5**:
   * **ARGOS (datos de prueba)**: no necesita backend; usa datos falsos (`ARGOS_MOCK=true`).
   * **ARGOS (backend local)**: habla con ARGOS-SERVICE corriendo con `docker compose up`
     en tu compu (`http://10.0.2.2:8000/api/v1` desde el emulador de Android).

Con la app corriendo, guarda un archivo y verás el cambio al instante (*hot reload*).

Desde la terminal es lo mismo:

```sh
flutter run --dart-define=ARGOS_MOCK=true
```

Si usas un teléfono físico con el backend local, cambia `10.0.2.2` por la IP de tu
computadora en la red Wi-Fi.

## 4. Antes de subir cambios

```sh
dart run build_runner build --delete-conflicting-outputs   # si tocaste providers o tablas
flutter analyze
flutter test
```

## 5. Cómo trabajamos

* Una rama por cambio (`feat/f<fase>-<tema>`), PR pequeño, se prueba en el emulador y se
  fusiona. Reglas completas en [`plans/reparto.md`](plans/reparto.md).
* Cada cosa terminada se anota en [`plans/avance.md`](plans/avance.md) con `[B]`.
