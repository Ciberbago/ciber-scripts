" Source the file with the plugins in it
source $HOME/.config/nvim/vim-plug/plugins.vim

"Start NERDTree
autocmd VimEnter * NERDTree
"Go to previous (last accessed) window.
autocmd VimEnter * wincmd p
"Close vim if nerdtree is the last window
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
"If more than one window and previous buffer was NERDTree, go back to it.
autocmd BufEnter * if bufname('#') =~# "^NERD_tree_" && winnr('$') > 1 | b# | endif

let g:plug_window = 'noautocmd vertical topleft new'
let NERDTreeShowHidden=1
let NERDTreeShowBookmarks=1

syntax on
colorscheme dracula
set mouse=a
set number
"Indent lines
lua require("ibl").setup()
