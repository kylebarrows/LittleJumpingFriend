START   ORG    $1000

*all registers
ALL_REG                 REG     D0-D7/A0-A6
COLLISION_REG           REG     D0-D6/A0-A6

*trap commands
SET_PEN_COLOR_COMMAND   equ     80
SET_FILL_COLOR_COMMAND  equ     81
DRAW_RECT_COMMAND       equ     87
DRAW_CIRCLE_COMMAND     equ     88
CLEAR_SCREEN_COMMAND    equ     11
CLEAR_SCREEN_MAGIC_VAL  equ     $FF00
DRAWING_MODE_TRAP_CODE  equ     92
DOUBLE_BUFFERED_MODE    equ     17
GET_USER_INPUT_COMMAND  equ     19
REPAINT_SCREEN_TRAP_CODE        equ     94

*key codes
KEY_LEFT_INPUT          equ     $25
KEY_RIGHT_INPUT         equ     $27

*fractional bits
FRAC_BITS               equ     12
NEG_MASK                equ     31

*ball info
BALL_RADIUS             equ     10
BALL_WIDTH              equ     20
BALL_HEIGHT             equ     20
BALL_VELOCITY           equ     5<<FRAC_BITS
BALL_LEFT_VELOCITY      equ     6<<FRAC_BITS

*physics stuff
GRAVITY                 equ     -1<<FRAC_BITS
IMPACT_VELOCITY         equ     20<<FRAC_BITS

*platform stuff
PLATFORM_WIDTH          equ     60
PLATFORM_HEIGHT         equ     10
PLATFORM_X_MAX          equ     640
PLATFORM_Y_OFFSET       equ     200
SCROLL_SPEED            equ     -1

*screen
BOTTOM_OF_SCREEN        equ     480
SCREEN_WIDTH            equ     640
SCREEN_HEIGHT           equ     480

PLATFORMCOLOR           equ     $00921A7D
WHITE                   equ     $00FFFFFF
RED                     equ     $000000FF
GREEN                   equ     $0000FF00
BLUE                    equ     $00FF0000
ON_COLOR                equ     $000000FF
OFF_COLOR               equ     $00000030

        bra         main
        INCLUDE   'COLLISION.X68'
        INCLUDE   'RANDOM.X68'
        INCLUDE   'DISPLAY.X68'
        INCLUDE   'BITMAP.X68'

main
        jsr         displayStartScreen
        jsr         reset
        
        ;set double buffered mode
        move.b      #DRAWING_MODE_TRAP_CODE, d0
        move.b      #DOUBLE_BUFFERED_MODE, d1
        trap        #15

        ;draw entire background
        lea     background, a6
        jsr     drawBackground
        
        jsr     awaitInput
        
        ;set timer
        lea     s_Time, a0
        move    #8, d0
        trap    #15
        move.l  d1, (a0)

timer    
        move    #8, d0
        trap    #15
        move.l  d1, d2
        sub.l   (a0), d2
        cmp.l   delay, d2
        bge     gameloop
        bra     timer
        
gameloop:
        move.l  d1, (a0)
        
*read input
        jsr     getInputs
     
*updates   
        jsr     updateBall
        jsr     updatePlatforms
        jsr     resolveCollisions
        
*renders
        jsr     clearBall
        jsr     clearPlatforms        
        jsr     drawPlatform
        jsr     drawBall
        jsr     displayScore
        jsr     swapBuffers
        
        bra     timer
        
loadingText
 ; set font properties
        moveq   #21, d0
        move.l  #$00FFFFFF, d1
        move.w  #$0110, d2
        swap    d2
        move.w  #0, d2
        trap    #15
        
        moveq   #95, d0
        move.w  #240, d1
        move.w  #200, d2
        lea     loadText, a1
        trap    #15 
        
        rts
        
reset
    ;initialize x position and x velocity of ball
        lea         PlayerXPosition, a0
        move.l      #320<<FRAC_BITS, d0
        move.l      d0, (a0)                    ;set x position    
        move.l      #BALL_HEIGHT>>FRAC_BITS, d1 ;set y position
        add.l       #40<<FRAC_BITS, d1
        move.l      d1, 4(a0)                   ;store y position
        move.l      #0, d2                      ;init x velocity
        move.l      d2, 8(a0)                   ;store x velocity
        move.l      #BALL_VELOCITY, d3          ;init y velocity
        move.l      d3, 12(a0)                  ;store y velocity
   
        ;set player height to 0
        lea         playerHeight, a4
        move.l      #0, d4
        move.l      d4, (a4)
        
        lea         totalHeightOffset, a4
        move.l      d4, (a4)
        
        lea         playerMaxHeight, a4
        move.l      #250, (a4)
        
        lea         platformOffset, a4
        move.l      #0, (a4)
        
        ;set platform positions
        lea         platforms, a4
        move.l      #100, d4
        move.l      #120, d5
        move.l      d4, (a4)+
        move.l      d5, (a4)+
        
        move.l      #200, d4
        move.l      #240, d5
        move.l      d4, (a4)+
        move.l      d5, (a4)+
        
        move.l      #300, d4
        move.l      #340, d5
        move.l      d4, (a4)+
        move.l      d5, (a4)+
        
        move.l      #200, d4
        move.l      #440, d5
        move.l      d4, (a4)+
        move.l      d5, (a4)+
        rts
        
displayStartScreen
        moveq   #95, d0
        move.w  #220, d1            ;move x pos
        move.w  #200, d2            ;move y pos
        lea     title, a1           ;load title
        trap    #15 
        move.w  #150, d1            ;move x pos
        move.w  #240, d2            ;move y pos
        lea     rulesText, a1       ;load rules
        trap    #15 
        move.w  #150, d1            ;move x pos
        move.w  #260, d2            ;move y pos
        lea     controlsText, a1    ;load controls
        trap    #15 
        move.w  #210, d1            ;move x pos
        move.w  #290, d2            ;move y pos
        lea     anyKey, a1          ;load anyKey
        trap    #15 
        
        rts
        
displayGameoverScreen
        moveq   #95, d0
        move.w  #260, d1            ;move x pos
        move.w  #200, d2            ;move y pos
        lea     gameOverText, a1    ;load title
        trap    #15 
        move.w  #150, d1            ;move x pos
        move.w  #240, d2            ;move y pos
        lea     rulesText, a1       ;load rules
        trap    #15 
        move.w  #150, d1            ;move x pos
        move.w  #260, d2            ;move y pos
        lea     controlsText, a1    ;load controls
        trap    #15 
        move.w  #210, d1            ;move x pos
        move.w  #290, d2            ;move y pos
        lea     anyKey, a1          ;load anyKey
        trap    #15 
        
        rts
        
awaitInput
        moveq   #5, d0
        trap    #15
        rts
        
displayGameover
        jsr     displayGameoverScreen
        jsr     displayScore
        jsr     swapBuffers
        jsr     reset
        jsr     drawBackground
        jsr     awaitInput
        jsr     cleanTopLeft
        jsr     swapBuffers

        rts

clearScreen:
        move.b  #CLEAR_SCREEN_COMMAND, d0
        move.l  #CLEAR_SCREEN_MAGIC_VAL, d1
       	TRAP    #15
	    rts
	    
swapBuffers:
        move.b  #REPAINT_SCREEN_TRAP_CODE,d0
      	TRAP    #15
	    rts
	    
getInputs:	
        movem.l  ALL_REG, -(sp)
        
        move.l  #(KEY_LEFT_INPUT<<8 + KEY_RIGHT_INPUT), d1
        move.l  #GET_USER_INPUT_COMMAND, d0
        trap    #15
        
        *check for left input
        move.l  d1, d2
        andi.l  #$0000FF00, d2
        bne     keyLeftInput
        
        *check for right input
        move.l  d1, d2
        andi.l  #$000000FF, d2
        bne     keyRightInput 
        
        *reset x velocity if no input
        lea     playerXVelocity, a0
        move.l  (a0), d0
        move.l  #0, d0
        move.l  d0, (a0)

        bra     doneInput 

doneInput:      
        movem.l (sp)+, ALL_REG
        rts
 
*Could make this horizontal acceleration up to a max velocity,       
keyLeftInput:
        lea     playerXVelocity, a0
        move.l  (a0), d0
        move.l  #-BALL_LEFT_VELOCITY, d0
        move.l  d0, (a0)
        
        bra     doneInput
        
keyRightInput:
        lea     playerXVelocity, a0
        move.l  (a0), d0
        move.l  #BALL_LEFT_VELOCITY, d0
        move.l  d0, (a0)
        
        bra     doneInput        
                
updateBall:
        movem.l  ALL_REG, -(sp)
        
        *Load position and velocity values
        lea     playerXPosition, a0
        move.l  (a0), d0                  ;load x position  
        move.l  4(a0), d1                 ;load y position  
        move.l  8(a0), d2                 ;load x velocity  
        move.l  12(a0), d3                ;load y velocity
        
        *Store positions before updating
        move.l  d0, d4          ;copy x pos
        lsr.l   #8, d4
        lsr.l   #4, d4      
        move.l  d1, d5          ;copy y pos
        lsr.l   #8, d5
        lsr.l   #4, d5
        move.l  d4, 16(a0)      ;store x pos
        move.l  d5, 20(a0)      ;store y pos
        
        *Load platform offset
        lea     platformOffset, a5
        move.l  #0, (a5)                  ;clear offset for this frame
        
        *Update position based on velocity
        add.l   d2, d0          ;update x pos
        add.l   d3, d1          ;update y pos
        
        *Update y-velocity based on gravity
        add.l   #GRAVITY, d3
        
        *Check if player is within bounds of screen
        cmpi.l  #0, d0                  ;check if off left side
        bgt.b   checkRightSide
        
        move.l  #0, d0                  ;reset x position
        
checkRightSide
        cmpi.l  #((SCREEN_WIDTH-BALL_WIDTH)<<FRAC_BITS), d0   ;check if off right side
        blt.b   inXBounds
        
        move.l  #(SCREEN_WIDTH-BALL_WIDTH)<<FRAC_BITS, d0

inXBounds
        *Check if ball is above screen_height midpoint
        cmpi.l  #(BOTTOM_OF_SCREEN>>1), d5
        blt.b   notAboveMid
        
        move.l  d1, d4
        subi.l  #(BOTTOM_OF_SCREEN>>1), d5              ;compute the difference from player height to middle of screen 
        move.l  d5, (a5)                                ;store the difference
        add.l   d5, totalHeightOffset
        lsl.l   #8, d5
        lsl.l   #4, d5
        sub.l   d5, d1                                  ;move the ball back to the middle of the screen

    
                                
notAboveMid        
        *Check if at edge of screen
        cmpi.l  #0, d1 
        bgt     noPositiveSet
        *Check if player has climbed at all
        *End game if they have and are below edge of screen
        cmpi.l  #1, totalHeightOffset
        bgt     gameOver
 
        move.l #IMPACT_VELOCITY, d3
        move.l  d3, 12(a0)
        move.l  #(BALL_HEIGHT<<FRAC_BITS), d1
        bra     noPositiveSet

        
noPositiveSet
        *Store data back in variables
        move.l  d0, (a0)
        move.l  d1, 4(a0)
        move.l  d3, 12(a0)
        
endPlayerUpdate
        ;jsr resolveCollisions
        movem.l (sp)+, ALL_REG
        rts
        
gameOver
        jsr displayGameover
        movem.l (sp)+, ALL_REG
        rts

        
updatePlatforms
        movem.l ALL_REG, -(sp)
        
        lea     platforms, a0
                
        move.l  #3, d5                  ;move numPlatforms -1
        move.l  platformOffset, d3      ;load offset for this frame
        
updatePlatformLoop:
        move.l  (a0)+, d1        ;load top left x position
        move.l  (a0)+, d2        ;load top left y position
        
        ; Convert height back into screen coordinates
        move.l  #BOTTOM_OF_SCREEN, d6
        move.l  d2, d4
        sub.l   d4, d6
        
        ;if below the bottom of the screen, move to a new y Pos
        cmpi    #BOTTOM_OF_SCREEN, d6
        blt     scroll
        
        ; generate new position for platform
        jsr getRandomByteIntoD6
        addi.l  #480, d2
        move.l  d6, -8(a0)   
        
scroll:      
        sub.l   d3, d2          ;move platform down by offset amount
        move.l  d2, -4(a0)      ;store position back in array
        
        dbf     d5, updatePlatformLoop   
        
dontApplyOffset
        movem.l (sp)+, ALL_REG
        rts     
        
*==============
*END OLD COLLISION CODE
    
drawPlatform
        movem.l ALL_REG,-(sp)
        
        *set pen color and fill
        move.l  #PLATFORMCOLOR, d1
        move.b  #SET_PEN_COLOR_COMMAND, d0
        trap    #15
        move.b  #SET_FILL_COLOR_COMMAND, d0
        trap    #15
        
        lea     platforms, a0
        
        move.l  #3, d5      ;move numPlatforms -1
        
drawPlatformLoop
        *FORCE SET POSITION FOR NOW
        move.l  (a0)+, d1               ;load x pos
        move.l  #BOTTOM_OF_SCREEN, d2   ;load y pos
        sub.l   (a0)+, d2
        
        move.l  d1, d3                  
        addi.l  #PLATFORM_WIDTH, d3     ;load bottom x pos
        move.l  d2, d4
        addi.l  #PLATFORM_HEIGHT, d4    ;bottom y pos

        moveq   #DRAW_RECT_COMMAND, d0
        trap    #15
        
        dbf     d5, drawPlatformLoop
        
        movem.l (sp)+, ALL_REG
        rts
        
drawBall
        movem.l ALL_REG,-(sp)
       
        *set pen color and fill
        move.l  #GREEN, d1
        moveq   #SET_PEN_COLOR_COMMAND, d0
        trap    #15
        moveq   #SET_FILL_COLOR_COMMAND, d0
        trap    #15
        
        *load player position
        move.l  playerXPosition, d1
        lsr.l   #8, d1
        lsr.l   #4, d1
        
        move.l  #BOTTOM_OF_SCREEN<<FRAC_BITS, d2
        sub.l   playerYPosition, d2                 ;Convert world position to screen pos
        lsr.l   #8, d2
        lsr.l   #4, d2
  
        
        *load player size
        move.l  d1, d3
        addi.l   #BALL_WIDTH, d3
        
        move.l  d2, d4
        addi.l  #BALL_HEIGHT, d4
        
        moveq   #DRAW_CIRCLE_COMMAND, d0
        trap    #15
        
        movem.l (sp)+, ALL_REG
        rts
        

    SIMHALT             ; halt simulator

* variables and constants here
playerXPosition         ds.l    1
playerYPosition         ds.l    1
playerXVelocity         ds.l    1
playerYVelocity         ds.l    1
prevPlayerXPos          ds.l    1
prevPlayerYPos          ds.l    1

totalHeightOffset       ds.l    1
platformOffset          ds.l    1
playerHeight            ds.l    1
playerMaxHeight         ds.l    1

randomVal               ds.l    1
digitDisplay            ds.l    1

platforms               dcb.l   8,0
endOfPlatforms

delay                   dc.l    2
s_Time                  ds.l    1
  
prevPlatformPos         dcb.l   4,0
background              incbin  'Background.bmp'
loadText                dc.b    'Loading...',0
title                   dc.b    'Little Jumping Friend', 0
rulesText               dc.b    'Climb as high as possible without falling.', 0
controlsText            dc.b    'Use left and right arrow keys to move.', 0
anyKey                  dc.b    'Press any key to start.', 0
gameOverText            dc.b    'Game Over!', 0    



    END    START


























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
