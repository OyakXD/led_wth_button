    .equ BASE_PRCM: 0x44E00000
    .equ MODULEMODE_ENABLE: 0x00000002
    .equ BASE_GPIO1: 0x4804C000

global _start

_start:
    
    B enable_clock_gpio1

main:

    @ CONFIGURAR GPIO1_21 COMO SAÍDA
    LDR R3, =BASE_GPIO1
    LDR R4, [R3, #0x134] @ GPIO_OE(1 = entrada)
    BIC R4, R4, #(1 << 21) @ BIT 21 = 0 -> saída (LED)
    STR R4, [R3, #0x134]

    @ CONFIGURAR GPIO1_28 COMO ENTRADA
    LDR R4, [R3, #0x134]
    ORR R4, R4, #(1 << 28) @ BIT 28 = 1 -> ENTRADA (BOTÃO)
    STR R4, [R3, #0x134]

    MOV R6, #0  @ ESTADO_BOTAO = 0
    MOV R7, #0  @ VAR2 = 0

loop:
    @ LER BOTÃO
    LDR R5, [R3, #0x138]    @ GPIO_DATAIN
    TST R5, #(1 << 28)
    MOVNE R8, #1    @ VAR = 1 (PRESSIONADO)
    MOVEQ R8, #0    @ VAR = 0 (SOLTO)

    @ VERIFICA TRANSIÇÃO
    CMP R8, #1
    BNE sem_pulso
    CMP R7, #0
    BNE sem_pulso

    @ MUDA O ESTADO DO LED
    EOR R6, R6, #1  @ ESTADO_BOTAO = 1 - ESTADO_BOTAO

    @ DELAY CURTO (EVITAR O DEBOUNCE)
    MOV R9, #0x3FFFF
delay:
    SUBS R9, R9, #1
    BNE delay

sem_pulso:
    MOV R7, R8  @ VAR2 = VAR

    @ CONTROLA O LED
    CMP R6, #1
    BEQ acende_led
    B apaga_led

acende_led:
    MOV R10, #(1 << 21)
    STR R10, [R3, #0x194]   @ SETDATAOUT -> LED ON
    B loop

apaga_led:
    MOV R10, #(1 << 21)
    STR R10, [R3, #0x190]   @ CLEARDATAOUT -> LED OFF
    B loop


enable_glock_gpio1:
    LDR R0, =BASE_PRCM
    LDR R1, =MODULEMODE_ENABLE
    STR R1, [R0, #0xAC]     @CM_PER_GPIO1_CLKCTRL

wait_clk:
    LDR R2, [R0, #0xAC]
    TST R2, #0x3
    BEQ wait_clk
    B main