;Script personalizado de autohotkey pensado para un teclado Motospeed CK61
;! es Alt, + es Shift y ^ es Ctrl
; Estas son las eñes

!n:: Send {Asc 164}
!+n:: Send {Asc 165}

;Insertar
!k:: Send {NumpadIns}

;Tilde
!\:: Send {ASC 126}

;Grave
!+\:: Send {`}

; Doy la funcion de las F a los fila de numeros
!1:: Send  {f1}
!3:: Send  !{f3}
!0:: Send  {f10}
!+3:: Send  +{f3}
!+6:: Send  !{f6}

!5:: Send  {f5}
!6:: Send  {f6}
!7:: Send  {f7}
!8:: Send  {f8}
!9:: Send  {f9}
!2:: Send  {f12}

; Debug screen y recarga de chunks
!h:: Send {F3 Down}h{F3 Up}
!a:: Send {F3 Down}a{F3 Up}
!t:: Send {F3 Down}t{F3 Up}
!g:: Send {F3 Down}g{F3 Up}

;Suprimir con backspace
^Backspace:: Send {Delete}

;Auto right clicker con Alt+R
SetBatchLines, -1
#MaxThreadsPerHotkey 2
!r::
Toggle := !Toggle
Loop,
{
    If not Toggle
        break
   Click, right
   Sleep, 5
}
return

;Auto left clicker con Alt+L
SetBatchLines, -1
#MaxThreadsPerHotkey 2
!l::
Toggle := !Toggle
Loop,
{
    If not Toggle
        break
   Click, left
   Sleep, 5
}
return

SpamLShift:=0
Return

;Esto es para abrir la terminal de windows
^!t::
run *runas wt.exe
