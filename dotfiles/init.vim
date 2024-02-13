source $HOME/.config/nvim/vim-plug/plugins.vim

" Start NERDTree
autocmd VimEnter * NERDTree
" Go to previous (last accessed) window.
autocmd VimEnter * wincmd p
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" If more than one window and previous buffer was NERDTree, go back to it.
autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr('$') > 1 | b# | endif
let g:plug_window = 'noautocmd vertical topleft new'
let NERDTreeShowHidden=1
let NERDTreeShowBookmarks=1
syntax on

colorscheme dracula
set mouse=a
set number

lua require("ibl").setup()
lua require("lualine").setup()
lua require("nvim-autopairs").setup()
