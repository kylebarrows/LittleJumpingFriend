resolveCollisions
        movem.l  ALL_REG, -(sp)
        
        move.l  platformOffset, d0
        cmpi.l  #0, d0
        bgt     done
        
        lea     playerXPosition, a0
        move.l  12(a0), d3          ;load y velocity  
        ; if ball is travelling up ignore collision with platforms
        cmpi.l  #-1, d3
        bge     done
        
        move.l  (a0), d0            ;load x pos
        move.l  4(a0), d1           ;load y pos        
        move.l  8(a0), d2           ;load x velocity
        
        lea     platforms, a0
        lea     totalHeightOffset, a1
        
        * load center x pos of ball
        asr.l   #8, d0
        asr.l   #4, d0
        add.l   #BALL_WIDTH>>1, d0
        move.l  d0, d4                  ;copy x pos
        
        * load center y pos of ball
        asr.l   #8, d1
        asr.l   #4, d1
        subi.l  #BALL_HEIGHT>>1, d1       
        move.l  d1, d5                  ;copy y pos
        
        cmpi.l  #230, d1
        bgt     done
        
        *Calculate substep height
        *velocity
        lsr.l   #8, d3
        lsr.l   #4, d3
        neg.l   d3
        lsr.l   #2, d3
        and.l   #$F, d3
        
        ;init loop
        move.l  #(endOfPlatforms - platforms), d6
colLoop    
        *Check first ball position
        jsr testCollision
        btst    #0, d7
        bne     done
        
        sub.l   d3, d1
        
        
        jsr testCollision
        btst    #0, d7
        bne.b     done

        move.l  d4, d0          ;reset x pos
        move.l  d5, d1          ;reset y pos
        
        add.l   #8, a0
        subi    #8, d6
        bne.b     colLoop
        
done:
        movem.l (sp)+, ALL_REG
        rts

        
*==============================
*d0: x position
*d1: y position
*d7: return bool wether we hit or not
*a0: address of platform
*==============================        
testCollision
        movem.l COLLISION_REG, -(sp)
        
        move.l  (a0)+, d4                            ;d4 platform xPos
        addi.l  #PLATFORM_WIDTH>>1, d4    ;move to center of rect       
        move.l  (a0)+, d5                            ;d5 platform yPos
        addi.l   #PLATFORM_HEIGHT>>1, d5   ;move to center of y
        
        move.l  #0, d7      ;d7 Yedge to test
        
        ;calculate distance from box to ball
        ; Determine distance from center of rect on the x axis
        cmp     d4, d0
        blt.b   toLeft
        sub.l   d4, d0      ;d0 xDistance
        bra.b   testY
        
toLeft
        sub.l   d0, d4
        move.l  d4, d0
        
testY
        ; Determine distance from center of rect on the y axis
        cmp     d5, d1
        blt.b   below
        sub.l   d5, d1      ;d1 yDistance
        bra     checkForCollision
        
below   
        sub.l   d1, d5
        move.l  d5, d1
        
checkForCollision
        ; test circle and rect x
        cmpi.l  #(PLATFORM_WIDTH>>1 + BALL_RADIUS), d0
        bgt.b   noCollision
        
        ;test y
        cmpi.l  #(PLATFORM_HEIGHT>>1 + BALL_RADIUS), d1
        bgt.b   noCollision
        
        cmpi.l  #PLATFORM_WIDTH>>1, d0
        ble.b   collided
        
        cmpi    #PLATFORM_HEIGHT>>1, d1
        ble.b   collided
        
        move.l  d0, d3
        move.l  d1, d4
        
        subi.w  #PLATFORM_WIDTH>>1, d3
        mulu.w  d3, d3
        subi.w  #PLATFORM_HEIGHT>>1, d4
        mulu.w  d4, d4
        
        add.l   d3, d4
        
        cmpi    #(BALL_RADIUS * BALL_RADIUS), d4
        bgt.b   noCollision     
        
collided
        move.l  #1, d7
        move.l  #IMPACT_VELOCITY, playerYVelocity
        
noCollision
        movem.l (sp)+, COLLISION_REG
        rts















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
