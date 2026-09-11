source $HOME/.config/nvim/vim-plug/plugins.vim

"Keybindings
nnoremap <silent> <M-Down> :MoveLine(1)<CR>
nnoremap <silent> <M-Up> :MoveLine(-1)<CR>
vnoremap < <gv
vnoremap > >gv
"Settings
colorscheme aurora
set autochdir
set autoindent
set clipboard=unnamedplus
set mouse=a
set number
set shiftwidth=2
set smartindent
set termguicolors
syntax on
let g:loaded_python3_provider = 0
let g:loaded_node_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_ruby_provider = 0
" Start NERDTree
autocmd VimEnter * NERDTree
autocmd VimEnter * wincmd p
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr('$') > 1 | b# | endif
let g:plug_window = 'noautocmd vertical topleft new'
let NERDTreeShowHidden=1
let NERDTreeShowBookmarks=1

"Lua section
lua require("ibl").setup()
lua require("nvim-autopairs").setup()
lua require('move').setup({})
lua << EOF
require("lualine").setup{
  options = {
    disabled_filetypes = {
      statusline = {'nerdtree'}
    },
    ignore_focus = {'nerdtree'}
  },
  sections = {
    lualine_a = {
      {
	'filetype'
      },
      {
	'mode',
	icons_enabled = true
      }
    },
    lualine_b = {
      {
	'filename',
	file_status = true,
	path = 3
      },
      {
	'branch'
      }
    }
  }
}
EOF


