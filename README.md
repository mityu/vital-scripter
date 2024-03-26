# vital-Scripter

[![Powered by vital.vim](https://img.shields.io/badge/powered%20by-vital.vim-80273f.svg)](https://github.com/vim-jp/vital.vim)
[![](https://github.com/mityu/vital-scripter/actions/workflows/ci.yml/badge.svg)](https://github.com/mityu/vital-scripter/actions/workflows/ci.yml)

A vital.vim module that make it easy to feed key types and call functions between the key types.

## Usage

```vim
let s:Scripter = vital#vital#import('Vim.Scripter')

call s:Scripter.new()
  \.call({-> assert_equal('n', mode())})
  \.feedkeys('ifoobar')
  \.call({-> assert_equal('i', mode())})
  \.call({-> assert_equal('foobar', getline('.'))})
  \.feedkeys("\<ESC>")
  \.call({-> assert_equal('n', mode())})
  \.run()

inoremap <Plug>(test-mapping) (rhs-test-mapping)
call s:Scripter.new()
  \.feedkeys('i')
  \.feedkeys_remap("\<Plug>(test-mapping)")
  \.call({-> assert_equal('(rhs-test-mapping)', getline('.'))})
  \.set_auto_replace_termcodes(1)
  \.feedkeys_remap('<Plug>(test-mapping)')
  \.call({-> assert_equal('(rhs-test-mapping)(rhs-test-mapping)', getline('.'))})
  \.feedkeys('<ESC>')
  \.run()
```
