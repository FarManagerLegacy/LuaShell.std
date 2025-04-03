https://forum.farmanager.com/viewtopic.php?p=175511#p175511

Следующий скрипт аналогичен прочим макросам, выбирающим пару файлов для сравнения
через VisualCompare ([©ccaid], [©Shmuel], [©SimSU], [@AleXH], [©LanKing])
и через WinMerge ([©gene.pavlovsky], [©DV]).

Разница в том что:
* это не макрос, а скрипт, запускаемый из командной строки
* в качестве параметра можно указать утилиту для сравнения. Например `diff meld` или `diff winmerge`

Алгоритм выбора пары:
- либо выделенная пара файлов на активной панели
- либо пара файлов с противоположных панелей
  + на активной: выделенный (если 1) или текущий
  + на пассивной: выделенный(если 1) или одноимённый

Поддерживаются и плагиновые панели с реальными файлами (TmpPanel, Branch, ...).
(На пассивной плагиновой панели поиск одноимённого файла не предусмотрен, работа только с выделенным).

[©ccaid]: https://forum.farmanager.com/viewtopic.php?f=15&t=10560
[©Shmuel]: https://github.com/shmuz/LuaFAR-2M/blob/main/Macros/scripts/Shell/visual_compare.lua
[©SimSU]: https://forum.farmanager.com/viewtopic.php?t=7075
[@AleXH]: https://forum.farmanager.com/viewtopic.php?t=12089
[©LanKing]: https://forum.farmanager.com/viewtopic.php?t=9221

[©gene.pavlovsky]: https://forum.farmanager.com/viewtopic.php?f=35&t=9769
[©DV]: https://forum.farmanager.com/viewtopic.php?f=15&t=10861
