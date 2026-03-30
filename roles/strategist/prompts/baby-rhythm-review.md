Выполни еженедельный анализ ритма Любы за прошедшую неделю.

## Шаг 1 — Сбор данных из macOS Calendar (AppleScript)

Запусти AppleScript для выгрузки событий из всех 4 календарей за последние 8 дней.
**ВАЖНО:** НЕ использовать `every event` без фильтра — таймаут. Всегда фильтровать по дате.

```bash
osascript << 'APPLESCRIPT'
set refDate to (current date) - (8 * days)
set output to ""

-- Основной календарь (с ~21 фев): события "Сон", "Кормление", "Активность"
tell application "Calendar"
    try
        set theCal to calendar "Домашний"
        set allEvents to (every event of theCal whose start date > refDate)
        repeat with e in allEvents
            set evName to summary of e
            if evName contains "Сон" or evName contains "Кормление" or evName contains "Активность" then
                set startT to start date of e
                set endT to end date of e
                set dur to (endT - startT) / 60 -- в минутах
                set output to output & "Домашний," & evName & "," & (startT as string) & "," & (endT as string) & "," & dur & "\n"
            end if
        end repeat
    end try

    -- Старые отдельные календари (данные 4-21 фев)
    repeat with calName in {"Сон", "Кормление", "Активность"}
        try
            set theCal to calendar (calName as string)
            set allEvents to (every event of theCal whose start date > refDate)
            repeat with e in allEvents
                set startT to start date of e
                set endT to end date of e
                set dur to (endT - startT) / 60
                set output to output & calName & "," & (summary of e) & "," & (startT as string) & "," & (endT as string) & "," & dur & "\n"
            end repeat
        end try
    end repeat
end tell

return output
APPLESCRIPT
```

Сохрани вывод AppleScript в переменную для передачи в Python.

## Шаг 2 — Анализ данных (Python)

Передай вывод AppleScript в Python-скрипт:

```bash
python3 << 'PYEOF'
import sys, re
from datetime import datetime, timedelta
from statistics import mean, median

# --- Данные из AppleScript (подставляются через переменную окружения) ---
import os
raw = os.environ.get("CALENDAR_DATA", "")

# --- Парсинг ---
sleep_durations = []
feed_durations = []
active_durations = []
events = []  # (datetime, type, duration_min)

for line in raw.strip().split("\n"):
    if not line.strip():
        continue
    parts = line.split(",", 4)
    if len(parts) < 5:
        continue
    cal, name, start_str, end_str, dur_str = parts
    name_lower = name.lower()
    try:
        dur = float(dur_str.strip())
    except:
        continue

    # Парсинг даты — macOS AppleScript format: "воскресенье, 16 марта 2026 г. в 14:00:00"
    # Используем dateutil для гибкого парсинга
    try:
        from dateutil import parser as dparser
        # Убираем лишнее
        clean = re.sub(r'\bг\.\b', '', start_str).strip()
        clean = re.sub(r'\bв\b', '', clean).strip()
        dt = dparser.parse(clean, dayfirst=True)
    except:
        dt = None

    etype = None
    if "сон" in name_lower:
        etype = "Сон"
        if 5 <= dur <= 300:
            sleep_durations.append(dur)
    elif "кормление" in name_lower or "питание" in name_lower:
        etype = "Кормление"
        if 1 <= dur <= 60:
            feed_durations.append(dur)
    elif "активность" in name_lower or "прогулка" in name_lower:
        etype = "Активность"
        if 5 <= dur <= 180:
            active_durations.append(dur)

    if etype and dt:
        events.append((dt, etype, dur))

# --- Статистика ---
def stats(lst):
    if not lst:
        return {"n": 0, "avg": None, "med": None, "min": None, "max": None}
    return {
        "n": len(lst),
        "avg": round(mean(lst), 1),
        "med": round(median(lst), 1),
        "min": round(min(lst), 1),
        "max": round(max(lst), 1),
    }

s_sleep = stats(sleep_durations)
s_feed = stats(feed_durations)
s_active = stats(active_durations)

# --- Цикл ПАСС ---
events_sorted = sorted(events, key=lambda x: x[0])
cycles = 0
pass_order = 0  # П→А→С

# Интервалы между кормлениями (длительность цикла)
feed_times = [dt for dt, etype, _ in events_sorted if etype == "Кормление"]
cycle_intervals = []
for i in range(1, len(feed_times)):
    delta = (feed_times[i] - feed_times[i-1]).total_seconds() / 3600  # в часах
    if 1.0 <= delta <= 5.0:  # разумный диапазон
        cycle_intervals.append(round(delta, 2))

# Проверка порядка П→А→С (в окне 3ч)
pass_checks = 0
pass_correct = 0
for i, (dt_p, tp, _) in enumerate(events_sorted):
    if tp != "Кормление":
        continue
    # Ищем Активность и Сон в следующие 3 часа
    window_end = dt_p + timedelta(hours=3)
    following = [(dt2, tp2) for dt2, tp2, _ in events_sorted if dt_p < dt2 < window_end]
    if not following:
        continue
    types_in_window = [tp2 for _, tp2 in following]
    pass_checks += 1
    # П (уже есть) → нужно А до С
    a_pos = next((j for j, t in enumerate(types_in_window) if t == "Активность"), -1)
    s_pos = next((j for j, t in enumerate(types_in_window) if t == "Сон"), -1)
    if a_pos >= 0 and s_pos >= 0 and a_pos < s_pos:
        pass_correct += 1

pass_pct = round(100 * pass_correct / pass_checks) if pass_checks > 0 else None
cycle_med = round(median(cycle_intervals), 2) if cycle_intervals else None

# --- Базовые показатели W11 ---
baseline = {
    "sleep_avg": 94,
    "active_avg": 42,
    "feed_med": 12,
    "cycle_med": 2.5,
    "pass_pct": 62,
}

# --- Вычисляем номер текущей недели Любы ---
# Дата рождения 01.01.2026
birth = datetime(2026, 1, 1)
today = datetime.now()
age_weeks = (today - birth).days // 7

# --- Отчёт ---
from datetime import date
week_start = (today - timedelta(days=today.weekday()+1)).strftime("%d.%m")  # Пн
week_end = (today - timedelta(days=today.weekday()-5)).strftime("%d.%m")  # Вс
iso_week = today.isocalendar()[1]

print(f"WEEK={iso_week}")
print(f"AGE_WEEKS={age_weeks}")
print(f"WEEK_RANGE={week_start}–{week_end}")
print(f"SLEEP_N={s_sleep['n']}")
print(f"SLEEP_AVG={s_sleep['avg']}")
print(f"SLEEP_MED={s_sleep['med']}")
print(f"SLEEP_MIN={s_sleep['min']}")
print(f"SLEEP_MAX={s_sleep['max']}")
print(f"FEED_N={s_feed['n']}")
print(f"FEED_AVG={s_feed['avg']}")
print(f"FEED_MED={s_feed['med']}")
print(f"ACTIVE_N={s_active['n']}")
print(f"ACTIVE_AVG={s_active['avg']}")
print(f"ACTIVE_MED={s_active['med']}")
print(f"CYCLE_MED={cycle_med}")
print(f"CYCLE_N={len(cycle_intervals)}")
print(f"PASS_PCT={pass_pct}")
print(f"PASS_CHECKS={pass_checks}")
# Дельты к базовым
def delta(new, base):
    if new is None or base is None: return "н/д"
    d = round(new - base, 1)
    return f"+{d}" if d >= 0 else str(d)
print(f"D_SLEEP={delta(s_sleep['avg'], baseline['sleep_avg'])}")
print(f"D_ACTIVE={delta(s_active['avg'], baseline['active_avg'])}")
print(f"D_FEED={delta(s_feed['med'], baseline['feed_med'])}")
print(f"D_CYCLE={delta(cycle_med, baseline['cycle_med'])}")
print(f"D_PASS={delta(pass_pct, baseline['pass_pct'])}")
PYEOF
```

**Техническая реализация:** передай данные через переменную окружения:
```bash
CALENDAR_DATA="$(osascript << 'AS'
... (AppleScript из шага 1) ...
AS
)" python3 << 'PYEOF'
... (Python из шага 2) ...
PYEOF
```

## Шаг 3 — Интерпретация и скачки роста

Ориентировочные скачки роста (по неделям жизни):
- ~5 нед (прошёл), ~8 нед (прошёл), **~12 нед (~конец марта — СЛЕДИТЬ)**
- ~19 нед (~начало мая), ~26 нед (~конец июня)

Признаки скачка: учащение кормлений, укорочение снов, повышенная капризность, нарушение ПАСС.

Интерпретируй изменения относительно W11-базы:
- Дельта ±10% = норма (флуктуация)
- Дельта >15% = тренд (наружать в отчёт)
- Резкое изменение (>25%) + совпадение с возрастом скачка = вероятный скачок роста

## Шаг 4 — Формирование отчёта

Создай файл `DS-strategy/current/BabyRhythm-W{N}-YYYY-MM-DD.md` (N = номер ISO-недели, дата = сегодня):

```markdown
---
type: baby-rhythm-review
date: YYYY-MM-DD
week: W{N}
age_weeks: {AGE_WEEKS}
agent: Стратег
---

# Анализ ритма Любы: W{N} ({WEEK_RANGE})

**Возраст:** ~{AGE_WEEKS} нед | **Данные:** {SLEEP_N} снов, {FEED_N} кормлений, {ACTIVE_N} активностей

---

## Ключевые показатели

| Показатель | W{N} (факт) | База W11 | Δ |
|-----------|-------------|---------|---|
| Сон (ср., мин) | {SLEEP_AVG} | 94 | {D_SLEEP} |
| Активность (ср., мин) | {ACTIVE_AVG} | 42 | {D_ACTIVE} |
| Кормление (медиана, мин) | {FEED_MED} | 12 | {D_FEED} |
| Цикл П→П (медиана, ч) | {CYCLE_MED} | 2.5 | {D_CYCLE} |
| Порядок П→А→С | {PASS_PCT}% | 62% | {D_PASS} |

## Диапазоны

- Сон: {SLEEP_MIN}–{SLEEP_MAX} мин (медиана {SLEEP_MED})

## Интерпретация

[Стратег заполняет: тренды, аномалии, вероятные скачки]

## Скачки роста

[Оценка: совпадает ли с возрастом скачка? Признаки есть/нет]

## Рекомендации

[1-3 конкретных наблюдения для мамы]

---

*Создан автоматически: YYYY-MM-DD (baby-rhythm-review)*
```

## Шаг 5 — Сохранение

1. Сохрани отчёт в `DS-strategy/current/BabyRhythm-W{N}-YYYY-MM-DD.md`
2. Закоммить: `git add current/ && git commit -m "feat: baby rhythm review W{N}"`

**Формат интерпретации:** Конкретные наблюдения (факты), без общих фраз. Если данных мало (< 5 событий типа) — указать «данных недостаточно» и не делать выводы.
