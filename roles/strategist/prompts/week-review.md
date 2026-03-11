Выполни сценарий Week Review для роли Стратег (R1).

> **Триггер:** Автоматический — Пн 00:00 (полночь Вс→Пн, launchd).
> Создаёт WeekReport для клуба. Служит входом для session-prep (Пн 4:00).

> Source-of-truth: DP.ROLE.012-strategist (PACK-digital-platform). Алгоритм полностью описан ниже.

## Контекст

- **WeekPlan:** /Users/elenadolgova/IWE/DS-strategy/current/WeekPlan W*.md
- **Шаблон:** см. секцию «Шаблон WeekReport» ниже

### 0. WakaTime — время работы за неделю

> Данные автоматически подставляются из WakaTime API.
> Включи секцию WakaTime в WeekReport после метрик коммитов.
> Если данных нет — напиши: «WakaTime: нет данных за неделю».

{{WAKATIME_WEEK}}

## Алгоритм

### 1. Сбор данных (Стратег собирает сам)

```bash
# Для КАЖДОГО репо в /Users/elenadolgova/IWE/:
git -C /Users/elenadolgova/IWE/<repo> log --since="last monday 00:00" --until="today 00:00" --oneline --no-merges
```

- Пройди по ВСЕМ репозиториям в `/Users/elenadolgova/IWE/`
- Загрузи текущий WeekPlan из `DS-strategy/current/`
- Сопоставь коммиты с РП из WeekPlan
- Определи статус каждого РП: done / partial / not started

### 2. Статистика

- Completion rate: X/Y РП (N%)
- Коммитов всего
- Активных дней (дни с коммитами)
- По репозиториям (таблица)
- По системам (Созидатель, Экосистема, ИТ-платформа, Бот)

### 3. Инсайты

- Что получилось хорошо
- Что можно улучшить
- Блокеры (если были)
- Carry-over на следующую неделю

### 4. Формат для клуба

- Используй шаблон `weekly-review.md` (если есть)
- Добавь хештеги
- Формат: компактный, читаемый, с метриками

### 5. Сохранение

1. Создай `current/WeekReport W{N} YYYY-MM-DD.md`
2. Закоммить в DS-strategy

### 6. Создать пост для клуба (опционально)

> Шаг выполняется только если у пользователя настроен Knowledge Index — surface downstream репо для публикаций.
> Проверь: существует ли директория `/Users/elenadolgova/IWE/DS-Knowledge-Index-msElenaDolgova/`?
> Если нет — пропусти шаг 6 полностью.

1. Переключись на **роль Автора (R4)** и на основе WeekReport сформируй пост для клуба.

   **Обязательно прочитай** `/Users/elenadolgova/IWE/DS-Knowledge-Index-msElenaDolgova/CLAUDE.md` — полные инструкции роли Автора:
   - § 2 — стандарт названий для итогов недели
   - § 3 — формат поста: аудитория `community`, структура для тега `итоги-недели`

   Стратег отвечает за **данные** (метрики, факты, сравнения). Автор отвечает за **подачу** (голос, структура, стиль).

   **Обязательные данные от Стратега → Автору:**
   - Метрики недели (коммиты, completion rate, сравнение с прошлой неделей)
   - Ключевые факты (что реально было сделано)
   - Carry-over → W{N+1} (из WeekReport, секция «Carry-over»)
   - Фокус следующей недели (из WeekReport, секция «Следующая неделя»)

   Выбери лучшее название сам (в автоматическом режиме нет пользователя для выбора).

2. Создай файл `/Users/elenadolgova/IWE/DS-Knowledge-Index-msElenaDolgova/docs/{YYYY}/{YYYY-MM-DD}-week-review-w{N}.md`

3. Frontmatter:

```yaml
---
type: post
title: "..."
audience: community
status: ready
created: YYYY-MM-DD
target: club
source_knowledge: null
tags: [итоги-недели, W{N}]
content_plan: null
---
```

4. Обнови `/Users/elenadolgova/IWE/DS-Knowledge-Index-msElenaDolgova/docs/README.md` — добавь строку в начало текущего месяца
5. Закоммить и запушь Knowledge Index (git add docs/ && git commit && git push)

**Шаблон WeekReport:**

```markdown
---
type: week-report
week: W{N}
date: YYYY-MM-DD
status: final
agent: Стратег
---

# WeekReport W{N}: DD мес — DD мес YYYY

## Метрики
- **РП:** X/Y завершено (N%)
- **Коммитов:** N в M репо
- **Активных дней:** N/7

## По репозиториям

| Репо | Коммиты | Основные изменения |
|------|---------|-------------------|
| ... | ... | ... |

## РП

| # | РП | Статус | Комментарий |
|---|-----|--------|-------------|
| ... | ... | done/partial/⬜ | ... |

## Инсайты
- ...

## Carry-over
- ...

---

*Создан: YYYY-MM-DD (Week Review)*
```

Результат:
- WeekReport в `current/` — как вход для session-prep
- (Опционально) Пост итогов в Knowledge Index со `status: ready`
