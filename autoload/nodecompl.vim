" Depends on vim-json: https://github.com/vimlab/vim-json

let s:nodefile = exists('g:nodecompl_node_doc_file') && filereadable(g:nodecompl_node_doc_file)
let s:nodefile = s:nodefile ? s:nodefile : ''

let s:data = {}

function! nodecompl#file()
  if len(keys(s:data)) != 0
    return s:data
  endif

  let file = filereadable(s:nodefile) ?
  \   join(readfile(s:nodefile), '') :
  \   nodecompl#get('https://nodejs.org/api/all.json')

  let s:data = JSON#parse(file)
  return s:data
endfunction

function! nodecompl#data()
  let docs = nodecompl#file()

  let variables = docs.globals
  let variables += docs.vars
  let variables += docs.classes

  let modules = docs.modules
  let moduleNames = map(copy(modules), 'v:val.name')
  let variables += copy(modules)
  let variableNames = map(copy(variables), 's:buildItem(v:val)')

  let result = {}
  let result.vars = variableNames
  let result.modules = moduleNames

  for name in moduleNames
    let module = {}
    for m in modules
      if m.name == name
        let module = m
      endif
    endfor

    let methods = []

    if !has_key(module, 'methods')
      if has_key(module, 'classes')
        let classes = module.classes

        for class in classes
          if has_key(class, 'methods')
            let methods += class.methods
          endif
        endfor
      endif
    else
      let methods += module.methods
    endif

    let result[name] = map(methods, 's:buildItem(v:val)')
  endfor

  return result
endfunction

function! s:html2markdown(html)
  let html = substitute(a:html, '<p>', '', 'g')
  let html = substitute(html, '</p>', '', 'g')

  let html = substitute(html, '<code>\([^<]*\)</code>', '`\1`', 'g')
  let html = substitute(html, '<pre><code class="\w*">\([^<]*\)</code></pre>', '```\n\1\n```', 'g')
  return html
endfunction

function! s:buildItem(val)
  let item = {}
  let item.word = substitute(a:val.name, '\\_\\_', '', '')
  let item.menu = substitute(a:val.textRaw, '\\_\\_', '', '')
  if has_key(a:val, 'desc')
    let item.info = s:html2markdown(a:val.desc)
  endif
  return item
endfunction

function! nodecompl#get(url)
  return system('curl -s ' . a:url)
endfunction

function! nodecompl#compl(type, base, line)
  let dotstart = matchstr(a:base, '^\.') != ''
  let data = nodecompl#data()
  let names = data.modules
  let whole = a:line . a:base

  let completions = []

  for name in names
    let matchd = matchstr(whole, name . '.')
    if matchd != ''
      let completions = get(data, name, 1)
    endif
  endfor

  if !dotstart
    let completions = get(data, a:type, 1)
  endif

  if len(completions) == 0
    let completions = s:buildVariableCompletion(a:base, a:line)
  endif

  if dotstart
    let completions = map(completions, 's:prefix(v:val, ".")')
  endif

  let completions = filter(completions, 's:filter(v:val, "' . a:base . '")')

  return completions
endfunction

function! s:buildVariableCompletion(base, line)
  let completions = []
  let buffer = getline(1, '$')
  let base = substitute(a:base, '\.', '\\.', 'g')

  let identifier = matchstr(a:line, '\w*' . base)
  let identifier = substitute(identifier, base, '', 'g')

  if identifier == ""
    return []
  endif

  let definition = matchstr(buffer, identifier)
  if definition != ''
    if matchstr(definition, 'require(') != ""
      let module = matchlist(definition, 'require(\(.*\))')[1]
      let module = substitute(module, '"', "'", 'g')
      let cmd = 'node -pe "Object.keys(require(' . module . ')).join(\"\\n\")"'
      let output = system(cmd)
      let completions = split(output, '\n')
    endif
  endif

  echo completions

  return completions
endfunction

function! nodecompl#complete(findstart, base)
  let line = getline('.')

  if a:findstart
    let existing = matchstr(line[0:col('.')-1], '\.*\w*$')
    return col('.')-1-strlen(existing)
  endif

  return nodecompl#compl('vars', a:base, line)
endfunction

function! s:filter(item, base)
  if type(a:item) == 1
    return match(a:item, '^' . a:base) != -1
  endif

  return match(a:item.word, '^' . a:base) != -1
endfunction

function! s:prefix(item, str)
  let item = a:item

  if type(item) == 1
    let item = a:str . item
  else
    let item.word = a:str . item.word
  endif

  return item
endfunction
