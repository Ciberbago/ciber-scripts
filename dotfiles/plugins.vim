call plug#begin('~/.config/nvim/autoload/plugged')
  Plug 'preservim/nerdtree', {'on': 'NERDTreeToggle'}
  Plug 'Xuyuanp/nerdtree-git-plugin'
  Plug 'ryanoasis/vim-devicons'
  Plug 'zefei/vim-wintabs'
  Plug 'zefei/vim-wintabs-powerline'
  Plug 'dracula/vim', { 'as': 'dracula' }
  Plug 'lukas-reineke/indent-blankline.nvim'
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'windwp/nvim-autopairs'
call plug#end()
