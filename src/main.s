

/*

Configurar gpmc_ad6 - seu endereço base é o CONTROL_MODULE
gpmc_ad6 - configra como gpio - 0x7 e entrada habilitada (pino 5)
No manual da BBB se refere ao ao gpio1[6] - corresponde ao p8 pino 3 - gpio_oe - 6

*/
.equ BASE_PRCM, 0x44E00000
.equ MODULEMODE_ENABLE, 0x00000002
.equ BASE_GPIO1, 0x4804C000
.equ GPIO_OE, 0x4804C000 + 0x134
.equ GPIO_SETDATAOUT, 0x4804C000 + 0x194
.equ GPIO_CLEARDATAOUT, 0x4804C000 + 0x190
.equ GPIO_DATAIN, 0x4804C000 + 0x138

// setenv autoload no && setenv ipaddr 192.168.1.2 && setenv serverip 192.168.1.1 && tftp 0x80000000 appGpio.bin && go 0x80000000

.global main
//.global enable_clock_gpio1
main:

    @ CONFIGURAR GPIO1_21 COMO SAÍDA
    LDR R3, =GPIO_OE
    LDR R4, [R3] @ GPIO_OE(1 = entrada)
    BIC R4, R4, #(1 << 21) @ BIT 21 = 0 -> saída (LED)
    STR R4, [R3]
/*
    Acender o LED 
    LDR R3, =GPIO_SETDATAOUT0
    LDR R10, [R3]
    MOV R10, #(1 << 21)
    STR R10, [R3]   @ SETDATAOUT -> LED ON
*/
    @ CONFIGURAR GPIO1_28 COMO ENTRADA
    LDR R4, [R3]
    ORR R4, R4, #(1 << 28) @ BIT 28 = 1 -> ENTRADA (BOTÃO)
    STR R4, [R3]

    MOV R6, #0  @ ESTADO_BOTAO = 0
    MOV R7, #0  @ VAR2 = 0

loop:
    @ LER BOTÃO
    LDR R3, =GPIO_DATAIN
    LDR R5, [R3]
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
    LDR R9, =0x3FFFF
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
    LDR R3, =GPIO_SETDATAOUT
    LDR R10, [R3]
    MOV R10, #(1 << 21)
    STR R10, [R3]   @ SETDATAOUT -> LED ON

apaga_led:
    LDR R3, =GPIO_CLEARDATAOUT
    LDR R10, [R3]
    MOV R10, #(1 << 21)
    STR R10, [R3]   @ CLEARDATAOUT -> LED OFF
    B loop




