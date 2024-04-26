DISPLAY_X       EQU 500
DISPLAY_Y       EQU 20
DISPLAY_WIDTH   EQU 120
DISPLAY_HEIGHT  EQU 100
COL_OFFSSET     EQU 30
ROW_OFFSET      EQU 35

*===================================
*converts a hex digit to it's deimcal counterpart
*and stores the bitmask for that decimal digit in an array
next_digit
    divu.w  d0, d1
    swap    d1
    move.b  (a1, d1.w), (a2)+
    clr.w   d1
    swap    d1
    rts    



*====================================
*displays the playerHeight on a 7 segment display
displayScore
        movem.l ALL_REG, -(sp)
        moveq   #0, d1                  ;clear reg
                                        
        move.l  totalHeightOffset, d1  ;load score
        lsr.l   #6, d1
        lea     digit_segments, a1      ;load digit segements
        lea     digitDisplay, a2        ;load digit display
        
        moveq   #10, d0                 ;set divisor
        BSR.s   next_digit              ;get digit
        BSR.s   next_digit              ;get digit
        BSR.s   next_digit              ;get digit
        BSR.s   next_digit              ;get digit
        
        
        move.l  #ON_COLOR, d1
        move.b  #80, d0
        TRAP    #15
        
        moveq   #0, d6                  ;reset column offset
        lea     digitDisplay, a2        ;load digit display
        jsr     displayDigit
        sub.w   #32, d6
        jsr     displayDigit
        sub.w   #32, d6
        jsr     displayDigit
        sub.w   #32, d6
        jsr     displayDigit

        movem.l (sp)+, ALL_REG
        rts
 
*==========================================
* draws each segment and determines       
displayDigit
        lea     segments, a5
        move.b  (a2)+, d5              ;load the bitmask
        moveq   #6, d7                 ;start the counter
segmentLoop
        move.l  #ON_COLOR, d1          ;Set the on color by default
        add.b   d5,d5                  ;determine status of each bit
        bcc.s   segment_off            ;if carry is clear segment is off
        
        bra     score
        
segment_off         
        move.l  #OFF_COLOR, d1         ;turn off segment
score
        moveq   #81, d0                ;set color
        trap    #15
            
        moveq   #80, d0                ;set color
        trap    #15
        
        move.w  (a5)+, d1       ;load segment x coord
        move.w  (a5)+, d2       ;load segment y coord
        add.w   d6, d1          ; add column offset
        move.w  d1, d3          ; move x to d3
        move.w  d2, d4          ; move y to d4
        add.w  (a5)+, d3        ; add width
        add.w  (a5)+, d4        ; add height
        
        moveq   #87, d0
        trap    #15

        dbf     d7, segmentLoop
        
        rts  




digit_segments
    dc.b    %01111110   ;0
    dc.b    %00001100   ;1
    dc.b    %10110110   ;2
    dc.b    %10011110   ;3
    dc.b    %11001100   ;4
    dc.b    %11011010   ;5
    dc.b    %11111010   ;6
    dc.b    %00001110   ;7
    dc.b    %11111110   ;8
    dc.b    %11011110   ;9
    
    
segments
    dc.w    595, 36, 15, 5     *segment  g (x,y,w,h)
    dc.w    593, 24, 5, 12     *segment  f
    dc.w    593, 41, 5, 12     *segment  e
    dc.w    595, 53, 15, 5     *segment  d
    dc.w    607, 41, 5, 12     *segment  c
    dc.w    607, 24, 5, 12     *segment  b
    dc.w    595, 19, 15, 5     *segment  a










*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
