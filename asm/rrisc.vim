" Vim syntax file
" Language:	RRISC assembler
" By: Rene Schallner <renemann@gmail.com>
" Creation date: 01-Jan-2021
" Version 0.01

" Remove any old syntax stuff hanging about
syn clear
syn case ignore
"
" registers
syn keyword asmR2Reg a b c d e f A B C D E F G

" opcodes:

syn keyword asmR2Op  lda ldb ldc ldd lde ldf ldg sta stb stc std ste stf stg in out jmp jmpp

syn keyword asmR2Branch EQ GT SM

" Atari 800XL 'Sally' undocumented opcodes
" mnemonics taken from Trevin Beattie's 'Atari Technical Information' page
" at "http://www.xmission.com/~trevin/atari/atari.shtml"

syn match asmLabel		"^:[@a-z_][a-z0-9_]*"
syn match asmComment		";.*"hs=s+1 contains=asmTodo
syn keyword asmTodo	contained todo fixme xxx warning danger note notice bug
syn region asmString		start=+"+ skip=+\\"+ end=+"+
syn keyword asmSettings	    org include
syn keyword asmMacros   MACRO macro MACRODEF ENDMACRO 
syn keyword asmConst const

syn match decNumber	"\<\d\+\>"
syn match hexNumber	"\$\x\+\>" " 'bug', but adding \< doesn't behave!
syn match binNumber	"%[01]\+\>" 
syn match asmImmediate	"#\$\x\+\>"
syn match asmImmediate	"#\d\+\>"
syn match asmImmediate	"<\$\x\+\>"
syn match asmImmediate	"<\d\+\>"
syn match asmImmediate	">\$\x\+\>"
syn match asmImmediate	">\d\+\>"
syn match asmImmediate	"#<\$\x\+\>"
syn match asmImmediate	"#<\d\+\>"
syn match asmImmediate	"#>\$\x\+\>"
syn match asmImmediate	"#>\d\+\>"

"
"syn case match
if !exists("did_asmR2_syntax_inits")
  let did_rgb_asm_syntax_inits = 1

  " The default methods for highlighting.  Can be overridden later
  hi link asmLabel	Label
  hi link asmString	String
  hi link asmComment	Comment
  hi link asmSettings	Statement
 hi link asmR2Op Statement
 hi link asmMacros Special
 hi link asmR2Reg Identifier
 hi link asmR2Branch Conditional
 hi link asmTodo Debug

  hi link asmImmediate Special

  hi link hexNumber	Number
  hi link binNumber	Number
  hi link decNumber	Number

" My default color overrides:
hi asmSpecialComment ctermfg=red
hi asmIdentifier ctermfg=lightcyan
hi asmType ctermbg=black ctermfg=brown
hi link asmMacros String
hi asmConst ctermfg=08
hi Number ctermfg=117
hi asmR2Reg ctermfg=73
hi asmR2Op ctermfg=73
hi asmLabel ctermfg=187
hi asmComment ctermfg=59

endif

let b:current_syntax = "rgbasm"


