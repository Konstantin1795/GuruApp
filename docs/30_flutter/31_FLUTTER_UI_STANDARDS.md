# 31 — Flutter UI Standards / UI-стандарты GURU

Стабильный файл.  
Меняется редко.

---

## 1. Общий стиль

GURU UI:

```text
тёмная тема
современный fintech mobile style
glass-like карточки
единый акцентный цвет
читаемые отступы
без перегруза
```

Акцент:

```text
#00D6C9
```

---

## 2. Core widgets

Использовать:

```text
AppScaffold
AppCard
AppButton
AppInput
AppLoader
AppEmptyState
AppSectionTitle
```

Не создавать одноразовые стили, если можно использовать core widgets.

---

## 3. Colors

Файл:

```text
app_colors.dart
```

Базовые цвета:

```text
accent = #00D6C9
bg = #0B0F14
surface = #0F141B
error = #FF6B6B
success = #4ADE80
warning = #FFB347
```

---

## 4. Typography

Файл:

```text
app_text_styles.dart
```

Ориентир:

```text
screen title: 22 / 800
card title: 18 / 700
section title: 13 / 700
body large: 16 / 400
body: 15 / 400
body strong: 15 / 600
caption: 12 / 400
button: 15 / 700
```

---

## 5. Spacing

Файл:

```text
app_spacing.dart
```

Разрешённая шкала:

```text
4
8
12
16
20
24
32
```

Не использовать случайные отступы.

---

## 6. Radii

Файл:

```text
app_radii.dart
```

Значения:

```text
12
16
20
24
28
999
```

---

## 7. Иконки

Иконки должны быть из одной стандартной Flutter/Material библиотеки, если не согласовано иное.

Иконки должны быть:

```text
одного визуального стиля
без смешивания разных наборов
в одном размере внутри одного блока
```

---

## 8. Анимации

Использовать лёгкие стандартные Flutter-анимации:

```text
AnimatedSwitcher
AnimatedContainer
AnimatedOpacity
PageRoute transitions
implicit animations
```

Не добавлять тяжёлые animation packages без причины.

---

## 9. Кнопки

Кнопки через:

```text
AppButton
```

Соблюдать:

```text
одинаковая высота
единые отступы
primary / secondary style
disabled state
loading state, если действие долгое
```

---

## 10. Поля ввода

Поля через:

```text
AppInput
```

Соблюдать:

```text
единый стиль
понятная ошибка
не наползать на кнопки
корректная клавиатура для сумм
```

---

## 11. Карточки

Карточки через:

```text
AppCard
```

Соблюдать:

```text
единые радиусы
единые отступы
одинаковая плотность текста
не перегружать данными
```

---

## 12. Русский интерфейс

В русском режиме не должно быть английских слов.

Все строки через l10n.

---

## 13. Экран операции

Для деталей операции показывать:

```text
статус
сумму
проект
участников
комментарий
историю lifecycle
доступные действия
```

Кнопки — только по `available_actions`.

---

## 14. Диалог комментария

Для действий с обязательным комментарием использовать общий диалог:

```text
showOperationCommentDialog
```

Например:

```text
отклонение
откат
возврат с причиной
```
