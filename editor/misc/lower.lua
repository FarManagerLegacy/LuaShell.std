sh.block_process_lines(function (sel)
  return sel:lower()
end, {ifnosel="curline"})
