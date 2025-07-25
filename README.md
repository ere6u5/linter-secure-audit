# Отчет по Secure Coding

В ходе выполнения задания были проанализированы три open-source проекта на разных языках программирования с использованием статических анализаторов кода. Основное внимание уделялось выявлению security-related проблем.

## Инструменты

| Язык       | Инструмент               | Плагины безопасности               |
|------------|--------------------------|-------------------------------------|
| **Python** | Flake8                   | bandit, bugbear, logging-format     |

### Установка

- **Python**: Flake8 с дополнительными плагинами
```bash
pip install flake8-bandit flake8-bugbear flake8-logging-format flake8-tidy-imports flake8-pie flake8-docstrings
```

Файл конфигурации может иметь названия `setup.cfg`, `.flake8` или `tox.ini`. Примерная структура файла выглядит так:

```bash
[flake8]
max-line-length = 300
filename = *.py

exclude=
...

enable-extensions = 
    G,  # flake8-logging-format
    S,  # flake8-bandit (security)
    B,  # flake8-bugbear

select =
...
```

> Для анализа проекта использовался [`setup.cfg`](./projects/python/setup.cfg)

## Анализируемые проекты

### Python/Flake8

**WeBob** - библиотека для работы с HTTP-запросами и ответами в Python. Предоставляет объекты-обертки для WSGI-окружения, упрощающие парсинг запросов и формирование ответов.

**Ссылка на репозиторий:**

**https://github.com/Pylons/webob**

```bash
git submodule add https://github.com/Pylons/webob ./projects/python/webob
```

### Анализ безопасности

Для удобства проведения аудита был разработан Bash-скрипт [`flake8_audit.sh`](./projects/python/flake8_audit.sh), который:

1. Запускает проверку кода
2. Генерирует структурированный отчёт
3. Сохраняет результаты в файлы:
    - `webob.audit` (полные логи)
    - `webob.summary` (статистика)

### Чек-лист из файла [`webob.summary`](./projects/python/webob.summary)

| Категория                | Количество  | Уязвимости                          |
|--------------------------|-------------|-------------------------------------|
| **Безопасность**         | 2573        |`S101`, `S603`, `S108`, `S324`, `S607`, `S404`, `S311`|
| **Документация**         | 2207        |`D102`, `D103`, `D400`, `D202`, `D101`, `D105`, `D200`, `D205`, `D100`, `D107`, `D401`, `D209`, `D412`, `D301`, `D403`, `D104`|
| **Потенциальные ошибки** | 53          |`B028`,`B010`,`B015`,`B009`,`B036`,`B023`       |
| **Прочие**               | 30          |...                                |
| **Всего**                | 4863        |

### Топ-3 security-проблемы

---
#### S101: Небезопасное использование `assert` для валидации (Production)

**Уязвимый код:**

- [`response.py:1569-1570:1`](./projects/python/webob/src/webob/response.py)
```python
def __init__(self, app_iter, start, stop):
    assert start >= 0, "Bad start: %r" % start
    assert stop is None or (stop >= 0 and stop >= start), "Bad stop: %r" % stop
```

- [`response.py:1594:1`](./projects/python/webob/src/webob/response.py)
```python
if stop is not None and self._pos > stop:
    chunk = chunk[: stop - self._pos]
    assert len(chunk) == stop - start
```

**Статус**

**Суть проблемы:**
- Использование `assert` для проверки входных параметров и условий в production
- При использования флага оптимизации - проверки `assert` будут опущены
- Проблема обнаружена в основном коде(не в тестах)

**Оценка риска**
- Высокий (для production кода с флагом `python -O`)

**Потенциальные проблемы:**
- Критичные ошибки в работе приложения
- Невалидные данные могут пройти проверку

**Рекомендации по исправлению**
- Использование инструкции `raise` вместо `assert`. Например:
```python
if start < 0:
    raise ValueError(f"Invalid start value: {start}")
```

---
#### S603 Выполнение произвольных команд (Testing)

**Уязвимый код:**

- [`perfomance_test.py:37:1`](./projects/python/webob/tests/performance_test.py)
```python
proc = subprocess.Popen([sys.executable, __file__]) # Исполнение текущего файла
```

- [`performance_test.py:39:1`](./projects/python/webob/tests/performance_test.py)
```python
subprocess.call(["ab", "-n", "1000", "http://localhost:8080/"]) # вызов внешней утилиты
```

**Статус**

**Суть проблемы:**
- Прямой вызов субпроцессов с динамическими параметрами

**Оценка риска:**
- Низкий (используется в тестовом окружении)

**Потенциальные проблемы:**
- Отсутствие обработки ошибок при отсутствии `ab` в системе

**Потенциальные последствия:**
- Исполнение произвольного кода (RCE) в тестовом окружении через подмену `__file__`

**Рекомендация:**
- Использовать Whitelist для разрешенных команд
- Заменить код на чистый Python. Если в окружении нет явного `ab` - возможны ошибки.

---
#### S108: Небезопасная работа с временными файлами (Testing)

**Уязвимый код:**

- [`perfomance_test.py:10:1`](./projects/python/webob/tests/performance_test.py)
```python
log_filename="/tmp/profile.log",
```

- [`test_static.py:62:1`](./projects/python/webob/tests/test_static.py)
```python
app = static.FileApp("/tmp/this/doesnt/exist")
```

**Статус**

**Суть проблемы:**
- Использование фиксированных путей `/tmp` без контроля

**Оценка риска:**
- Низкий (используется тестовое окружение)

**Потенциальные проблемы:**
- Утечка данных между тестами

**Потенциальные последствия:**
- Перезапись файлов при параллельном запуске тестов

**Рекомендация:**
- Исправить в рамках рефакторинга







## JavaScript/ESlint

(содержание аудита javascript)

## Ruby/RuboCop

(содержание аудита ruby)
