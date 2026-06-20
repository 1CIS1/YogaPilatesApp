# Иконка и сплэш — исходники

Здесь лежат **векторные исходники-плейсхолдеры** (монограмма «фигура в позе лотоса»
на бренд-градиенте #1A73E8 → #34A853). Генераторы иконок/сплэша требуют **PNG**,
поэтому SVG нужно экспортировать в PNG (или заменить своими картинками).

## Нужные PNG-файлы

| Файл | Размер | Из чего |
|---|---|---|
| `icon.png` | 1024×1024 | `icon.svg` (с фоном) |
| `icon_foreground.png` | 1024×1024 | `icon_foreground.svg` (прозрачный фон) |
| `splash_logo.png` | 768×768 | `splash_logo.svg` (прозрачный фон) |

## Как экспортировать SVG → PNG

Любой из вариантов:

- **Онлайн**: cloudconvert.com / svgtopng.com — загрузить SVG, указать размер, скачать.
- **Inkscape**:
  ```bash
  inkscape assets/icon/icon.svg --export-type=png --export-filename=assets/icon/icon.png -w 1024 -h 1024
  inkscape assets/icon/icon_foreground.svg --export-type=png --export-filename=assets/icon/icon_foreground.png -w 1024 -h 1024
  inkscape assets/icon/splash_logo.svg --export-type=png --export-filename=assets/icon/splash_logo.png -w 768 -h 768
  ```
- **rsvg-convert**:
  ```bash
  rsvg-convert -w 1024 -h 1024 assets/icon/icon.svg -o assets/icon/icon.png
  ```

## Сгенерировать иконки и сплэш

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

> Это создаст иконки во всех плотностях для Android и наборы для iOS, а также
> нативные сплэш-экраны. Своя финальная иконка студии просто кладётся вместо
> `icon.png` (1024×1024, без прозрачности для iOS).
