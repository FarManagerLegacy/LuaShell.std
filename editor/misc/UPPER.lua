sh.block_process_lines(function (sel)
  return sel:upper()
end, {ifnosel="curline"})
