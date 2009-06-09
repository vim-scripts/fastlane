" Vim plugin for showing matching parens
" Maintainer:  Hongbo Dong <dong4138@126.com>
" Last Change: 6/9/2009

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" 底层基础函数                                         
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""

" 获取默认模块
function IwnGetDefaultModule()
  if (exists('g:iwn_default_module')!=0)
    return g:iwn_default_module
  else
    return 0
  endif 
endfunction

" 设置默认模块
function IwnSetDefaultModule(str)
  let g:iwn_default_module = a:str
endfunction

" 获取文本片断和缩写等等定义所在的目录
function IwnGetSnippetDir()
  return g:iwn_snippet_dir
endfunction

" 检测文件是否存在
function IwnCheckFile(filename)
  let pass1 = filereadable(a:filename)
  let pass2 = filewritable(a:filename)
  if (pass1 && pass2 ) 
    return 1
  else 
    return 0
  endif
endfunction

" 获取配置文件名
function IwnGetFilename(module)
  let filename = IwnGetSnippetDir() . a:module . "_snippets.vim"
  return filename
endfunction

" 获取范例文件名
function IwnGetFilenameSample() 
  let filename  = IwnGetSnippetDir() . "example_snippets.vim"
  return filename
endfunction










""""""""""""""""""""""""""""""""""""""""""
" 具体的操作命令
" 包括：
"     创建模块
"     删除模块
"     使用模块
"     添加模块包含     [ no start ]
"     删除模块包含     [ no start]
"     添加缩写 
"     删除缩写
"     添加文本片断
"     删除文本片断
""""""""""""""""""""""""""""""""""""""""""

"创建模块
function IwnCreateModule(str)
  let filename = IwnGetFilename(a:str)
  if (IwnCheckFile(filename)==1)
    echo a:str . '模块已经被创建'
    return
  endif

  let sample_file = IwnGetFilenameSample()
  let l = readfile(sample_file)
  if (writefile(l, filename)==0) 
    echo "模块: " . a:str . "创建成功"
  endif 
endfunction
command! -nargs=1 IwnCreateModule :call IwnCreateModule(<f-args>)

"删除模块
function! IwnRemoveModule(str) 
  let module = a:str
  let filename =  IwnGetFilename(module)
  if (IwnCheckFile(filename)==1)
    call delete(filename)
    echo "模块: " . module . "删除成功"
  else 
    echo "模块: " . module . "不存在"
  endif
endfunction
command! -nargs=1 IwnRemoveModule :call IwnRemoveModule(<f-args>)

" 使用模块
function! IwnUseModule(str)
  let module = a:str
  call IwnSetDefaultModule(module)
  let filename =  IwnGetFilename(module)
  if (IwnCheckFile(filename)==0)
    echo "模块: " . module . "不存在"
    return
  endif

  if (exists('g:iwn_include_modules')!=0)
    if (has_key(g:iwn_include_modules, module)==1)
      for n in g:iwn_include_modules[module]
        let tmpfilename = IwnGetFilename(n)
        execute "source " . tmpfilename
      endfor
    endif
  endif

  execute "source " . filename
  echo "模块: " . module . "使用开启"
endfunction
command! -nargs=1 IwnUseModule :call IwnUseModule(<f-args>)

function! IwnAutoUseModule()
  let module = IwnGetDefaultModule()
  if (module!=0) 
    echo module
    call IwnUseModule(module)
  endif
endfunction

autocmd BufEnter * call IwnAutoUseModule() 

"创建文本片断
function! IwnAddSnippet(name) range
  let module = IwnGetDefaultModule()
  let name   = a:name
  let filename = IwnGetFilename(module)

  let str = ''
  for n in range(a:firstline, a:lastline)
    let line = getline(n)
    if (n==a:lastline) 
      let str = str .line
    else 
      let str = str . line . "<CR>"
    endif
  endfor
  let str = escape( str, '"')
  
  let str = 'exec "Snippet ' . name . " ". str . '"'
  let str =  substitute(str, '<fun>', '".', "g")
  let str =  substitute(str, '</fun>', '."', "g")
  let str = substitute(str, '<sni>', '". st ."', 'g')
  let str = substitute(str, '</sni>', '". et ."', 'g')

  let content = readfile(filename)
  let reg = 'v:val !~ "Snippet '.name. '"'
  call filter(content, reg)
  call add(content, str)
  call writefile(content, filename)

  execute "source " . filename
  echo "添加文本片断成功"
endfunction
command! -range=% -nargs=1 IwnAddSnippet :<line1>,<line2>call IwnAddSnippet(<f-args>)

" 删除片断
function! IwnRemoveSnippet(name)
  let module = IwnGetDefaultModule()
  let name   = a:name
  let filename = IwnGetFilename(module)
  let content = readfile(filename)
  let reg = 'v:val !~ "Snippet '.name. '"'
  call filter(content, reg)
  call writefile(content, filename)
  echo "删除文本片断成功"

  execute "source " . filename
endfunction
command! -nargs=1 IwnRemoveSnippet :<line1>,<line2>call IwnRemoveSnippet(<f-args>)

" 添加缩写
function! IwnAddAbb(...) 
  "获取模块名和片段名
  let module = IwnGetDefaultModule()
  let name   = a:1
  let filename = IwnGetFilename(module)

  let value  = ''
  for n in (range(2,a:0))
    let value  = value . ' ' . a:{n}
  endfor
  let value = escape( value, '"')



  let value = "abb " . name . " " .value
  let content = readfile(filename)
  let reg = 'v:val !~ "abb '.name. '"'
  call filter(content, reg)
  call add(content, value)
  call writefile(content, filename)
  echo "添加缩写成功"

  execute "source " . filename
endfunction
command! -nargs=+ IwnAddAbb :<line1>,<line2>call IwnAddAbb(<f-args>)

" 删除缩写
function! IwnRemoveAbb (name)
  let module = IwnGetDefaultModule()
  let name   = a:name
  let filename = IwnGetFilename(module)

  let content = readfile(filename)
  let reg = 'v:val !~ "abb '.name. '"'
  call filter(content, reg)
  call writefile(content, filename)

  echo "删除缩写成功"
  execute "source " . filename
endfunction
command! -nargs=1 IwnRemoveAbb :<line1>,<line2>call IwnRemoveAbb(<f-args>)
