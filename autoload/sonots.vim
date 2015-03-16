let s:data_dir = expand('<sfile>:h:h') . '/data'

function! s:gui2cui(rgb)
  if a:rgb == 'NONE'
    return 'NONE'
  endif
  let rgb = map(matchlist(a:rgb, '#\(..\)\(..\)\(..\)')[1:3], '0 + ("0x".v:val)')
  let rgb = [rgb[0] > 127 ? 4 : 0, rgb[1] > 127 ? 2 : 0, rgb[2] > 127 ? 1 : 0]
  return rgb[0] + rgb[1] + rgb[2]
endfunction

function! sonots#render()
  let rgbfile = $VIMRUNTIME . '/rgb.txt'
  let coltable = {}
  if filereadable(rgbfile)
    for _ in map(filter(readfile(rgbfile), 'v:val !~ "^!"'), 'matchlist(v:val, "^\\s*\\(\\d\\+\\)\\s\\+\\(\\d\\+\\)\\s\\+\\(\\d\\+\\)\\s\\+\\(.*\\)")[1:4]')
      let coltable[tolower(_[3])] = printf("#%02x%02x%02x", _[0], _[1], _[2])
    endfor
  endif
  let coltable['None'] = 'NONE'

  let lines = readfile(s:data_dir . '/sonots.xpm')
  let pos1 = index(lines, '/* columns rows colors chars-per-pixel */')
  let pos2 = index(lines, '/* pixels */')
  let colors = []
  for line in lines[pos1+2:pos2-1]
    let s = split(line[1:-3], ' c ')
    if s[1] !~ '^#'
      let s[1] = coltable[s[1]]
    endif
    if s[1] == 'NONE'
      call add(colors, printf('syntax match sonotsNONE /%s/', join(map(split(s[0], '\zs'), 'printf("[\\x%02x]",char2nr(v:val))'), '')))
      highlight sonotsNONE guifg=bg guibg=NONE ctermfg=NONE ctermbg=NONE
    else
      call add(colors, printf('syntax match sonots%s /%s/ contains=sonotsNONE', s[1][1:], join(map(split(s[0], '\zs'), 'printf("[\\x%02x]",char2nr(v:val))'), '')))
      exe printf("highlight sonots%s guifg='%s' guibg='%s' ctermfg=%d ctermbg=%d", s[1][1:], s[1], s[1], s:gui2cui(s[1]), s:gui2cui(s[1]))
    endif
  endfor
  let image = {
  \ "colors" : colors,
  \ "data" : map(lines[pos2+1 :], 'matchstr(v:val, ''^"\zs.\+\ze",\?$'')')
  \}

  silent edit `='==SONOTS=='`
  silent normal! gg0
  silent only!
  setlocal buftype=nowrite
  setlocal noswapfile
  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal nonumber
  setlocal nolist
  setlocal nowrap
  setlocal nocursorline
  setlocal nocursorcolumn
  silent! syntax clear
  for c in image.colors
    exe c
  endfor
  call setline(1, image.data)
  redraw
endfunction

" vim:set et:
