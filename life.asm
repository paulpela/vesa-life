USE64

ORG 0x100000

life:
    call init_video_mem_addr
    call gen_rnd
    call l_clear_buffers
    call l_init_random
    call l_redraw

inf:
    call l_play
    call l_redraw
    jmp inf

init_video_mem_addr:
    xor rax, rax
    mov eax, dword [0x5c00+40]
    mov qword [video_mem], rax
    ret


l_play:
    mov rsi, qword [buffer_current]
    mov rdi, qword [buffer_next]
    mov rcx, qword [screen_size]
.loop:
    call l_parse_cell
    add rsi, 3
    add rdi, 3
    loop .loop

    ret

l_parse_cell:
    call l_count_neighbors
    call l_apply_rules
    ret

l_apply_rules:
    mov al, byte [rsi]
    cmp al, 0x00
    je .empty_cell
    cmp r13, 2
    jl .die
    cmp r13, 3
    jg .die
    jmp .live
.empty_cell:
    cmp r13, 3
    je .live
.die:
    mov byte [rdi], 0x00
    mov word [rdi+1], 0x0000
    ret
.live: 
    mov bx, 0x4040
    mov al, byte [rsi]
    dec al
    cmp al, 0x40
    cmovb ax, bx
    mov byte [rdi], al
    mov ax, word [rsi+1]
    dec ah
    dec al
    cmp al, 0x40
    cmovb ax, bx
    mov word [rdi+1], ax
    ret


l_count_neighbors:
    push rcx
    push rsi

    xor r13, r13 ; neighbors count
    ;call l_count_neighbors_above
    ;call l_count_neighbors_next_to
    ;call l_count_neighbors_below

    mov rdx, rsi
.step0:
    add rdx, 641*3
    call l_check_neighbor
.step1:
    sub rdx, 3
    call l_check_neighbor
.step2:
    sub rdx, 3
    call l_check_neighbor

    mov rdx, rsi
.step3:
    add rdx, 3
    call l_check_neighbor
.step4:
    sub rdx, 2*3
    call l_check_neighbor

    mov rdx, rsi
.step5:
    sub rdx, 641*3
    call l_check_neighbor
.step6:
    add rdx, 3
    call l_check_neighbor
.step7:
    add rdx, 3
    call l_check_neighbor

    pop rsi
    pop rcx
    ret

;l_count_neighbors_above:
;    mov rdx, rsi
;.step0:
;    add rdx, 641*3
;    call l_check_neighbor
;.step1:
;    sub rdx, 3
;    call l_check_neighbor
;.step2:
;    sub rdx, 3
;    call l_check_neighbor
;.end:
;    ret
;
;l_count_neighbors_next_to:
;    mov rdx, rsi
;.step0:
;    add rdx, 3
;    call l_check_neighbor
;.step1:
;    sub rdx, 2*3
;    call l_check_neighbor
;.end:
;    ret
;
;l_count_neighbors_below:
;    mov rdx, rsi
;.step0:
;    sub rdx, 641*3
;    call l_check_neighbor
;.step1:
;    add rdx, 3
;    call l_check_neighbor
;.step2:
;    add rdx, 3
;    call l_check_neighbor
;.end:
;    ret

l_check_neighbor:
    mov al, byte [rdx]
    cmp al, 0x00
    je .end
    inc r13
.end:
    ret

l_clear_buffers:
    call l_zero_current
    call l_zero_next
    ret

l_zero_current:
    mov rdi, qword [buffer_current]
    mov rcx, qword [screen_size]
    xor rax, rax
.zero:
    stosw
    stosb
    loop .zero

    ret

l_zero_next:
    mov rdi, qword [buffer_next]
    mov rcx, qword [screen_size]
    xor rax, rax
.zero:
    stosw
    stosb
    loop .zero

    ret
    

l_init_random:
    mov rcx, qword [initial_amount]

.generate:
    call gen_rnd
    mov rax, qword [rnd_a]
    mov rbx, 320
    xor rdx, rdx
    div rbx
    mov rdi, rdx
    add rdi, 160
    call gen_rnd
    mov rax, qword [rnd_a]
    mov rbx, 240
    xor rdx, rdx
    div rbx
    mov rsi, rdx
    add rsi, 120
    call l_resize_xy
    call l_insert_next
    loop .generate

    ret

l_insert_next:
    mov r9, qword [buffer_next]
    call l_xy_to_addr
    add r9, rax
    mov rdi, r9
    mov eax, 0x00ffffff
    stosb
    stosw
    ret

l_xy_to_addr:
    mov rax, rsi
    mov rbx, 640
    mul rbx
    add rax, rdi
    mov rbx, 3
    mul rbx
    ret

l_addr_to_xy:
    xor rdx, rdx
    mov rax, rdi
    mov rbx, 480
    div rbx
    ret ; (rdx, rax)

l_get_xy:
    call l_xy_to_addr
    mov rsi, rax
    mov al, byte [rsi]
    ret

l_resize_xy:
    mov rax, rdi
    mov rbx, 640
    xor rdx, rdx
    div rbx
    mov rdi, rdx
    mov rax, rsi
    mov rbx, 480
    xor rdx, rdx
    div rbx
    mov rsi, rdx
    ret

l_redraw:
    call l_next_to_current
    call l_draw_current
    ;call l_zero_next
    ret

l_next_to_current:
    mov rsi, qword [buffer_next]
    mov rdi, qword [buffer_current]
    mov qword [buffer_next], rdi
    mov qword [buffer_current], rsi
;    mov rcx, [screen_size]
;.l_move_buffers:
;    lodsb
;    stosb
;    lodsw
;    stosw
;    loop .l_move_buffers
    ret

l_draw_current:
    mov rsi, qword [buffer_current]
    mov rdi, qword [video_mem]
    mov rcx, [screen_size]
.l_move_buffers:
    lodsb
    stosb
    lodsw
    stosw
    loop .l_move_buffers
    ret

%include "lib/rand.asm"

video_mem: dq 0x00000000
buffer_current: dq 0x200000
buffer_next: dq 0x400000
screen_size: dq 640*480
automaton_color: db 0xff, 0xff, 0xff
initial_amount: dq 16000
