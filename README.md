# Интерактивные интерфейсы в Bash-скриптах

Этот мини-проект по созданию скрипта с интерфейсом коммандной строки написан для [Rebrain](https://rebrainme.com).

В скриптах показана реализация самых частых интерактивных элементов и продвинутого парсера аргументов.

## Скрипты

### site.sh

Рабочий скрипт, который реализует функционал добавления сайтов на сервер (создаёт виртуальный хост и папку для сайта).

```
Create site dir and nginx virtual host.

Usage: site [-v | --version] [-h | --help] [--disabled] [--no-dir]
            [-e | --edit] [-y]  [-t | --template=<template>] <domain>

Options:
    --disabled                  don't enable virtual host.
    --no-dir                    don't create site directory.
    -e, --edit                  open vhost in default editor.
    -t, --template=<template>   use <template> for site.
    -y, --yes                   assume 'yes' in all dialogs.
    -h, --help                  print this message and exit.
    -v, --version               print version and exit.
```

### site-completion.sh

Скрипт автодополнения команд для скрипта site.sh.

### make\_dist.sh

Скрипт для быстрой сборки DEB-пакета. Используется минимально-возможный набор файлов для сборки пакета. Если хотите собирать пакеты "по-взрослому", то настоятельно рекомендуем к изучению [Руководство начинающего разработчика Debian](https://www.debian.org/doc/manuals/maint-guide/start.ru.html).

### bonus.sh

Скрипт, показывающий некоторые другие аспекты парсера аргументов и возможности Bash, которые не были раскрыты в скрипте site.sh.
