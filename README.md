# Отчет по Secure Coding

В ходе выполнения задания были проанализированы три open-source проекта на разных языках программирования с использованием статических анализаторов кода. Основное внимание уделялось выявлению security-related проблем.

## Инструменты

| Язык           | Инструмент               | Плагины безопасности               |
|----------------|--------------------------|-------------------------------------|
| **Python**     | Flake8                   | `bandit`, `bugbear`, `logging-format`     |
| **JavaScript** | ESLint | `eslint-plugin-security`, `eslint-plugin-security-node`, `eslint-plugin-no-secrets`, `eslint-plugin-promise` |
| **Ruby** | RuboCop | `rubocop-security`, `rubocop-thread_safety` |

> Для автоматизации процессов можно написать `pipeline` для сохранения аудитов в виде артефактов, чтобы они сохранялись на 7 дней

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

---

- **JavaScript**: ESLint с дополнительными плагинами

```bash
npm init -y
npm install --save-dev \
  eslint@latest \
  @eslint/js \
  eslint-plugin-security \
  eslint-plugin-security-node \
  eslint-plugin-no-secrets \
  eslint-plugin-promise \
  @typescript-eslint/eslint-plugin
```

Файл конфигурации в версии `>9.0` имеет название `eslint.config.mjs`. Примерная структура файла выглядит так:
```javascript
import js from '@eslint/js';
...

export default [
  {
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        node: true,
        browser: true,
      },
    },
  },

  js.configs.recommended,

  {
    plugins: {
      security,
      'security-node': securityNode,
      'no-secrets': noSecrets,
      promise,
    },
    rules: {
        ...
    },
  },

  // TypeScript
  {
    files: ['**/*.ts', '**/*.tsx'],
    ...ts.configs['eslint-recommended'],
    ...ts.configs['recommended'],
    rules: {
        ...
    },
  },

  // Ignored files
  {
    ignores: [
        ...
    ],
  },
];
```
> Для анализа проекта использовался [`eslint.config.mjs`](./projects/javascript/eslint.config.mjs)

---

- **Ruby**: RubyCop с дополнительными плагинами
```bash
sudo gem install rubocop rubocop-rails rubocop-performance rubocop-rspec rubocop-security brakeman rubocop-md rubocop-thread_safety bundler-audit rubocop-erb
```

Файл конфигурации в версии `>=3.2` имеет название `.rubocop.yml`. Примерная структура файла выглядит так:
```yaml
plugins:
  - rubocop-rails
  - rubocop-performance
  - rubocop-rspec
  - rubocop-md
  - rubocop-thread_safety
  - rubocop-erb

AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2
  DisplayCopNames: true
  SuggestExtensions: false
  DisabledByDefault: false
  Include:
    - '**/*.rb'
    ...
  Exclude:
    - 'db/**/*'
    ...
...
```

> Для анализа проекта использовался [`.rubocop.yml`](./projects/ruby/.rubocop.yml).

> `bundler-audit` и `brakeman` дополнительные инструменты, однако в рамках отчёта они не будут использоваться.

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

**Ссылки**

- [CWE-617: Reachable Assertion](https://cwe.mitre.org/data/definitions/617.html)

---
#### S603: Выполнение произвольных команд (Testing)

**Уязвимый код:**

- [`perfomance_test.py:37:1`](./projects/python/webob/tests/performance_test.py)
```python
proc = subprocess.Popen([sys.executable, __file__]) # Исполнение текущего файла
```

- [`performance_test.py:39:1`](./projects/python/webob/tests/performance_test.py)
```python
subprocess.call(["ab", "-n", "1000", "http://localhost:8080/"]) # вызов внешней утилиты
```

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

**Ссылки**
- [CWE-78: Improper Neutralization of Special Elements used in an OS Command ('OS Command Injection')](https://cwe.mitre.org/data/definitions/78.html)

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

**Ссылки**
- [CWE-377: Insecure Temporary File](https://cwe.mitre.org/data/definitions/377.html)

## JavaScript/ESLint

**Eve** - JavaScript библиотека для визуализации данных с использованием D3.js. Предоставляет компоненты для построения сложных интерактивных диаграмм и карт.

**Ссылка на репозиторий:**

**https://github.com/ozdemiri/eve**
```javascript
git submodule add https://github.com/ozdemiri/eve.git ./projects/javascript/eve
```

### Анализ безопасности

Для удобства проведения аудита был разработан Bash-скрипт [`eslint_audit.sh`](./projects/javascript/eslint_audit.sh), который:

1. Запускает проверку кода
2. Генерирует структурированный отчёт
3. Сохраняет результаты в файлы:
    - `eve.audit` (полные логи)
    - `eve.summary` (статистика)

### Чек-лист из файла [`eve.summary`](./projects/javascript/eve.summary)

| Категория                | Количество | Уязвимости |
|--------------------------|------------|------------|
| **Critical Security**    | 1216       | Object Injection, Code Injection, Hardcoded Secrets |
| **High Risk Issues**     | 831        | Undefined Variables, Unsafe Operations |
| **Code Quality**        | 359        | Unused Variables |
| **Best Practices**      | 34         | Promise Handling |
| **Other Issues**        | 1347       | Undefined globals, Prototype access |
| **Всего**               | 3633       |            |


### Топ-3 security-проблемы

---

#### Non-literal Resource

**Уязвимый код**

- [`eve.js:883:21`](./projects/javascript/eve/src/eve.js)
```javascript
name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
let regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
```

**Суть проблемы**
1. **Использование регулярных выражений на основе ввода:**
    - Если `name` содержит специальные символы для `RegExp`, это может сломать логику проверки или привести к ReDoS (Regular Expression Denial of Service), если злоумышленник передаст какой-либо сложный паттерн

**Риски**
| Угроза               | Уровень  | Последствия                                                                 |
|----------------------|----------|-----------------------------------------------------------------------------|
| **ReDoS**            | Высокий  | Увеличение нагрузки на CPU (отказ в обслуживании)                          |
| **Логическая ошибка** | Средний  | Некорректное извлечение параметров                                  |
| **Инъекция**         | Низкий   | В редких случаях — выполнение произвольного кода через сложные регулярки   |

**Рекомендации**

1. Использовать экранирование символов, если `name` - внешний параметр
```javascript
function escapeRegExp(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

const safeName = escapeRegExp(name);
const regex = new RegExp("[\\?&]" + safeName + "=([^&#]*)");
```

2. Использовать заранее разрешённые параметры для `name`:
```javascript
const ALLOWED_PARAMS = ['id', 'name', 'page'];
if (!ALLOWED_PARAMS.includes(name)) throw new Error('Invalid param');

const regex = new RegExp(`[\\?&]${name}=([^&#]*)`);
```

**Ссылки**

- [CWE-185: Incorrect Regular Expression](https://cwe.mitre.org/data/definitions/185.html)

---

#### Code Injection

**Уязвимый код**

- [`eve.js:853:17`](./projects/javascript/eve/src/eve.js)
```javascript
eval('sub.' + key1 + ' = base.' + key1);
```

**Суть проблемы**  
1. **Динамическое выполнение кода через `eval`**  
   - Позволяет выполнить произвольный JavaScript-код при контроле над `key1`

2. **Возможность инъекции кода**  
   - Если атакующий может контролировать свойства объекта `base`, он может:
     - Внедрить вредоносный JavaScript-код
     - Выполнить произвольные операции в контексте приложения

**Оценка риска**
| Риск                | Уровень  | Обоснование                                                                 |
|---------------------|----------|-----------------------------------------------------------------------------|
| Инъекция кода       | Критический | Может привести к полному компрометированию приложения (RCE)               |
| Утечка данных       | Высокий  | Позволяет получить доступ к чувствительной информации в контексте         |
| Нарушение работы    | Высокий  | Может привести к изменению логики работы приложения                       |

**Рекомендации**

1. **Избегать использования `eval`:** Заменить на безопасные альтернативы
2. **Использовать строгий режим:** Добавить `'use strict'` для ограничения контекста `eval`

**Ссылки**
- [CWE-95: Improper Neutralization of Directives in Dynamically Evaluated Code ('Eval Injection')](https://cwe.mitre.org/data/definitions/95.html)
---

#### Hardcoded Secret

**Уязвимый код**

В трёх местах обнаружены захардкоженные API ключи, seed для генерации и закоментированная юрла.

- [`eve.js:146:20`](./projects/javascript/eve/src/eve.js)
```javascript
vectorKey: "TiNL5etp1GifX4gsKGzS"
```
- [`eve.js:739:21`](./projects/javascript/eve/src/eve.js)
```javascript
eve.randColor = function () {
    let chars = '0123456789ABCDEF'.split(''),
        color = '#';

    for (let i = 0; i < 6; i++)
        color += chars[Math.floor(Math.random() * 16)];

    return eve.hexToRgbString(color);
};
```

- [`eve.vectortileconverter.js:1709:1`](./projects/javascript/eve/src/maps/eve.vectortileconverter.js)
```javascript
//# sourceMappingURL=Leaflet.VectorGrid.bundled.js.map
```

**Суть проблемы**  
1. **API-ключ MapTiler**  
   - Ключ `TiNL5etp1GifX4gsKGzS` жёстко закодирован в коде, что позволяет:
     - Получить доступ к платным возможностям сервиса.

2. **Псевдослучайная генерация цвета**  
   - Фиксированный набор символов (`0123456789ABCDEF`) снижает энтропию генерации.

3. **Раскрытие структуры проекта**  
   - Закомментированный путь к sourcemap-файлу может раскрыть внутреннюю структуру файлов.

**Оценка риска**
| Риск                | Уровень  | Обоснование                                                                 |
|---------------------|----------|-----------------------------------------------------------------------------|
| Утечка API-ключа    | Высокий  | Может привести к финансовым потерям и злоупотреблению сервисом.            |
| Слабая генерация    | Низкий   | Не влияет на безопасность.     |
| Раскрытие структуры | Средний  | Может упростить анализ кода для атакующего.                                |

**Рекомендации**
1. Для API ключа использовать переменные окружения.
2. Для генерации цвета использовать `crypto` библиотеки.
3. Для комментария - удалить перед продакшеном.

**Ссылки**
- [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)

## Ruby/RuboCop

**Evally** - веб-приложение для управления оценкой навыков сотрудников.

**Ссылка на репозиторий:**

**https://github.com/mjjar/evally**
```javascript
git submodule add https://github.com/mjjar/evally.git ./projects/ruby/evally
```

### Анализ безопасности

Для удобства проведения аудита был разработан Bash-скрипт [`rubocop_audit.sh`](./projects/ruby/rubocop_audit.sh), который:

1. Запускает проверку кода
2. Генерирует структурированный отчёт
3. Сохраняет результаты в файлы:
    - `rubocop.audit` (полные логи)
    - `rubocop.summary` (статистика)

### Чек-лист из файла [`rubocop.summary`](./projects/ruby/rubocop.summary)

| Категория                | Количество | Доля   | Основные проблемы |
|--------------------------|------------|--------|-------------------|
| **Security Issues**      | 1          | 0.2%   | Использование eval |
| **Lint Issues**          | 2          | 0.3%   | Пропущен super, пустые файлы |
| **Metrics Issues**       | 13         | 2.1%   | Длинные методы/блоки |
| **Style Issues**         | 303        | 49.8%  | Строковые литералы, frozen strings |
| **Layout Issues**        | 37         | 6.1%   | Длина строк, выравнивание |
| **RSpec Issues**         | 229        | 37.6%  | Длина примеров, множественные expectations |
| **Rails Issues**         | 14         | 2.3%   | Безопасность файловых путей |
| **Thread Safety**        | 9          | 1.5%   | Переменные класса, Dir.chdir |
| **Всего**               | 609        | 100%   |                   |

### Топ-3 security-проблемы

---
#### Security/Eval: Использование опасной инструкции `eval`

**Уязвимый код**

- [`eval.rb:3:8`](./projects/ruby/evally/spec/cypress/app_commands/eval.rb)
```ruby
Kernel.eval(command_options) unless command_options.nil?
```

**Суть проблемы**  

1. **Использование eval в тестах**  
   - Код находится в директории `spec` (тесты)
   - Используется для динамического выполнения команд в тестовой среде
   - Технически представляет меньший риск, чем в production-коде

2. **Потенциальные риски**:
   - Возможность выполнения произвольного кода при:
     - Неправильной настройке CI/CD
     - Использовании тестовых данных из ненадёжных источников

**Оценка риска**

| Риск                 | Уровень       | Обоснование |
|----------------------|---------------|-------------|
| **Контекст выполнения** | Низкий       | Используется только в тестах |
| **Потенциальный ущерб** | Средний | Может повлиять на тестовые данные |


**Рекомендации**

1. Рефакторинг (рекомендуется): Заменить на явные методы тестирования.
2. Ограничение доступа: Добавить проверку окружения.

**Ссылки**

- [
CWE-95: Improper Neutralization of Directives in Dynamically Evaluated Code ('Eval Injection')](https://cwe.mitre.org/data/definitions/95.html)

---

#### ThreadSafety/ClassInstanceVariable: Проблема потокобезопасности

**Уязвимый код**

- [`employees_search_query.rb`](./projects/ruby/evally/db/seeds.rb)
```ruby
# 6:7
@params = params

# 57:45
['sections_join.section_group = ?', @params[:group]]

# 63:55
["(skills_join.skill->>'name')::varchar = ?", @params[:name]]

# 70:45
ActiveRecord::Base.sanitize_sql([sql, @params[:value]])

# 74:52
{ eq: '=', gteq: '>=', lteq: '<=' }.fetch(@params[:operator]&.to_sym, '=')

# 78:52
{ bool: 'boolean', rating: 'integer' }.fetch(@params[:group]&.to_sym, 'integer')
```

**Суть проблемы**

1. Классовые переменные экземпляра (`@params`) сохраняются между вызовами.

2. В многопоточной среде это может привести к:
    - Утечке параметров между запросами
    - Подмена параметров в запросе

**Оценка риска**

| Угроза               | Уровень  | Последствия |
|----------------------|----------|-------------|
| Утечка данных        | Высокий  | Параметры одного пользователя могут попасть в запрос другого |
| Непредсказуемые результаты | Средний | Возврат неожиданных данных из-за смешивания параметров |

**Рекомендации**
- Использовать `immutable` объекты в Ruby
- Использовать инстансы классов

**Ссылки**

- [CWE-362: Concurrent Execution using Shared Resource with Improper Synchronization ('Race Condition')](https://cwe.mitre.org/data/definitions/362.html)

---

#### Rails/OutputSafety: Небезопасное использование html_safe в email-шаблонах (XSS)

**Уязвимый код**

- [`invitation_instructions.html.erb:10:3`](./projects/ruby/evally/app/views/users/mailer/invitation_instructions.html.erb)
```ruby
<%= link_to 'Accept invitation', accept_invitations_url(invitation_token: @resource.invitation_token).html_safe, class: 'button' %>
```

- [`reset_password_instructions.html.erb`](./projects/ruby/evally/app/views/users/mailer/reset_password_instructions.html.erb)
```ruby
<%= link_to 'Change my password', reset_passwords_url(reset_password_token: @resource.reset_password_token).html_safe, class: 'button' %>
```

**Суть проблемы**

1. Если злоумышленник сможет подменить `invitation_token` или `reset_password_token` на строку с JavaScript-кодом (например, "><script>malicious()</script>), это приведёт к XSS.


**Оценка риска**

| Угроза               | Уровень  | Последствия                                                                 |
|----------------------|----------|-----------------------------------------------------------------------------|
| **Подмена ссылки**   | Низкий   | Если токен скомпрометирован, злоумышленник может изменить URL.             |

**Рекомендации**

1. Использовать явное экранирование
```erb
<%= link_to 'Accept invitation', ERB::Util.url_encode(accept_invitations_url(invitation_token: @resource.invitation_token)), class: 'button' %>
```

2. Убрать `.html_safe`
```erb
<%= link_to 'Accept invitation', accept_invitations_url(invitation_token: @resource.invitation_token), class: 'button' %>
```

3. Добавить Content Security Policy (CSP), чтобы ограничить выполнение скриптов

**Ссылки**

- [OWASP XSS](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)

---