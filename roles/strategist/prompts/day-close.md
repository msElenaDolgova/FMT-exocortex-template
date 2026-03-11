Выполни сценарий Day-Close для роли Стратег (R1).

> **Триггер:** Ручной — по запросу пользователя (`./scripts/strategist.sh day-close`).
> Отдельный файл отчёта НЕ создаётся. Итоги дня войдут в DayPlan следующего утра.

Источник сценария: /Users/elenadolgova/IWE/CLAUDE.md → Протокол Day-Close

## Контекст

- **WeekPlan:** /Users/elenadolgova/IWE/DS-strategy/current/WeekPlan W*.md (последний по дате)
- **MEMORY:** ~/.claude/projects/-Users-elenadolgova-IWE/memory/MEMORY.md
- **Exocortex backup:** /Users/elenadolgova/IWE/DS-strategy/exocortex/

## Алгоритм

### 1. Сбор коммитов за сегодня

```bash
# Для КАЖДОГО репо в /Users/elenadolgova/IWE/:
git -C /Users/elenadolgova/IWE/<repo> log --since="today 00:00" --oneline --no-merges
```

- Пройди по ВСЕМ репозиториям в `/Users/elenadolgova/IWE/`
- Сгруппируй коммиты по репозиториям
- Сопоставь с РП из недельного плана
- Определи статус каждого затронутого РП: done / partial / not started
- Выведи итоги на экран (не в файл)

### 2. Обновить WeekPlan

Найди текущий `WeekPlan W*.md` в `DS-strategy/current/` и обнови:

- Пометь завершённые РП как **done**
- Обнови статусы partial с описанием прогресса
- Добавь carry-over (что переносится на завтра) — в конец файла
- **НЕ удаляй** ничего — только помечай и дописывай

### 3. Обновить MEMORY.md

Синхронизируй статусы РП в MEMORY.md с обновлённым WeekPlan:
- done → done
- partial → in_progress (с пометкой прогресса)
- Удали завершённые РП из pending, если они в done

### 4. Backup экзокортекса

Скопируй актуальные файлы в `/Users/elenadolgova/IWE/DS-strategy/exocortex/`:

```bash
# Корневой CLAUDE.md
cp /Users/elenadolgova/IWE/CLAUDE.md /Users/elenadolgova/IWE/DS-strategy/exocortex/CLAUDE.md

# Memory (Слой 3)
cp ~/.claude/projects/-Users-elenadolgova-IWE/memory/MEMORY.md /Users/elenadolgova/IWE/DS-strategy/exocortex/MEMORY.md
cp ~/.claude/projects/-Users-elenadolgova-IWE/memory/*.md /Users/elenadolgova/IWE/DS-strategy/exocortex/
```

### 5. Закоммитить

- Закоммить все изменения в `DS-strategy` (WeekPlan + exocortex backup)
- Запуши

## Правила

- **Ничего не удалять** из WeekPlan — только помечать и дописывать
- **Не создавать отдельный файл отчёта** — итоги дня войдут в DayPlan следующего утра (шаг 1 day-plan)
- Если коммитов за день нет — написать «Нет активности» и всё равно сделать backup
- Выводить итоги на экран для пользователя

## Вывод на экран (шаблон)

```
📋 Day-Close: DD месяца YYYY

Коммиты: N в M репо
- repo-name: N коммитов (краткое описание)

РП обновлены в WeekPlan:
- #N: статус → новый статус

MEMORY.md: синхронизирован ✅
Exocortex backup: скопирован ✅
Git: закоммичен и запушен ✅
```

Результат: обновлённый WeekPlan + MEMORY.md + backup экзокортекса.
