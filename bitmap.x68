SET_PEN_COLOR_CMD     EQU     80
DRAW_CMD              EQU     82
PARAM1                EQU     4


; <STEP 1> replace this subroutine with your actual code
drawBitmap
        movem.l ALL_REG,-(sp)
        sub.l    #4, sp     ;make space for local variable 
        move.l   d4, (sp)   
        
        move.l 10(a1), d6   ;load offset to pixel data into d0
        ; convert endianness
        rol.w   #8, d6
        swap    d6
        rol.w   #8, d6
        
        move.l  a1, a2
        add.l   d6, a2
        
        ; move to beginning of chunk in pixel array
        ; starting offset = ((iWidth * (iHeight - (cHeight + startY)) + startX) * nBytes
        ;load height
        move.l  22(a1), d7
        rol.w   #8, d7
        swap    d7
        rol.w   #8, d7
        
        sub.l   d1, d7          ;subtract Y
        sub.l   d3, d7          ;subtract height
        
        ;load width
        move.l  18(a1), d6
        rol.w   #8, d6
        swap    d6
        rol.w   #8, d6
        
        move.l  d6, d4
        
        mulu.w  d6, d7          ;multiply by width
        add.l   d0, d7          ;add x
        lsl.l   #2, d7          ;multiply by 4
        add.l   d7, a2          ;add to address
        
        ; store (imgWidth - cWidth) * nBytes
        sub.l   d2, d4
        lsl.l   #2, d4
        
        move.l  d2, d6          ;move width to d6
        move.l  d3, d2          ;calculate starting height     displayY + chunkHeight
        add.l   d5, d2
        move.l  d3, d7          ;copy height to d7
        ;subi    #1, d7
        
        move.l  (sp), d5
        
        subi    #1, d6                          ;sub 1
        move.l  d6, d3                          ;store in d3
       
drawBitmapLoop
        moveq  #SET_PEN_COLOR_CMD, d0           ;load pen color commmand 
        move.l (a2)+, d1                        ;get pixel color
        lsr.l  #8, d1                           ;shift into proper format
        TRAP   #15
    
        moveq  #DRAW_CMD, d0
        move.l d5, d1
        TRAP   #15
    
        ; check if we reached the end of chunk row
        addi   #1, d5                          ;move to next position
        dbf     d3, drawBitmapLoop
        
        ; move to first pixel in next row
        add.l  d4, a2
    
       ; increment height and reset loop counter
        move.l (sp), d5
        move.l d6, d3           ;reset row counter
        subi   #1, d2           ;move to next row 

        dbf     d7, drawBitmapLoop
        
        add.l   #4, sp
        movem.l (sp)+, ALL_REG
        rts

; a1 - pointer to bmp data
; d0,d1,d2,d3 - rect to display from image (x,y,w,h)
; d4,d5 - top left display position (dx,dy)
drawBitmap_wrapper:
        ; <STEP 2> move parameter values to the place your subroutine expects them
        jsr     drawBitmap
        rts
        
; a6 - pointer to bmp       
clearPlatforms:
        movem.l ALL_REG, -(sp)
        
        move.l  a6, a1
        move.l  #PLATFORM_WIDTH+1, d2     ;width
        move.l  platformOffset, d3      ;height
        
        cmpi    #0, d3
        ble.b   clearPlatformDone
        
        lea     platforms, a5
        
        move.l  #(endOfPlatforms - platforms), d6
        
clearPlatformLoop
        move.l  (a5)+, d0               ;load x pos
        move.l  #SCREEN_HEIGHT, d1
        sub.l   (a5)+, d1               ;load y pos
        sub.l   d3, d1                  ;move to old y pos
        move.l  d0, d4                  ;display x
        move.l  d1, d5                  ;display y
        
        jsr     drawBitmap
        
        subi    #8, d6
        
        cmpi    #0, d6
        bgt.b   clearPlatformLoop
        
clearPlatformDone
        movem.l (sp)+, ALL_REG 
        rts            
                
; a6 - pointer to bmp       
clearBall:
        movem.l  ALL_REG,-(sp)
        
        lea     prevPlayerXPos, a2
        move.l  (a2), d0                ;load x pos
        move.l  #SCREEN_HEIGHT, d1      ;load y pos
        sub.l   4(a2), d1
        move.l  #BALL_WIDTH+1, d2       ;width
        move.l  #BALL_HEIGHT+1, d3      ;height
        move.l  d0, d4                  ;display x
        move.l  d1, d5                  ;display y
        
        move.l  a6, a1
        jsr     drawBitmap
        
        movem.l (sp)+, ALL_REG 
        rts        
        
; remove character from top left corner after gameover screen.... :|        
cleanTopLeft
        movem.l ALL_REG,-(sp)
        moveq   #0, d0
        moveq   #0, d1
        move.l  #30, d2
        move.l  #30, d3
        moveq   #0, d4          
        moveq   #0, d5
        
        move.l  a6, a1
        jsr     drawBitmap
        
        movem.l (sp)+, ALL_REG 
        rts        

        
drawBackground
        lea     background, a1
        moveq   #0, d0
        moveq   #0, d1
        move.l  #(SCREEN_WIDTH + 1), d2
        move.l  #(SCREEN_HEIGHT + 1), d3
        moveq   #0, d4
        moveq   #0, d5
        jsr     drawBitmap
        rts        
                 



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
