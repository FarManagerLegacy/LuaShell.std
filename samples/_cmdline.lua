if _cmdline=="" then
  print "Скрипт запущен без аргументов, выводим подсказку"
  return
elseif _cmdline then
  print("Командная строка:", _cmdline)
  print("Аргументы:", ...)
else
  -- скрипт вызван другим скриптом, экспортируем функцию
  return some_function
end
