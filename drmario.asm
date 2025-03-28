################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Sergio Sanchez, 1008801432
# Student 2: Rafay Usman, 1010103317
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       256
# - Unit height in pixels:      256
# - Display width in pixels:    8
# - Display height in pixels:   8
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

BOTTLE_GRID:
    .space 2280    # 19×30 grid (width×height) = 570 cells × 4 bytes = 2280 bytes
                   # Each cell will store 0 for empty, other values for colors
                   
##############################################################################
# Mutable Data
##############################################################################
# Capsule position and orientation
CAPSULE_X:
    .word 11    # Starting X position (middle of the bottle)
CAPSULE_Y:
    .word 3     # Starting Y position (near the top)
CAPSULE_ORIENTATION:
    .word 0     # 0 = horizontal, 1 = vertical
CAPSULE_COLOR1:
    .word 0     # Will store the color of the first pill
CAPSULE_COLOR2:
    .word 0     # Will store the color of the second pill
GAME_OVER:
    .word 0     # 0 = game is running, 1 = game is over
MOVE_DELAY:
    .word 0     # Counter for controlling automatic downward movement
GRAVITY_DELAY:
    .word 15    # Initial delay for gravity (decreases over time)
CAPSULE_COUNT:
    .word 0     # Counter for spawned capsules
GRAVITY_INTERVAL:
    .word 5      # Increase speed every 5 capsules
DIFFICULTY:
    .word 0  # 0=Easy, 1=Medium, 2=Hard
PAUSED:
    .word 0     # 0 = not paused, 1 = paused

# Virus positions and colors
VIRUS_POSITIONS:
    .space 36    # Space for 3 viruses (x, y, color) = 12 bytes per virus
VIRUS_COUNT:
    .word 3      # Number of viruses to generate

##############################################################################
# Code
##############################################################################
    .text
    .globl main

    # Run the game.
main:
    # Initialize the game
    li $t1, 0xff0000        # $t1 = red
    li $t2, 0x00ff00        # $t2 = green
    li $t3, 0x0000ff        # $t3 = blue
    li $t4, 0xffffff        # $t4 = white

    # Initialize capsule position to middle top
    li $t5, 11              # X position (middle)
    sw $t5, CAPSULE_X
    li $t5, 3               # Y position (top)
    sw $t5, CAPSULE_Y
    
    # Initialize orientation to horizontal (0)
    sw $zero, CAPSULE_ORIENTATION
    
    # Generate initial capsule colors
    jal generateCapsuleColors

	#generate the viruses now 
	jal generateViruses
    
    lw $t0, ADDR_DSPL       # $t0 = base address for display 
    # New code for mode selection and virus generation
    # Move this to game_loop
    # jal mode_selection      # Let player choose difficulty
    # jal generate_viruses    # Populate viruses based on difficulty
    
    j game_loop             # Start the game

# mode_selection:
    # # Draw difficulty selection screen
    # # (Assume draw_mode_menu is implemented to display options)
    # # jal draw_mode_menu

    # la $t8, ADDR_KBRD      # Get address of keyboard base address storage
    # lw $t8, 0($t8)         # Load actual keyboard base address


# mode_wait:
    # lw $t9, 0($t8)         # Check if key pressed
    # andi $t9, $t9, 1
    # beqz $t9, mode_wait
    
    # lw $t9, 4($t8)         # Get key code
    
    # li $t3, 101            # ASCII for 'e'
    # beq $t9, $t3, set_easy
    # li $t3, 109            # ASCII for 'm'
    # beq $t9, $t3, set_medium
    # li $t3, 100            # ASCII for 'd' (changed from 104)
    # beq $t9, $t3, set_hard
    
    # j mode_wait           # Invalid key, wait again

# set_easy:
    # li $t1, 4             # 4 viruses
    # sw $t1, VIRUS_COUNT
    # li $t1, 20            # Slow gravity
    # sw $t1, GRAVITY_DELAY
    # j end_mode

# set_medium:
    # li $t1, 8             # 8 viruses
    # sw $t1, VIRUS_COUNT
    # li $t1, 15            # Medium gravity
    # sw $t1, GRAVITY_DELAY
    # j end_mode

# set_hard:
    # li $t1, 12            # 12 viruses
    # sw $t1, VIRUS_COUNT
    # li $t1, 10            # Fast gravity
    # sw $t1, GRAVITY_DELAY

# end_mode:
    # jr $ra                # Return to main

generateViruses:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t0, VIRUS_POSITIONS  # Load address of virus positions array
    lw $t1, VIRUS_COUNT      # Load number of viruses
    li $t2, 0                # Counter
    
gen_virus_loop:
    # Generate random X position (3 to 20)
    li $v0, 42
    li $a0, 0
    li $a1, 18               # Range 0-17
    syscall
    addi $a0, $a0, 3         # Adjust to 3-20 range
    sw $a0, 0($t0)           # Store X position
    
    # Generate random Y position (10 to 28)
    li $v0, 42
    li $a0, 0
    li $a1, 19               # Range 0-18
    syscall
    addi $a0, $a0, 10        # Adjust to 10-28 range
    sw $a0, 4($t0)           # Store Y position
    
    # Generate random color
    jal generateColour
    sw $v0, 8($t0)           # Store color
    
    # Store virus in grid
    lw $t3, 0($t0)           # Load X
    lw $t4, 4($t0)           # Load Y
    
    # Convert to grid coordinates
    subi $t3, $t3, 3         # Subtract left wall offset from X
    
    # Calculate grid index
    mul $t5, $t4, 19         # Y * grid width
    add $t5, $t5, $t3        # Add X
    sll $t5, $t5, 2          # Multiply by 4 for word alignment
    la $t6, BOTTLE_GRID      # Load grid base address
    add $t6, $t6, $t5        # Calculate address in grid
    
    # Store virus color in grid
    lw $t7, 8($t0)           # Load virus color
    sw $t7, 0($t6)           # Store in grid
    
    # Move to next virus
    addi $t0, $t0, 12        # Move to next virus (3 words per virus)
    addi $t2, $t2, 1         # Increment counter
    blt $t2, $t1, gen_virus_loop # Loop if more viruses to generate
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawViruses:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t9, VIRUS_POSITIONS  # Load virus positions array
    lw $t8, VIRUS_COUNT      # Load number of viruses
    li $t7, 0                # Counter
    lw $t0, ADDR_DSPL        # Load display base address
    
draw_virus_loop:
    # Load virus data
    lw $t1, 0($t9)           # X position
    lw $t2, 4($t9)           # Y position
    lw $t3, 8($t9)           # Color
    
    # Calculate pixel position
    mul $t4, $t2, 128        # Y * row width
    mul $t5, $t1, 4          # X * pixel size
    add $t6, $t4, $t5        # Combine offsets
    add $t6, $t6, $t0        # Add to display base
    
    # Draw virus at position
    sw $t3, 0($t6)           # Draw pixel
    
    # Move to next virus
    addi $t9, $t9, 12        # Next virus (3 words)
    addi $t7, $t7, 1         # Increment counter
    blt $t7, $t8, draw_virus_loop
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

game_loop:
	# Check if game is over
    lw $t5, GAME_OVER
    bnez $t5, show_game_over

    # 1a. Check if key has been pressed
    lw $t8, ADDR_KBRD       # $t8 = base address of keyboard
    lw $t9, 0($t8)          # Load first word from keyboard
    andi $t9, $t9, 1        # Extract the least significant bit
    beq $t9, $zero, update_game  # If key not pressed, skip input handling
    
    # 1b. If key is pressed, get the key value
    lw $t9, 4($t8)          # Load second word from keyboard (the key that was pressed)
    
    # Check which key was pressed
    beq $t9, 97, move_left      # ASCII 'a' (move left)
    beq $t9, 100, move_right    # ASCII 'd' (move right)
    beq $t9, 119, rotate        # ASCII 'w' (rotate)
    beq $t9, 115, move_down     # ASCII 's' (move down quickly)
    beq $t9, 113, exit          # ASCII 'q' (quit game)
    beq $t9, 112, toggle_pause  # 'p'
    
    j update_game               # If none of these keys, continue with game

handle_paused_input:
    beq $t9, 112, toggle_pause  # Unpause with 'p'
    j update_game

toggle_pause:
    lw $t5, PAUSED
    xori $t5, $t5, 1        # Toggle pause state
    sw $t5, PAUSED
    j input_done


move_left:
    # Move capsule left if possible
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    
    # Try moving left
    addi $a0, $t5, -1    # New X position
    add $a1, $t6, $zero  # Current Y position
    add $a2, $t7, $zero  # Current orientation
    
    # Check collision
    jal checkCollision
    bnez $v0, input_done  # Skip if collision detected
    
    # Update position if no collision
    sw $a0, CAPSULE_X
    j input_done

move_right:

	# Move capsule right if possible
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    
    # Try moving right
    addi $a0, $t5, 1     # New X position
    add $a1, $t6, $zero  # Current Y position
    add $a2, $t7, $zero  # Current orientation
    
    # Check collision
    jal checkCollision
    bnez $v0, input_done  # Skip if collision detected
    
    # Update position if no collision
    sw $a0, CAPSULE_X
    j input_done
    
check_horizontal_right:
    addi $t5, $t5, 1        # Increment X position
    bge $t5, 18, input_done # Don't move if hitting right wall (account for 2-wide capsule)
    sw $t5, CAPSULE_X
    j input_done

rotate:
    # Rotate the capsule between horizontal and vertical
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    
    # If horizontal to vertical, no special check needed
    # If vertical to horizontal, we need to check right wall
    beq $t7, 1, vertical_to_horizontal
    
    # Calculate new orientation (horizontal to vertical)
    xori $a2, $t7, 1     # Toggle orientation
    add $a0, $t5, $zero  # Current X position
    add $a1, $t6, $zero  # Current Y position
    
    # Check collision with new orientation
    jal checkCollision
    bnez $v0, input_done  # Skip if collision detected
    
    # Update orientation if no collision
    sw $a2, CAPSULE_ORIENTATION
    j input_done
    
vertical_to_horizontal:
    # When going from vertical to horizontal, check if too close to right wall
    bge $t5, 20, input_done  # Can't rotate if too close to right wall
    
    # Now check collision with new orientation
    xori $a2, $t7, 1     # Toggle orientation
    add $a0, $t5, $zero  # Current X position
    add $a1, $t6, $zero  # Current Y position
    
    jal checkCollision
    bnez $v0, input_done  # Skip if collision detected
    
    # Update orientation if no collision
    sw $a2, CAPSULE_ORIENTATION
    j input_done

move_down:
    # Move capsule down if possible
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    
    # Try moving down
    add $a0, $t5, $zero  # Current X position
    addi $a1, $t6, 1     # New Y position
    add $a2, $t7, $zero  # Current orientation
    
    # Check collision
    jal checkCollision
    bnez $v0, new_capsule  # Generate new capsule if collision detected
    
    # Update position if no collision
    sw $a1, CAPSULE_Y
    j input_done

input_done:
    # Input has been processed, move on

update_game:
    # 2a. Update game state (automatic drop)
    lw $t5, PAUSED
    bnez $t5, skip_auto_down
    
    lw $t5, MOVE_DELAY
    addi $t5, $t5, 1
    sw $t5, MOVE_DELAY
    
    # Move down automatically every 15 frames (adjust this number for difficulty)
    lw $t6, GRAVITY_DELAY
    div $t5, $t6
    mfhi $t7        # Get remainder of division
    bne $t7, 0, skip_auto_down

	# Move down automatically
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    
    # Try moving down
    add $a0, $t5, $zero  # Current X position
    addi $a1, $t6, 1     # New Y position
    add $a2, $t7, $zero  # Current orientation
    
    # Check collision
    jal checkCollision
    bnez $v0, new_capsule  # Generate new capsule if collision detected
    
    # Update position if no collision
    sw $a1, CAPSULE_Y

skip_auto_down:
    # 3. Draw the screen
    jal clear_screen
    jal drawBottle
    jal drawStoredPills     # Add this line to draw stored pills
    jal drawActiveCapsule   # Active capsule should be drawn last
    
    # 4. Sleep (for approximately 16.67ms to achieve 60 FPS)
    li $v0, 32           
    li $a0, 17          # sleep for ~17 milliseconds (1000ms / 60fps ≈ 16.67ms)
    syscall

    # 5. Go back to Step 1
    j game_loop

new_capsule:
	# First, store the current capsule in the grid
    jal store_current_capsule
    
    #Check, the current matches loop
    jal check_matches_loop

matches_done:
    # Reset capsule to top middle and generate new colors
    li $t5, 11
    sw $t5, CAPSULE_X
    li $t5, 3
    sw $t5, CAPSULE_Y
    li $t5, 0
    sw $t5, CAPSULE_ORIENTATION
    jal generateCapsuleColors
    
    # Check if game is over
    jal checkGameOver
    
    lw $t6, CAPSULE_COUNT
    addi $t6, $t6, 1
    sw $t6, CAPSULE_COUNT
    
    lw $t7 GRAVITY_DELAY
    bge $t7 5 gravity_adjusted_check #Minimum Gravity
    
    j skip_auto_down

gravity_adjusted_check:
    lw $t5, CAPSULE_COUNT
    lw $t6, GRAVITY_INTERVAL
    div $t5, $t6
    mfhi $t7             # Get remainder
    beqz $t7, adjust_gravity # Skip if not at interval
    
adjust_gravity:
    lw $t8, GRAVITY_DELAY
    addi $t8, $t8, -1
    sw $t8 GRAVITY_DELAY


check_matches_loop:
    # Check for matches and remove them
    jal find_matches
    
    # If no matches were found, exit the loop
    beqz $v0, matches_done
    
    # If matches were found, drop unsupported pills
    jal drop_unsupported_pills
    
    # Check for new matches that may have formed
    j check_matches_loop

find_matches:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Set $v0 to 0 initially (no matches found)
    li $v0, 0
    
    # First check for horizontal matches
    jal find_horizontal_matches
    
    # If horizontal matches were found, set $v0 to 1
    bnez $v0, matches_found
    
    # Then check for vertical matches
    jal find_vertical_matches
    
matches_found:
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

find_horizontal_matches:
    # Save return address and $s registers we'll use
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    # Set $v0 to 0 initially (no matches found)
    li $v0, 0
    
    # Loop through each row of the grid
    li $s0, 0          # Row counter
    
row_loop_h:
    # Loop through each potential starting position in the row
    li $s1, 0          # Column counter
    
col_loop_h:
    # Get current cell color
    mul $t1, $s0, 19   # Row * width
    add $t1, $t1, $s1  # Add column offset
    sll $t1, $t1, 2    # Multiply by 4 (word alignment)
    la $t2, BOTTLE_GRID
    add $t2, $t2, $t1  # Grid cell address
    lw $t3, 0($t2)     # Cell color
    
    # Skip if empty
    beqz $t3, next_col_h
    
    # Check if we have at least 3 more columns to check
    addi $t4, $s1, 3   # Need positions x, x+1, x+2, x+3
    bge $t4, 19, next_col_h  # Skip if not enough space
    
    # Check next 3 positions for the same color
    addi $t2, $t2, 4   # Move to x+1
    lw $t4, 0($t2)
    bne $t4, $t3, next_col_h
    
    addi $t2, $t2, 4   # Move to x+2
    lw $t4, 0($t2)
    bne $t4, $t3, next_col_h
    
    addi $t2, $t2, 4   # Move to x+3
    lw $t4, 0($t2)
    bne $t4, $t3, next_col_h
    
    # If we get here, we found a match of 4 horizontal cells
    li $v0, 1          # Set found flag
    
    # Clear the matched cells
    mul $t1, $s0, 19   # Row * width
    add $t1, $t1, $s1  # Add column
    sll $t1, $t1, 2    # Multiply by 4
    la $t2, BOTTLE_GRID
    add $t2, $t2, $t1  # Address of first cell
    
    # Clear the 4 cells
    sw $zero, 0($t2)
    sw $zero, 4($t2)
    sw $zero, 8($t2)
    sw $zero, 12($t2)
    
next_col_h:
    addi $s1, $s1, 1   # Increment column
    blt $s1, 16, col_loop_h  # Loop if not at end (19-3 = 16 is the last valid start position)
    
    addi $s0, $s0, 1   # Increment row
    blt $s0, 30, row_loop_h  # Loop if not at the bottom
    
    # Restore registers and return
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

find_vertical_matches:
    # Save return address and $s registers we'll use
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    # Set $v0 to 0 initially (no matches found)
    li $v0, 0
    
    # Loop through each column
    li $s1, 0          # Column counter
    
col_loop_v:
    # Loop through each potential starting position in the column
    li $s0, 0          # Row counter
    
row_loop_v:
    # Get current cell color
    mul $t1, $s0, 19   # Row * width
    add $t1, $t1, $s1  # Add column offset
    sll $t1, $t1, 2    # Multiply by 4 (word alignment)
    la $t2, BOTTLE_GRID
    add $t2, $t2, $t1  # Grid cell address
    lw $t3, 0($t2)     # Cell color
    
    # Skip if empty
    beqz $t3, next_row_v
    
    # Check if we have at least 3 more rows to check
    addi $t4, $s0, 3   # Need positions y, y+1, y+2, y+3
    bge $t4, 30, next_row_v  # Skip if not enough space
    
    # Check next 3 positions for the same color
    addi $t2, $t2, 76  # Move to y+1 (19*4 bytes per row)
    lw $t4, 0($t2)
    bne $t4, $t3, next_row_v
    
    addi $t2, $t2, 76  # Move to y+2
    lw $t4, 0($t2)
    bne $t4, $t3, next_row_v
    
    addi $t2, $t2, 76  # Move to y+3
    lw $t4, 0($t2)
    bne $t4, $t3, next_row_v
    
    # If we get here, we found a match of 4 vertical cells
    li $v0, 1          # Set found flag
    
    # Clear the matched cells
    mul $t1, $s0, 19   # Row * width
    add $t1, $t1, $s1  # Add column
    sll $t1, $t1, 2    # Multiply by 4
    la $t2, BOTTLE_GRID
    add $t2, $t2, $t1  # Address of first cell
    
    # Clear the 4 cells
    sw $zero, 0($t2)
    addi $t5, $t2, 76  # y+1
    sw $zero, 0($t5)
    addi $t5, $t5, 76  # y+2
    sw $zero, 0($t5)
    addi $t5, $t5, 76  # y+3
    sw $zero, 0($t5)
    
next_row_v:
    addi $s0, $s0, 1   # Increment row
    blt $s0, 27, row_loop_v  # Loop if not too close to bottom (30-3 = 27 is the last valid start position)
    
    addi $s1, $s1, 1   # Increment column
    blt $s1, 19, col_loop_v  # Loop if not at the right edge
    
    # Restore registers and return
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

drop_unsupported_pills:
    # Save return address and $s registers we'll use
    addi $sp, $sp, -24
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)   # Flag for movement (0 = no movement, 1 = movement)
    
    # Process each column from bottom to top
    li $s1, 0      # Column counter
    
drop_loop:
    li $s4, 0          # Reset movement flag each iteration
    
    # Process each column from bottom to top
    li $s1, 0          # Column counter

drop_col_loop:
    # Start processing from the second-to-last row, working up
    li $s0, 28         # Start from row 28

drop_row_loop:
    # Get current cell color
    mul $t1, $s0, 19       # Row * width
    add $t1, $t1, $s1      # Add column offset
    sll $t1, $t1, 2        # Multiply by 4 (word alignment)
    la $t2, BOTTLE_GRID
    add $t2, $t2, $t1      # Grid cell address
    lw $t3, 0($t2)         # Cell color at current position
    
    # Skip if cell is empty
    beqz $t3, drop_next_row
    
    # Check the cell below
    addi $t4, $t2, 76      # Move to row below (19*4 bytes)
    lw $t5, 0($t4)         # Color of cell below
    
    # Only proceed if cell below is empty
    bnez $t5, drop_next_row
    
    # Check left neighbor (if not first column)
    beqz $s1, check_right  # Skip if first column
    lw $t6, -4($t2)        # Load left neighbor
    bnez $t6, drop_next_row # Blocked by left neighbor
    
check_right:
    # Check right neighbor (if not last column)
    addi $t7, $s1, 1       # Next column
    bge $t7, 19, push_down # Skip if last column
    lw $t6, 4($t2)         # Load right neighbor
    bnez $t6, drop_next_row # Blocked by right neighbor
    
push_down:
    # Move pill down if no horizontal neighbors
    sw $t3, 0($t4)         # Copy to cell below
    sw $zero, 0($t2)       # Clear current cell
    li $s4, 1              # Set movement flag

drop_next_row:
    addi $s0, $s0, -1  # Move up one row
    bgez $s0, drop_row_loop  # Continue if not at top row
    
    addi $s1, $s1, 1   # Move to next column
    blt $s1, 19, drop_col_loop  # Continue if not at the right edge
    
    # Repeat the process if any movement occurred
    bnez $s4, drop_loop
    
    # Restore registers and return
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    addi $sp, $sp, 24
    jr $ra

store_current_capsule:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Load capsule position and orientation
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    lw $t8, CAPSULE_COLOR1    # Load color 1
    lw $t9, CAPSULE_COLOR2    # Load color 2
    
    # Calculate grid index for first pill
    # Grid index = y * grid_width + x
    # Since our bottle is 19 cells wide (from x=3 to x=21)
    subi $t5, $t5, 3    # Adjust x coordinate (subtract the left wall offset)
    mul $t3, $t6, 19    # Multiply y by grid width
    add $t3, $t3, $t5   # Add x offset
    
    # Convert to byte address (multiply by 4)
    sll $t3, $t3, 2     # Multiply by 4 for word alignment
    
    # Store first pill in grid
    la $t4, BOTTLE_GRID
    add $t4, $t4, $t3
    sw $t8, 0($t4)      # Store actual color value in grid
    
    # Calculate position of second pill based on orientation
    beq $t7, 0, store_horizontal
    
    # Vertical orientation (second pill below first)
    addi $t3, $t3, 76   # Move down one row in the grid (19*4 bytes)
    add $t4, $t4, 76    # 19*4 bytes per row
    sw $t9, 0($t4)      # Store second pill color
    j store_done
    
store_horizontal:
    # Horizontal orientation (second pill right of first)
    addi $t3, $t3, 4    # Move right one column in the grid (4 bytes)
    add $t4, $t4, 4
    sw $t9, 0($t4)      # Store second pill color
    
store_done:
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


clear_screen:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Clear the entire screen by setting each pixel to black
    lw $t5, ADDR_DSPL
    li $t6, 0           # Black color
    li $t7, 4096        # 64×64 display = 4096 pixels
    li $t8, 0           # Counter
    
clear_loop:
    sw $t6, 0($t5)      # Set pixel to black
    addi $t5, $t5, 4    # Move to next pixel
    addi $t8, $t8, 1    # Increment counter
    bne $t8, $t7, clear_loop
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

generateCapsuleColors:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Generate first color
    jal generateColour
    sw $v0, CAPSULE_COLOR1
    
    # Generate second color
    jal generateColour
    sw $v0, CAPSULE_COLOR2
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

generateColour:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Generate random number between 0-2
    li $v0, 42
    li $a0, 0
    li $a1, 3
    syscall
    
    # Set color based on random number
    beq $a0, 0, set_red_color
    beq $a0, 1, set_green_color
    li $v0, 0x0000ff    # Blue
    j store_color
    
set_red_color:
    li $v0, 0xff0000    # Red
    j store_color
    
set_green_color:
    li $v0, 0x00ff00    # Green
    
store_color:
    # Result is already in $v0
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawBottle:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
	
    jal drawTop
    jal drawSides
    jal drawBottom
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawActiveCapsule:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Load capsule position and orientation
    lw $t5, CAPSULE_X
    lw $t6, CAPSULE_Y
    lw $t7, CAPSULE_ORIENTATION
    lw $t8, CAPSULE_COLOR1
    lw $t9, CAPSULE_COLOR2
    
    # Calculate first pill position
    mul $a1, $t6, 128   # Y position * row width (32 * 4 bytes)
    mul $a0, $t5, 4     # X position * pixel size (4 bytes)
    add $a3, $a1, $a0   # Combine X and Y offsets
    add $a3, $a3, $t0   # Add to display base address
    
    # Draw first pill
    sw $t8, 0($a3)
    
    # Calculate second pill position based on orientation
    beq $t7, 0, horizontal_capsule
    
    # Vertical orientation (second pill below first)
    addi $a3, $a3, 128  # Move down one row
    sw $t9, 0($a3)
    j capsule_done
    
horizontal_capsule:
    # Horizontal orientation (second pill right of first)
    addi $a3, $a3, 4    # Move right one pixel
    sw $t9, 0($a3)
    
capsule_done:
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawTop:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)

	li $t4, 0xffffff        # $t4 = white

    #the little opening at the top of the bottle 5 pixels wide
    sw $t4, 160($t0)   #column 8 row 2(0 indexed)      
    sw $t4, 188($t0)   #column 13 row 2

    #draw the left side of the top of the bottle
    addi $a2, $zero, 6 #line from 2 to 8
    addi $a0, $zero, 3 #initialize x coord
    addi $a1, $zero, 2 #draw from column underneath the bottle opening
    jal drawLineHoriz #draw with those parameters
    
    #draw the right side of the top of the bottle
    addi $a2, $zero, 6 #draw 6 pixels 
    addi $a0, $zero, 15 #initialize x coord
    addi $a1, $zero, 2 #draw from the column beneath the opening
    jal drawLineHoriz #draw again with new parameters
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    #finished top of bottle
    jr $ra

drawSides:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $t4, 0xffffff        # $t4 = white

    #draw left wall of the bottle
    addi $a2, $zero, 28 #side to be 27 pixels long
    addi $a0, $zero, 2 #wall starts at left most side which is 2
    addi $a1, $zero, 2 #draw from row underneath the bottle opening
    jal drawLineVert 
    
    addi $a2, $zero, 29 
    addi $a0, $zero, 21 #right most side of the bottle should be at pixel 19 (2 + 6 + 5 + 6)
    addi $a1, $zero, 2 #initialize y coord start at third row
    jal drawLineVert
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawBottom:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)

	li $t4, 0xffffff        # $t4 = white
	
    addi $a2, $zero, 19 #line from col 2 to 20
    addi $a0, $zero, 2 #initialize x coord start to 2 (left side of the bottle)
    addi $a1, $zero, 30 #draw bottom of the bottle at 30
    jal drawLineHoriz #draw left side of the bottle
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawStoredPills:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $s0, BOTTLE_GRID    # Load grid base address
    li $s1, 0              # Row counter
    li $s2, 0              # Column counter
    lw $t0, ADDR_DSPL      # Load display base address
    
draw_grid_loop_row:
    li $s2, 0              # Reset column counter
    
draw_grid_loop_col:
    # Calculate grid index
    mul $t1, $s1, 19       # Row * width
    add $t1, $t1, $s2      # Add column
    sll $t1, $t1, 2        # Multiply by 4 (word alignment)
    add $t1, $t1, $s0      # Add to grid base address
    
    # Load color from grid
    lw $t2, 0($t1)
    beqz $t2, next_grid_cell    # Skip if empty (0)
    
    # Convert grid coordinates to screen coordinates
    addi $t3, $s2, 3       # Add left wall offset to column
    add $t4, $s1, $zero    # Y coordinate
    
    # Calculate pixel address
    mul $t5, $t4, 128      # Y * row width in bytes
    mul $t6, $t3, 4        # X * pixel size
    add $t7, $t5, $t6      # Combine X and Y
    add $t7, $t7, $t0      # Add display base address
    
    # Draw the pixel with the stored color
    sw $t2, 0($t7)
    
next_grid_cell:
    addi $s2, $s2, 1       # Increment column
    blt $s2, 19, draw_grid_loop_col    # Loop for all columns
    
    addi $s1, $s1, 1       # Increment row
    blt $s1, 30, draw_grid_loop_row    # Loop for all rows
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

checkCollision:
    # Input: $a0 = x, $a1 = y, $a2 = orientation
    # Output: $v0 = 1 if collision, 0 if no collision
    
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Convert screen coordinates to grid coordinates
    addi $t5, $a0, -3    # Adjust X (subtract left wall offset)
    add $t6, $a1, $zero  # Y stays the same
    
    # Check if out of bounds
    blt $t5, 0, collision_true    # Left boundary
    bge $t5, 18, collision_true   # Right boundary
    
    # Check orientation to apply correct boundaries
    beq $a2, 0, horizontal_bound_check
    # Vertical capsule: grid_x can be 0-18
    blt $t5, 0, collision_true
    bge $t5, 19, collision_true
    j check_y_bounds
    
    # For vertical orientation, check if bottom pill would be out of bounds
    beq $a2, 1, check_vertical_bounds
    bge $t6, 30, collision_true   # Bottom boundary for horizontal
    j continue_collision_check
    
check_vertical_bounds:
    addi $t8, $t6, 1     # Position of bottom pill in vertical orientation
    bge $t8, 30, collision_true   # Check if bottom pill would be beyond boundary

horizontal_bound_check:
    # Horizontal capsule: grid_x can be 0-17 (since two cells)
    blt $t5, 0, collision_true
    bge $t5, 18, collision_true

check_y_bounds:
    # Check Y bounds based on orientation
    beq $a2, 0, check_horizontal_y
    # Vertical: check if y+1 is within bounds
    addi $t8, $t6, 1
    bge $t8, 30, collision_true
    j continue_collision_check

check_horizontal_y:
    bge $t6, 30, collision_true

continue_collision_check:
    # Check orientation
    beq $a2, 0, check_horizontal_collision
    
    # Vertical orientation: check both cells
    mul $t3, $t6, 19     # Row * width
    add $t3, $t3, $t5    # Add column
    sll $t3, $t3, 2      # Multiply by 4 (word alignment)
    la $t4, BOTTLE_GRID   # Grid base address
    add $t3, $t3, $t4    # Add to grid base address
    
    # Check first cell
    lw $t7, 0($t3)
    bnez $t7, collision_true    # Collision if cell is not empty
    
    # Check second cell (below first)
    addi $t3, $t3, 76    # Move down one row (19*4 bytes)
    lw $t7, 0($t3)
    bnez $t7, collision_true    # Collision if cell is not empty
    
    j collision_false
    
check_horizontal_collision:
    # Horizontal orientation: check both cells
    bge $t5, 17, collision_true    # Right boundary adjusted for horizontal
    
    mul $t3, $t6, 19     # Row * width
    add $t3, $t3, $t5    # Add column
    sll $t3, $t3, 2      # Multiply by 4 (word alignment)
    la $t4, BOTTLE_GRID   # Grid base address
    add $t3, $t3, $t4    # Add to grid base address
    
    # Check first cell
    lw $t7, 0($t3)
    bnez $t7, collision_true    # Collision if cell is not empty
    
    # Check second cell (right of first)
    addi $t3, $t3, 4     # Move right one column (4 bytes)
    lw $t7, 0($t3)
    bnez $t7, collision_true    # Collision if cell is not empty
    
collision_false:
    li $v0, 0    # No collision
    j collision_done
    
collision_true:
    li $v0, 1    # Collision detected
    
collision_done:
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

checkGameOver:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check if there are pills at the opening position
    # We'll check the starting capsule position
    lw $t5, CAPSULE_X    # Default starting X (usually 11)
    li $t6, 3            # Default starting Y
    lw $t7, CAPSULE_ORIENTATION  # Default orientation
    
    add $a0, $t5, $zero  # X position
    add $a1, $t6, $zero  # Y position
    add $a2, $t7, $zero  # Orientation
    
    # Use collision detection to check if starting position is blocked
    jal checkCollision
    
    # If collision detected, game over
    beqz $v0, game_not_over
    
    # Game over - set flag
    li $t5, 1
    sw $t5, GAME_OVER
    
game_not_over:
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

drawGameOver:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Clear screen first
    jal clear_screen
    
    # Draw "GAME OVER" text
    lw $t0, ADDR_DSPL    # Display base address
    li $t1, 0xff0000     # Red color for game over
    
    # G position (first row, first letter)
    sw $t1, 1024($t0)    # Top horizontal
    sw $t1, 1028($t0)
    sw $t1, 1032($t0)
    sw $t1, 1036($t0)
    sw $t1, 1152($t0)    # Left vertical
    sw $t1, 1280($t0)
    sw $t1, 1408($t0)
    sw $t1, 1536($t0)
    sw $t1, 1540($t0)    # Bottom horizontal
    sw $t1, 1544($t0)
    sw $t1, 1548($t0)
    sw $t1, 1420($t0)    # Right vertical with horizontal
    sw $t1, 1424($t0)
    sw $t1, 1428($t0)
    sw $t1, 1300($t0)
    
    # A position (first row, second letter)
    sw $t1, 1044($t0)    # Top horizontal
    sw $t1, 1048($t0)
    sw $t1, 1052($t0)
    sw $t1, 1172($t0)    # Left vertical
    sw $t1, 1300($t0)
    sw $t1, 1428($t0)
    sw $t1, 1556($t0)
    sw $t1, 1180($t0)    # Right vertical
    sw $t1, 1308($t0)
    sw $t1, 1436($t0)
    sw $t1, 1564($t0)
    sw $t1, 1304($t0)    # Middle horizontal
    sw $t1, 1312($t0)
    
    # M position (first row, third letter)
    sw $t1, 1060($t0)    # Left vertical
    sw $t1, 1188($t0)
    sw $t1, 1316($t0)
    sw $t1, 1444($t0)
    sw $t1, 1572($t0)
    sw $t1, 1064($t0)    # Middle slopes
    sw $t1, 1196($t0)
    sw $t1, 1072($t0)
    sw $t1, 1196($t0)
    sw $t1, 1068($t0)    # Middle
    sw $t1, 1196($t0)
    sw $t1, 1324($t0)
    sw $t1, 1076($t0)    # Right vertical
    sw $t1, 1204($t0)
    sw $t1, 1332($t0)
    sw $t1, 1460($t0)
    sw $t1, 1588($t0)
    
    # E position (first row, fourth letter)
    sw $t1, 1084($t0)    # Left vertical
    sw $t1, 1212($t0)
    sw $t1, 1340($t0)
    sw $t1, 1468($t0)
    sw $t1, 1596($t0)
    sw $t1, 1088($t0)    # Top horizontal
    sw $t1, 1092($t0)
    sw $t1, 1096($t0)
    sw $t1, 1100($t0)
    sw $t1, 1344($t0)    # Middle horizontal
    sw $t1, 1348($t0)
    sw $t1, 1352($t0)
    sw $t1, 1600($t0)    # Bottom horizontal
    sw $t1, 1604($t0)
    sw $t1, 1608($t0)
    sw $t1, 1612($t0)
    
    # O position (second row, first letter)
    sw $t1, 2056($t0)    # Top horizontal
    sw $t1, 2060($t0)
    sw $t1, 2064($t0)
    sw $t1, 2068($t0)
    sw $t1, 2184($t0)    # Left vertical
    sw $t1, 2312($t0)
    sw $t1, 2440($t0)
    sw $t1, 2568($t0)
    sw $t1, 2572($t0)    # Bottom horizontal
    sw $t1, 2576($t0)
    sw $t1, 2580($t0)
    sw $t1, 2584($t0)
    sw $t1, 2196($t0)    # Right vertical
    sw $t1, 2324($t0)
    sw $t1, 2452($t0)
    sw $t1, 2580($t0)
    
    # V position (second row, second letter)
    sw $t1, 2076($t0)    # Left slope
    sw $t1, 2204($t0)
    sw $t1, 2332($t0)
    sw $t1, 2460($t0)
    sw $t1, 2588($t0)
	sw $t1, 2592($t0)
	sw $t1, 2596($t0)
	sw $t1, 2600($t0)
    sw $t1, 2092($t0)    # Right slope
    sw $t1, 2220($t0)
    sw $t1, 2348($t0)
    sw $t1, 2476($t0)
    sw $t1, 2604($t0)
    
    # E position (second row, third letter)
    sw $t1, 2100($t0)    # Left vertical
    sw $t1, 2228($t0)
    sw $t1, 2356($t0)
    sw $t1, 2484($t0)
    sw $t1, 2612($t0)
    sw $t1, 2104($t0)    # Top horizontal
    sw $t1, 2108($t0)
    sw $t1, 2112($t0)
    sw $t1, 2116($t0)
    sw $t1, 2360($t0)    # Middle horizontal
    sw $t1, 2364($t0)
    sw $t1, 2368($t0)
    sw $t1, 2616($t0)    # Bottom horizontal
    sw $t1, 2620($t0)
    sw $t1, 2624($t0)
    sw $t1, 2628($t0)
    
    # R position (second row, fourth letter)
    sw $t1, 2124($t0)    # Left vertical
    sw $t1, 2252($t0)
    sw $t1, 2380($t0)
    sw $t1, 2508($t0)
    sw $t1, 2636($t0)
    sw $t1, 2128($t0)    # Top horizontal
    sw $t1, 2132($t0)
    sw $t1, 2136($t0)
    sw $t1, 2140($t0)
    sw $t1, 2268($t0)    # Right top vertical
    sw $t1, 2396($t0)
    sw $t1, 2384($t0)    # Middle horizontal
    sw $t1, 2388($t0)
    sw $t1, 2392($t0)
    sw $t1, 2516($t0)    # Right bottom diagonal
    sw $t1, 2648($t0)
    
    # Draw "PRESS R TO RESTART" message below
    li $t1, 0xffffff     # White color for instructions
    
    # Message at the bottom of screen (simplified)
    # P
    sw $t1, 3072($t0)
	sw $t1, 3200($t0)
	sw $t1, 3328($t0)
    sw $t1, 3076($t0)
    sw $t1, 3080($t0)
    sw $t1, 3208($t0)
    sw $t1, 3336($t0)
	sw $t1, 3332($t0)
    sw $t1, 3456($t0)
	sw $t1, 3584($t0)
    sw $t1, 3208($t0)
    
    # R
    sw $t1, 3088($t0)
    sw $t1, 3216($t0)
    sw $t1, 3344($t0)
    sw $t1, 3472($t0)
    sw $t1, 3600($t0)
    sw $t1, 3092($t0)
    sw $t1, 3096($t0)
    sw $t1, 3224($t0)
    
    # E
    sw $t1, 3104($t0)
    sw $t1, 3232($t0)
    sw $t1, 3360($t0)
    sw $t1, 3488($t0)
    sw $t1, 3616($t0)
    sw $t1, 3108($t0)
    sw $t1, 3112($t0)
    sw $t1, 3116($t0)
    sw $t1, 3364($t0)
    sw $t1, 3368($t0)
    sw $t1, 3620($t0)
    sw $t1, 3624($t0)
    sw $t1, 3628($t0)
    
    # S
    sw $t1, 3124($t0)
    sw $t1, 3128($t0)
    sw $t1, 3132($t0)
    sw $t1, 3252($t0)
    sw $t1, 3380($t0)
    sw $t1, 3384($t0)
    sw $t1, 3388($t0)
    sw $t1, 3516($t0)
	sw $t1, 3636($t0)
    sw $t1, 3640($t0)
    sw $t1, 3644($t0)
    
    # S
    sw $t1, 3140($t0)
    sw $t1, 3144($t0)
    sw $t1, 3148($t0)
    sw $t1, 3268($t0)
    sw $t1, 3396($t0)
    sw $t1, 3400($t0)
    sw $t1, 3404($t0)
    sw $t1, 3532($t0)
	sw $t1, 3652($t0)
    sw $t1, 3656($t0)
    sw $t1, 3660($t0)
    
    # Draw an "R" in a different color to highlight it
    li $t1, 0x00ff00     # Green color for the R
    sw $t1, 3172($t0)
    sw $t1, 3300($t0)
    sw $t1, 3428($t0)
    sw $t1, 3556($t0)
    sw $t1, 3684($t0)
    sw $t1, 3176($t0)
    sw $t1, 3180($t0)
    sw $t1, 3184($t0)
    sw $t1, 3312($t0)
    sw $t1, 3440($t0)
    sw $t1, 3428($t0)
    sw $t1, 3432($t0)
    sw $t1, 3436($t0)
	sw $t1, 3560($t0)
	sw $t1, 3692($t0)
    
    # Restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

show_game_over:
    # Display game over screen only once
    jal drawGameOver
    
    # Now wait for 'r' key without redrawing the screen
wait_for_restart:
    # Check if 'r' key is pressed to restart
    lw $t8, ADDR_KBRD
    lw $t9, 0($t8)
    andi $t9, $t9, 1
    beq $t9, $zero, wait_for_restart  # If no key, keep checking
    
    lw $t9, 4($t8)
    beq $t9, 114, restart_game    # restart game if r is pressed
	beq $t9, 113, exit # end game if q pressed
    j wait_for_restart  # If not 'r', keep waiting

restart_game:
    # Reset game variables
    sw $zero, GAME_OVER
    
    # Initialize the grid to empty
    la $t9, BOTTLE_GRID    # Use $t9 instead of $t0
    li $t1, 0
    li $t2, 570    # 19×30 grid size (number of cells)
    
reset_grid_loop:
    sw $zero, 0($t9)      # Store word (4 bytes) of zeros
    addi $t9, $t9, 4      # Move to next word
    addi $t1, $t1, 1      # Increment counter
    blt $t1, $t2, reset_grid_loop
    
    # Reset capsule position
    li $t5, 11            # Use $t5 instead of $t0
    sw $t5, CAPSULE_X
    li $t5, 3
    sw $t5, CAPSULE_Y
    sw $zero, CAPSULE_ORIENTATION
    
    # Reload display base address before returning to game loop
    lw $t0, ADDR_DSPL
    
    # Generate new colors
    jal generateCapsuleColors

	#Gen new viruses
	jal generateViruses
    
    j game_loop

drawLineHoriz:
    # This is a leaf function (doesn't call other functions)
    # so we don't need to save $ra
    
    # Main line drawing loop
    add $t5, $zero, $zero
    
    sll $a1, $a1, 7 #account for vertical offset
    sll $a0, $a0, 2  #account for horizontal offset
    
    add $t7, $a1, $t0 #set the start points for x and y
    add $t7, $a0, $t7
    j pixelDrawHor

pixelDrawHor:     # the starting label for the pixel drawing loop  
    sw $t4, 0($t7)      # paint the current bitmap location white.
    addi $t5, $t5, 1      # increment the loop variable
    addi $t7, $t7, 4      # move to the next pixel in the row.
    beq $t5, $a2, pixelDrawEnd    # break out of the loop if you hit the stop condition
    j pixelDrawHor    # jump to the top of the loop

drawLineVert:
    # This is a leaf function (doesn't call other functions)
    # so we don't need to save $ra
    
    # Main line drawing loop
    add $t5, $zero, $zero
    
    sll $a1, $a1, 7 #account for vertical offset
    sll $a0, $a0, 2  #account for horizontal offset
    
    add $t7, $a1, $t0 #set the start points for x and y
    add $t7, $a0, $t7
    j pixelDrawVert

pixelDrawVert:     # the starting label for the pixel drawing loop  
    sw $t4, 0($t7)      # paint the current bitmap location white.
    addi $t5, $t5, 1      # increment the loop variable
    addi $t7, $t7, 128    # move to the next pixel in the column.
    beq $t5, $a2, pixelDrawEnd    # break out of the loop if you hit the stop condition
    j pixelDrawVert    # jump to the top of the loop

pixelDrawEnd:       # the end label for the pixel drawing loop
    jr $ra

exit:
    li $v0, 10              # terminate the program gracefully
    syscall