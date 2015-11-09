.model small
.stack 256
.data
.code
jmp start
;==============================
; animation
;==============================

startaddr dw 0a000h ;start of video memory
colour db 02 ; starting colour
black_colour db 0
orig_colour db 2 ; starting colour
base dw 50d	; it is default value pixels
triangle_sides dw 25d 	; half of the base
start_point_right dw 31998	;row 100 = 320x99 + 200 for column (right side of the display)
radius dw 24d	; it is default value pixels
orig_radius dw 24d
center dw 31840	;row 100 = 320x99 + 160 for column (center of the display)
x_squared dw 0
clean db 0
side db 0
bounce db 2
bounce_count db 0
eye_left dw 0
eye_right dw 0
mouth_var dw 0
mouth_var_1 dw 0
mouth_var_2 dw 0
mouth_var_3 dw 0
;=============================================
set_x_left:
mov di, center	;starting point
sub di, bx	;move to the next left pixel
mov cx, radius ;loop counter
mov ax, bx 	;x to ax
mul bx 	;x squared
mov x_squared, ax ; store squared x
mov ax, cx 	;radius
mul cx 	;radius squared
sub ax, x_squared
call sqr_root
ret
;=================================================
set_x_right:
mov di, center	;starting point
add di, bx	;move to the next right pixel
mov cx, radius ;loop counter
mov ax, bx 	;x to ax
mul bx 	;x squared
mov x_squared, ax ; store squared x
mov ax, cx 	;radius
mul cx 	;radius squared
sub ax, x_squared
call sqr_root
ret
;==================================================
sqr_root:
;num is alteady in ax
mov bx,1d ;Initialize BX to 1d
mov cx,1d ;Initialize CX to 1d
loop1: 	;start of counting square_root
sub ax,bx ;AX=AX-BX
inc cx ; Increment CX by 1
add bx,2 ;BX=BX+0002H
cmp ax,bx
jle store ; If zero flag is zero jump to store
jmp loop1 ; Jump to loop1
store:
ret 
;==================================
; Here are macros
;==================================
delay macro
mov cx, 00h
mov dx, 2100h
mov ah, 86h
int 15h
endm

;=================================================
;	START - set radius
;=================================================
start:

;=================================
; Graphic function
;=================================
mov ah,00 ;subfunction 0
mov al,19 ; mod 320x200
int 10h ;switch to 320x200 mode
;=============================
left_half: ; that part plots only the left up quarter of the circle
mov es, startaddr ;put segment address in es
mov di, center	;start draw from center point
mov cx, radius ;loop counter (pixels)
mov bx, 0 	;0d to bx
push bx 	;set default number of steps from the middle
xor dx, dx

plot_left_half:
mov al,colour ;cannot do mem-mem copy so use reg
mov es:[di],al ;set pixel to colour
add dx, 640	;make an oposit value of a point
add di, dx	; set di to the oposit value
mov es:[di],al ;set pixel to colour
sub di, dx	; set DI to the previous value
sub di, 320 ;mov up a pixel
loop plot_left_half
counter:
pop bx	; pop number of steps from middle
inc bx 	;add 1 to the x line from center
push bx ; store the value
cmp bx, radius	;chceck if radius is reached on the left side
je right_half	; if radius is reached jump to plot right up side
call set_x_left
jmp plot_left_half
;=================================================
;ploting right up quarter of a circle
right_half:
mov es, startaddr ;put segment address in es
mov di, center	;start draw from center point
mov cx, radius ;loop counter (pixels)
mov bx, 0 	;0d to bx
push bx 	;set default number of steps from the middle
xor dx, dx

plot_right_half:
mov al,colour ;cannot do mem-mem copy so use reg
mov es:[di],al ;set pixel to colour
add dx, 640
add di, dx
mov es:[di],al ;set pixel to colour
sub di, dx
sub di, 320 ;mov up a pixel
loop plot_right_half
counter2:
pop bx	; pop number of steps from middle
inc bx 	;add 1 to the x line from center
push bx ; store the value
cmp bx, radius	;chceck if radius is reached on the left side
je col_up	; if radius is reached jump to plot right up side
call set_x_right
jmp plot_right_half
;==================================================
col_up:
inc colour
inc colour
;===================================

check_right_side:
mov ax, es:[31999]
cmp ax, 0 ; chceck if right side is reached
je check_left_side
mov side, 0
inc bounce_count
;====================================
check_left_side:
mov ax, es:[31680]
cmp ax, 0 ; chceck if left side is reached
je black_circle
mov side, 1
inc bounce_count
;================================================

black_circle:
mov al, bounce
cmp al, bounce_count
je triangle
cmp clean,1
je set_center_left
mov clean,1
mov colour, 0
mov ax, orig_radius
mov radius, ax
delay
jmp left_half
;=============================

set_center_left:
cmp side, 1
je set_center_right
dec center
mov clean, 0
jmp left_half
set_center_right:
inc center
mov clean, 0
jmp left_half
;===================================

triangle:
;=================================
; Graphic function triangle
;=================================
mov ah,00 ;subfunction 0
mov al,19 ; mod 320x200
int 10h ;switch to 320x200 mode
;=============================

mov bounce_count,0

set_base: ; that part plots only the base
mov di, start_point_right	;start draw from right
mov cx, base
mov al,colour ;cannot do mem-mem copy so use reg

plot_base:
mov es:[di],al ;set pixel to colour
cmp al, black_colour
je continue_0
inc al
continue_0:
sub di, 1 ;mov left a pixel
loop plot_base
;=================================================

mov cx, triangle_sides ;loop counter (pixels)
cmp al, black_colour
je plot_left_side
inc al

plot_left_side:
sub di, 319
mov es:[di],al ;set pixel to colour
cmp al, black_colour
je continue_1
dec al
continue_1:
loop plot_left_side

mov cx, triangle_sides ;loop counter (pixels)

plot_right_side:
add di, 321
mov es:[di],al ;set pixel to colour
cmp al, black_colour
je continue_2
inc al
continue_2:
loop plot_right_side
;==================================================

col_renew:
mov dh, orig_colour
mov colour, dh
;===================================

check_right_side_2:
mov bx, es:[31999]
cmp bx, 0 ; chceck if right side is reached
je check_left_side_2
mov side, 0
inc bounce_count
;====================================
check_left_side_2:
mov bx, es:[31680]
cmp bx, 0 ; chceck if left side is reached
je black_obj
mov side, 1
inc bounce_count
;================================================

black_obj:
mov bl, bounce_count
cmp bl, bounce
je square
cmp clean,1
je set_obj_left
mov clean,1
mov colour, 0
delay
jmp set_base
;=============================

set_obj_left:
cmp side, 1
je set_obj_right
dec start_point_right
inc orig_colour
mov clean, 0
jmp set_base

set_obj_right:
inc start_point_right
inc orig_colour
mov clean, 0
jmp set_base
;===================================

square:
;=================================
; Graphic function square
;=================================
mov ah,00 ;subfunction 0
mov al,19 ; mod 320x200
int 10h ;switch to 320x200 mode
;=============================

mov bounce_count, -1

set_base_square: ; that part plots only the base
mov di, start_point_right	;start draw from right
mov cx, base
mov al,colour ;cannot do mem-mem copy so use reg

plot_base_square:
mov es:[di],al ;set pixel to colour
sub di, 1 ;mov left a pixel
loop plot_base_square
;=================================================

mov cx, base ;loop counter (pixels)

plot_left_square:
sub di, 320
mov es:[di],al ;set pixel to colour
loop plot_left_square

mov cx, base ;loop counter (pixels)

plot_up_square:
mov es:[di],al ;set pixel to colour
add di, 1 ;mov left a pixel
loop plot_up_square

mov cx, base ;loop counter (pixels)

plot_right_square:
add di, 320
mov es:[di],al ;set pixel to colour
loop plot_right_square

;==================================================

col_up_square:
mov dh, orig_colour
mov colour, dh
;===================================

check_right_square:
mov bx, es:[31999]
cmp bx, 0 ; chceck if right side is reached
je check_left_square
mov side, 0
inc bounce_count
;====================================
check_left_square:
mov bx, es:[31680]
cmp bx, 0 ; chceck if left side is reached
je black_square
mov side, 1
inc bounce_count
;================================================

black_square:
mov bl, bounce
cmp bl, bounce_count
je star
cmp clean,1
je set_square_left
mov clean,1
mov colour, 0
delay
jmp set_base_square
;=============================

set_square_left:
cmp side, 1
je set_square_right
dec start_point_right
inc orig_colour
mov clean, 0
jmp set_base_square

set_square_right:
inc start_point_right
inc orig_colour
mov clean, 0
jmp set_base_square
;===================================

star:
;=================================
; Graphic function star
;=================================
mov ah,00 ;subfunction 0
mov al,19 ; mod 320x200
int 10h ;switch to 320x200 mode
;=============================

mov bounce_count, -1

set_base_star: ; that part plots only the base
mov di, start_point_right	;start draw from right
mov cx, base
mov al,colour ;cannot do mem-mem copy so use reg

plot_base_star:
mov es:[di],al ;set pixel to colour
sub di, 1 ;mov left a pixel
loop plot_base_star
;=================================================

mov cx, triangle_sides ;loop counter (pixels)

plot_left_side_star:
sub di, 319
mov es:[di],al ;set pixel to colour
loop plot_left_side_star

mov cx, triangle_sides ;loop counter (pixels)

plot_right_side_star:
add di, 321
mov es:[di],al ;set pixel to colour
loop plot_right_side_star
;==================================================
;second triangle
;==================================================
set_base_star_2: ; that part plots only the base
sub di, 4800	;start draw from right
mov cx, base
mov al,colour ;cannot do mem-mem copy so use reg

plot_base_star_2:
mov es:[di],al ;set pixel to colour
sub di, 1 ;mov left a pixel
loop plot_base_star_2
;=================================================

mov cx, triangle_sides ;loop counter (pixels)

plot_left_side_star_2:
add di, 321
mov es:[di],al ;set pixel to colour
loop plot_left_side_star_2

mov cx, triangle_sides ;loop counter (pixels)

plot_right_side_star_2:
sub di, 319
mov es:[di],al ;set pixel to colour
loop plot_right_side_star_2

;=================================================

col_renew_star:
mov dh, orig_colour
mov colour, dh
;===================================

check_right_side_star:
mov bx, es:[31999]
cmp bx, 0 ; chceck if right side is reached
je check_left_side_star
mov side, 0
inc bounce_count
;====================================
check_left_side_star:
mov bx, es:[31680]
cmp bx, 0 ; chceck if left side is reached
je black_star
mov side, 1
inc bounce_count
;================================================

black_star:
mov bl, bounce_count
cmp bl, bounce
je smile
cmp clean,1
je set_star_left
mov clean,1
mov colour, 0
delay
jmp set_base_star
;=============================
set_star_left:
cmp side, 1
je set_star_right
dec start_point_right
mov clean, 0
jmp set_base_star

set_star_right:
inc start_point_right
mov clean, 0
jmp set_base_star
;===================================
; Here are functions
;==============================
set_x_left_smile:
mov di, center	;starting point
sub di, bx	;move to the next left pixel
mov cx, radius ;loop counter
mov ax, bx 	;x to ax
mul bx 	;x squared
mov x_squared, ax ; store squared x
mov ax, cx 	;radius
mul cx 	;radius squared
sub ax, x_squared
call sqr_root_smile
ret
;=================================================
smile:
mov radius, 85
mov center, 31840
mov colour, 14
jmp smile2

set_x_right_smile:
mov di, center	;starting point
add di, bx	;move to the next right pixel
mov cx, radius ;loop counter
mov ax, bx 	;x to ax
mul bx 	;x squared
mov x_squared, ax ; store squared x
mov ax, cx 	;radius
mul cx 	;radius squared
sub ax, x_squared
call sqr_root_smile
ret
;==================================================
sqr_root_smile:
;num is alteady in ax
mov bx,1d ;Initialize BX to 1d
mov cx,1d ;Initialize CX to 1d
loop1_smile: 	;start of counting square_root
sub ax,bx ;AX=AX-BX
inc cx ; Increment CX by 1
add bx,2 ;BX=BX+0002H
cmp ax,bx
jle store_smile ; If zero flag is zero jump to store
jmp loop1_smile ; Jump to loop1
store_smile:
ret 

smile2:
;=================================
; Graphic function smile
;=================================
mov ah,00 ;subfunction 0
mov al,19 ; mod 320x200
int 10h ;switch to 320x200 mode
;=============================
left_up_smile: ; that part plots only the left up quarter of the circle
mov es, startaddr ;put segment address in es
mov di, center	;start draw from center point
mov cx, radius ;loop counter (pixels)
mov bx, 0 	;0d to bx
push bx 	;set default number of steps from the middle
plot_left_up_smile:
mov al,colour ;cannot do mem-mem copy so use reg
mov es:[di],al ;set pixel to colour
sub di, 320 ;mov up a pixel
loop plot_left_up_smile
counter_smile:
pop bx	; pop number of steps from middle
inc bx 	;add 1 to the x line from center
push bx ; store the value
cmp bx, radius	;chceck if radius is reached on the left side
je right_up_smile	; if radius is reached jump to plot right up side
call set_x_left_smile
jmp plot_left_up_smile
;=================================================
right_up_smile:
mov di, center	;start draw from center point
mov cx, radius ;loop counter (pixels)
mov bx, 0 	;0d to bx
push bx 	;set default number of steps from the middle
plot_right_up_smile:
mov al,colour ;cannot do mem-mem copy so use reg
mov es:[di],al ;set pixel to colour
sub di, 320 ;mov up a pixel
loop plot_right_up_smile
counter2_smile:
pop bx	; pop number of steps from middle
inc bx 	;add 1 to the x line from center
push bx ; store the value
cmp bx, radius	;chceck if radius is reached on the left side
je left_down_smile	; if radius is reached jump to plot right up side
call set_x_right_smile
jmp plot_right_up_smile
;==================================================
left_down_smile:
mov di, center	;start draw from center point
mov cx, radius ;loop counter (pixels)
mov bx, 0 	;0d to bx
push bx 	;set default number of steps from the middle
plot_left_down_smile:
mov al,colour ;cannot do mem-mem copy so use reg
mov es:[di],al ;set pixel to colour
add di, 320 ;mov down a pixel
loop plot_left_down_smile
counter3_smile:
pop bx	; pop number of steps from middle
inc bx 	;add 1 to the x line from center
push bx ; store the value
cmp bx, radius	;chceck if radius is reached on the left side
je right_down_smile	; if radius is reached jump to plot right up side
call set_x_left_smile
jmp plot_left_down_smile
;==================================================
right_down_smile:
mov di, center	;start draw from center point
mov cx, radius ;loop counter (pixels)
mov bx, 0 	;0d to bx
push bx 	;set default number of steps from the middle
plot_right_down_smile:
mov al,colour ;cannot do mem-mem copy so use reg
mov es:[di],al ;set pixel to colour
add di, 320 ;mov down a pixel
loop plot_right_down_smile
counter4_smile:
pop bx	; pop number of steps from middle
inc bx 	;add 1 to the x line from center
push bx ; store the value
cmp bx, radius	;chceck if radius is reached on the left side
je eye_1	
call set_x_right_smile
jmp plot_right_down_smile
;=============================
eye_1:
cmp eye_left, 1d
je eye_2
mov radius, 12d
mov cx, radius ;loop counter (pixels)
mov colour, 0
mov bx, 0 	;0d to bx
push bx
mov center, 19330d ; row 60 and column 130
mov di, center
mov eye_left, 1
jmp plot_left_up_smile
;===============================
eye_2:
cmp eye_right, 1d
je mouth
mov radius, 12d
mov cx, radius ;loop counter (pixels)
mov colour, 0
mov bx, 0 	;0d to bx
push bx
mov center, 19390d	; row 60 and column 190
mov di, center
mov eye_right, 1
jmp plot_left_up_smile
;===============================
mouth:
cmp mouth_var_1, 7d
je mouth_2
mov radius, 6d
mov cx, radius ;loop counter (pixels)
mov colour, 0
mov bx, 0 	;0d to bx
push bx
cmp mouth_var_1, 0
jne next_state
mov center, 38510d	; row 120 and column 110
mov di, center
next_state:
add center, 643
mov di, center
add mouth_var_1, 1
jmp plot_left_up_smile
;==============================
mouth_2:
cmp mouth_var_2, 7d
je mouth_3
mov radius, 6d
mov cx, radius ;loop counter (pixels)
mov colour, 0
mov bx, 0 	;0d to bx
push bx
cmp mouth_var_2, 0
jne next_state_2
mov center, 38610d	; row 120 and column 210
mov di, center
next_state_2:
add center, 637
mov di, center
add mouth_var_2, 1
jmp plot_left_up_smile
;==============================
mouth_3:
cmp mouth_var_3, 5d
je keypress
mov radius, 6d
mov cx, radius ;loop counter (pixels)
mov colour, 0
mov bx, 0 	;0d to bx
push bx
cmp mouth_var_3, 0
jne next_state_3
mov center, 43069d	; row 120 and column 210
mov di, center
next_state_3:
sub center, 11
mov di, center
add mouth_var_3, 1
jmp plot_left_up_smile
;=============================

keypress:
mov ah,00
int 16h ;await keypress
exit:
mov ah,00
mov al,03
int 10h
mov ah,4ch
mov al,00 ;terminate program
int 21h
end start