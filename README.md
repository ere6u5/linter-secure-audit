# Отчет по Secure Coding

Провёл анализ open-source проектов на предмет уязвимостей с использованием статических анализаторов кода.

## Инструменты

| Язык       | Инструмент               | Плагины безопасности               |
|------------|--------------------------|-------------------------------------|
| **Python** | Flake8                   | bandit, bugbear, logging-format     |

### Установка

- **Python**: Flake8 с дополнительными плагинами
```bash
pip install flake8-bandit flake8-bugbear flake8-logging-format flake8-tidy-imports flake8-pie flake8-docstrings
```

Файл может иметь названия `setup.cfg`, `.flake8` или `tox.ini`. Примерная структура файла конфигурации выглядит так:
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

# Sec-rules
select =
...
```


## Анализируемые проекты

### Python/Flake8

Ссылка на репозиторий [webob](https://github.com/Pylons/webob).
```bash
git submodule add https://github.com/Pylons/webob ./projects/python/webob
```
  

(содержание аудита python)

## JavaScript/ESlint

(содержание аудита javascript)

## Ruby/RuboCop

(содержание аудита ruby)
