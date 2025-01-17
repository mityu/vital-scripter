let s:latest_id = -1
let s:objects = {}
let s:scripter = {
  \ '_object_id': -1,
  \ '_script': [],
  \ '_fn_stack': [],
  \ '_temporal_maps': [],
  \ '_auto_replace_termcodes': 0,
  \}

function s:_get_sid() abort
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\ze_get_sid')
endfunction

function s:_get_new_id() abort
  let s:latest_id += 1
  return s:latest_id
endfunction

function s:_internal_error_message(msg) abort
  return 'themis: report: internal error: ' . a:msg
endfunction

function s:_replace_termcodes(from) abort
  return substitute(a:from, '<[^<>]\+>',
   \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

function s:_call_top_of_fn_stack(object_id) abort
  if !has_key(s:objects, a:object_id)
    throw s:_internal_error_message('cannot find scripter object by object-id:' . a:object_id)
  endif
  let obj = s:objects[a:object_id]
  if empty(obj._fn_stack)
    throw s:_internal_error_message('function stack is empty.')
  endif

  call call(remove(obj._fn_stack, 0), [])
  return ''
endfunction

if has('patch-8.2.1978') || has('nvim-0.3.0')
  function s:scripter.call(Fn) abort
    call add(self._fn_stack, a:Fn)
    let script =
      \ printf("\<Cmd>call %s_call_top_of_fn_stack(%s)\<CR>", s:_get_sid(), self._object_id)
    call add(self._script, [script, 0])
    return self
  endfunction
else
  function s:scripter.call(Fn) abort
    call add(self._fn_stack, a:Fn)
    let lhs = printf('%s(_vital_scripter_map-%d)', s:_get_sid(), s:_get_new_id())
    let mapcmd = printf('<expr> %s <SID>_call_top_of_fn_stack(%s)', lhs, self._object_id)
    execute 'noremap' mapcmd
    execute 'noremap!' mapcmd
    execute 'lnoremap' mapcmd
    execute 'tnoremap' mapcmd
    call add(self._script, ["\<Ignore>" . s:_replace_termcodes(lhs), 1])
    call add(self._temporal_maps, lhs)
    return self
  endfunction
endif

function s:scripter.feedkeys(keys) abort
  let keys = a:keys
  if self._auto_replace_termcodes
    let keys = s:_replace_termcodes(keys)
  endif
  call add(self._script, [keys, 0])
  return self
endfunction

function s:scripter.feedkeys_remap(keys) abort
  let keys = a:keys
  if self._auto_replace_termcodes
    let keys = s:_replace_termcodes(keys)
  endif
  call add(self._script, [keys, 1])
  return self
endfunction

function s:scripter.run() abort
  for [keys, remap] in self._script
    if remap
      call feedkeys(keys, 'm')
    else
      call feedkeys(keys, 'n')
    endif
  endfor
  call feedkeys('', 'x')

  for lhs in self._temporal_maps
    execute 'unmap' lhs
    execute 'unmap!' lhs
    execute 'lunmap' lhs
    execute 'tunmap' lhs
  endfor

  if !has_key(s:objects, self._object_id)
    throw s:_internal_error_message('cannot find self by object-id: ' . self._object_id)
  endif
  call remove(s:objects, self._object_id)
  if !empty(self._fn_stack)
    throw s:_internal_error_message(
      \ '_fn_stack still have entries: ' . string(self._fn_stack))
  endif
  return self
endfunction

function s:scripter.set_auto_replace_termcodes(value) abort
  let self._auto_replace_termcodes = a:value
  return self
endfunction

function s:new() abort
  let obj = deepcopy(s:scripter)
  let obj._object_id = s:_get_new_id()
  let s:objects[obj._object_id] = obj
  return obj
endfunction
