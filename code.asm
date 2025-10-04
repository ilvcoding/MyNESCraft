.setcpu "6502x"
; Adresses
	controller = $4016
	apu_enable = $4015
	dragon_energy_1_x = $02F3
	dragon_energy_1_y = $02F0
	dragon_energy_2_x = $02F7
	dragon_energy_2_y = $02F4
	dragon_energy_3_x = $02FB
	dragon_energy_3_y = $02F8
	dragon_energy_4_x = $02FF
	dragon_energy_4_y = $02FC
	crossbow_arrow_y = $0204

; Local variables
	reg_adr = $000E
	line_start = $000F
	line_mod = $0010
	in_xy = $0011
	in_ang = $0012
	out_x = $0013
	out_y = $0014
	ray_steps = $0015
	break_pressed = $002C
	place_pressed = $002D

; Global variables
	display_buff = $0300 ; $0300 -> $04FF
	display_buff_middle = $0400
	blocks = $0500       ; $0500 -> $05FF
	frame_wait = $0016
	px = $0017
	py = $0018
	pa = $0019
	pdx = $001A
	pdy = $001B
	pvx = $001D
	pvy = $001E
	pl = $0039
	color_emphasis = $001F
	point_x = $0020
	point_y = $0021
	prev_point_x = $003A
	prev_point_y = $003B
	day_time_inc_wait = $002F
	day_time = $0030
	day_count = $0031
	in_game = $0032
	selected_hotbar_slot = $0033
	select_pressed = $0034
	start_pressed = $0035
	strafing = $0036
	inventory_open = $0037
	pressing_oib = $0038
	check_top_map = $0023
	inventory_pallete_update = $003C
	time = $003D
	jingle_position = $003E
	prev_jingle_note = $003F
	bg_music_position = $0040
	bg_music_page = $0041
	prev_note_high_pulse_2 = $0042
	prev_note_low_pulse_2 = $0043
	prev_note_high_triangle = $0044
	prev_note_low_triangle = $0045
	item_amounts = $0046 ; $0046 -> $0048
	enable_music = $0049
	enable_sound = $004A
	music_enable_changed = $004B
	sound_enable_changed = $004C
	loop_mincraft_times = $004E
	pulse_1_volume = $004F
	game_progress = $0050
	sound_change_animation_time = $0051
	last_sound_change = $0052
	player_health = $0053
	player_health_changed = $0054
	time_since_died = $0055
	damage_cooldown = $0056
	player_hunger = $0057
	player_hunger_changed = $0058
	eating_sound_time = $0059
	player_energy = $005A
	player_energy_changed = $005B
	in_the_end = $005C
	pressed_up_left_down = $005D
	just_coded_up = $005E
	just_coded_left = $005F
	just_coded_down = $0060
	time_since_tunnel = $0061
	display_frame = $0062
	dragon_x = $0063
	dragon_y = $0064
	end_scroll = $0065
	sprite_zero_hit = $0066
	scroll_time = $0067
	crystal_1_exists = $0068
	crystal_2_exists = $0069
	dragon_time = $006A
	end_paused = $006B
	fire_breath_time = $006C
	crossbow_cooldown = $006D
	time_since_dragon_died = $006E
	in_end_poem = $006F
	poem_scroll_low = $0070
	poem_scroll_high = $0071
	poem_scroll_sub_pixel = $0072
	poem_page = $0073
	poem_character_pos = $0074
	poem_character_nybl = $0075
	draw_text_line_flag = $0076
	lower_line_chars = $0077 ; $0077 -> $0081
	lower_line_chars2 = $0082 ; $0082 -> $008C
	finished_poem = $008D
	star_index = $008E
	star_counter = $008F
	playing_triangle_notes = $0090

; Function variables
	set_tile_type = $0022
	trig_input = $0024
	trig_output = $0025
	trig_out_neg = $0026
	line_x = $0027
	line_h = $0028
	ray_angle = $0029
	line_color = $002A
	draw_bottom = $002B
	block_type = $002E
	rand_out = $004D

.segment "HEADER"
.byte "NES"
.byte $1A
.byte $02 ; 2x 16 kb of program rom
.byte $01 ; 1x 8 kb of char rom
.byte %00000000 ; mapper and mirroring
.byte $00
.byte $00
.byte $00
.byte $00
.byte $00, $00, $00, $00, $00

.segment "ZEROPAGE"
background_tiles: .res 2
background_attributes: .res 2
raycast_lut: .res 2
diff_x_squared: .res 2
diff_y_squared: .res 2
dist_squared: .res 2

.segment "STARTUP"
; When the game starts
reset:
	; Disable interrupts and decimals
		sei
		cld

	; Disable sound IRQ
		ldx #$40
		stx $4017

	; Initialize the stack register
		ldx #$FF
		txs

	; Clear all addresses and registers
		inx ; X == 0 now
		; Clear out the PPU registers
			stx $2000
			stx $2001
			stx $4010
			:
			bit $2002
			bpl :-
		; Clear out all the memory
			txa
			clear_memory:
			sta $0000, x
			sta $0100, x
			sta $0300, x
			sta $0400, x
			sta $0500, x
			sta $0600, x
			sta $0700, x
			lda #$FF
			sta $0200, x
			lda #$00
			inx
			bne clear_memory 
			; wait for vblank
				:
				bit $2002
				bpl :-
				lda #$02
				sta $4014
				nop

	; Initiallize zeropage addresses
		lda #<name_table_tiles
		sta background_tiles
		lda #>name_table_tiles
		sta background_tiles + 1
		lda #<name_table_tiles_attributes
		sta background_attributes
		lda #>name_table_tiles_attributes
		sta background_attributes + 1

	; Load pallets
		lda #$3F
		sta $2006
		lda #$00
		sta $2006
		ldx #$00
		load_palettes:
		lda palettes, x
		sta $2007
		inx
		cpx #$20
		bne load_palettes

	; Setup the first screen and load its contents
		; Setup address in PPU for nametable data
			bit $2002
			lda #$20
			sta $2006
			lda #$00
			sta $2006
		; Store nametable tile data
			ldx #$00
			ldy #$00
			load_background_tiles:
			lda (background_tiles), y
			sta $2007
			iny
			; Check if we finished
				cpx #$02
				bne :+
				cpy #$20
				beq done_loading_background_tiles
				:
				cpy #$00
				bne load_background_tiles
				inx
				inc background_tiles + 1
				jmp load_background_tiles
		done_loading_background_tiles:
		; Make sure there aren't artifacts on the bottom half of the screen
		lda #$00
		clear_first_screen:
			sta $2007
			iny
			; Check if we finished
				cpx #$03
				bne :+
				cpy #$C0
				beq done_clearing_first_screen
				:
				cpy #$00
				bne clear_first_screen
				inx
				inc background_tiles + 1
				jmp clear_first_screen
		done_clearing_first_screen:
		; Set nametable attributes
			ldy #$00
			lda #$00
			set_background_tile_attributes:
			sta $2007
			iny
			cpy #$40
			bne set_background_tile_attributes

	; Setup the second screen and load its contents
		lda #>name_table_tiles
		sta background_tiles + 1
		; Setup address in PPU for nametable data
			bit $2002
			lda #$28
			sta $2006
			lda #$00
			sta $2006
		; Store nametable tile data
			ldx #$00
			ldy #$00
			load_background_tiles2:
			cpx #$03
			bne :+
			cpy #$60
			bcs :++
			:
			lda (background_tiles), y
			:
			sta $2007
			iny
			; Check if we finished
				cpx #$03
				bne :+
				cpy #$C0
				beq done_loading_background_tiles2
				:
				cpy #$00
				bne load_background_tiles2
				inx
				inc background_tiles + 1
				jmp load_background_tiles2
		done_loading_background_tiles2:
		; Set nametable attributes
			ldy #$00
			set_background_tile_attributes2:
			lda (background_attributes), y
			sta $2007
			iny
			cpy #$40
			bne set_background_tile_attributes2
	
	; Set screen scroll offset
		lda #$00
		sta $2005
		lda #$F8
		sta $2005
	
	; Enable sprites and background with no color emphasis
		lda #%00011110
		sta $2001
	
	; Make background use the correct nametable
		lda #%10010000
		sta $2000

	; Re-enable interrupts
		cli
	
	; Set variables initial value
		lda #$03
		sta pdy
		sta bg_music_page
		sta star_counter
		lda #$FF
		sta inventory_pallete_update
		sta bg_music_position ; Set the background music to not be playing at first
		lda #$40 ; Play the titlescreen music
		sta jingle_position
		sta pa
		lda #$01
		sta enable_music
		sta enable_sound
		sta game_progress
		sta selected_hotbar_slot
		sta crystal_1_exists
		sta crystal_2_exists
		sta poem_scroll_high
		lda #$14
		sta player_health
		sta player_hunger
		lda #$60
		sta dragon_x
		lda #$38
		sta dragon_y
		lda #$C8
		sta poem_scroll_low
		lda #$80
		sta star_index
	
	; Initiallize all the the blocks in the world
		ldx #$00
		load_blocks:
		lda starting_blocks, x
		sta blocks, x
		inx
		cpx #$00
		bne load_blocks
	
	; Initiallize audio
		lda #$01 ; Enable all audio channels
		sta apu_enable

; The game logic loop
loop:
	; Keep consistant frame rate
		ldx frame_wait
		cpx #$00
		bne loop
		lda #$06 ; 10 FPS
		sta frame_wait
		inc time

	; Increase time of day
		lda day_time_inc_wait
		clc
		adc #$20
		sta day_time_inc_wait
		cmp #$00
		bne :+
		inc day_time
		; Increase date
		lda day_time
		cmp #$00
		bne :+
		inc day_count
		:
		; Decrement eating sound duration
		lda eating_sound_time
		beq :+
		dec eating_sound_time
		lda eating_sound_time
		bne :+
		sta $400C
		lda player_hunger
		adc #$03
		sta player_hunger
		inc player_hunger_changed
		:
	
	; Check if we are already dead
		lda in_the_end
		bne :+
		lda time_since_died
		beq :+
		jmp start_playing_music
		:

	; Check if we are going to the end
		lda in_the_end
		bne :+
		jmp not_in_the_end
		:
		; Delete the big cloud
		lda #$FF
		sta $0228
		sta $022C
		sta $0230
		sta $0234
		sta $0238
		sta $023C
		sta $0240
		sta $0244
		sta $0248
		sta $024C
		; Play end transition sound
		; Enable channels
			lda #$0B
			sta apu_enable
		; Noise
			lda #$FF
			sta $400C
			sta $400E
			sta $400F
		; Set the player's vertical look direction
			lda #$80
			sta pl

	end_loop:
		; Check for sprite zero hit
		lda sprite_zero_hit
		beq :+
    	bit $2002           ; read PPUSTATUS
    	bvc :+
		lda #$07
		sta $2005
		lda #$E4
		sta $2005
		lda #%10010010
		sec
		sbc in_game
		sta $2000
		dec sprite_zero_hit
		:
		; Keep consistant frame rate
		ldx frame_wait
		cpx #$00
		bne end_loop
		lda #$01 ; 60 FPS
		sta frame_wait
		; Check if we already are in the end
		lda time_since_tunnel
		cmp #$80
		bne :+
		jmp currently_in_the_end ; Jump to handling the ender dragon fight
		:
		; We are currently going to the end
		; Draw the clouds
		; Small cloud 1 left
			; Vertical position
				lda #$37
				adc time_since_tunnel
				sta $0218
			; Attributes
				lda #$09
				sta $0219
				lda #$22
				sta $021A
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$00
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $021B
		; Small cloud 1 right
			; Vertical position
				lda #$37
				adc time_since_tunnel
				sta $021C
			; Attributes
				lda #$0A
				sta $021D
				lda #$22
				sta $021E
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$08
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $021F
		; Small cloud 2 left
			; Vertical position
				lda #$2D
				adc time_since_tunnel
				sta $0220
			; Attributes
				lda #$0A
				sta $0221
				lda #$62
				sta $0222
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$C3
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $0223
		; Small cloud 2 right
			; Vertical position
				lda #$2D
				adc time_since_tunnel
				sta $0224
			; Attributes
				lda #$09
				sta $0225
				lda #$62
				sta $0226
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$CB
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $0227
		; Play end transition sound
		; Pulse
			lda #%01111101
			sta $4000
			sta $4001
			sta $4004
			sta $4005
			lda time_since_tunnel
			asl a
			sta $4002
			sta $4006
			lda #%11110100
			sta $4003
			lda #%11110011
			sta $4007
		; Deleting the background
		lda time_since_tunnel
		cmp #$80
		bcs finished_erasing_world
		asl a
		asl a
		tay
		lda #$00
		sta display_buff, y
		sta display_buff + 1, y
		sta display_buff + 2, y
		sta display_buff + 3, y
		lda #$A8
		sta display_buff_middle, y
		sta display_buff_middle + 1, y
		sta display_buff_middle + 2, y
		sta display_buff_middle + 3, y
		finished_erasing_world:
		; Loop back
		inc time_since_tunnel
		jmp end_loop
	
	currently_in_the_end:
	; Handle the ender dragon fight
		; Play the music
		jsr start_playing_music
		; Check if the dragon is already dead
			lda time_since_dragon_died
			bne :+
			jmp the_ender_dragon_hasnt_been_dead
			:
			cmp #$FF
			beq :+
			jmp the_dragon_is_dying
			:
			lda #$07
			sta apu_enable
			lda #$F7
			sta display_buff + 128 + 16 - 3
			lda #$F6
			sta display_buff + 128 + 16 - 2
			lda #$F8
			sta display_buff + 128 + 16 - 1
			lda #$F3
			sta display_buff + 128 + 16
			sta display_buff + 128 + 16 + 1
			lda #$64
			sta display_buff + 128 + 16 + 3
			; Delete the ender dragon
			lda #$FF
			sta $0218
			sta $021C
			sta $0220
			sta $0224
			sta $0228
			sta $022C
			sta $0230
			sta $0234
			sta $0238
			sta $023C
			sta $0240
			sta $0260
			sta $0264
			sta $0268
			sta $026C
			; Sprite 0 for scrolling without the hotbar moving
			; Vertical position
				lda #$8B
				sta $0200
			; Attributes
				lda #$2F
				sta $0201
				lda #$00
				sta $0202
			; Horizontal position
				lda #$04
				clc
				adc end_scroll
				sta $0203
			; Scroll the view of the end dimension
			dec end_scroll
			; Check if the player pressed the a button
			lda #$01
			sta controller
			lda #$00
			sta controller
			lda controller
			and #$01
			beq continue_dragon_death_scroll; The player hasn't pressed a yet
			inc in_end_poem ; If we are here, the player pressed a and we will not display the end poem
			lda #$0A
			sta $2001
			jmp start_end_poem
			the_dragon_is_dying:
			; Draw the purple rays
			lda dragon_y
			adc #$04
			lsr a
			ldx time_since_dragon_died
			cpx #$20
			bcc dont_draw_vertical_ray
			sec
			sbc time_since_dragon_died
			dont_draw_vertical_ray:
			asl a
			asl a
			asl a
			and #$E0
			sta reg_adr
			lda dragon_x
			sbc end_scroll
			adc #$18
			lsr a
			lsr a
			lsr a
			ldx time_since_dragon_died
			cpx #$20
			bcs dont_draw_horizontal_ray
			clc
			adc time_since_dragon_died
			and #$1F
			dont_draw_horizontal_ray:
			clc
			adc reg_adr
			tay
			lda #$3E
			sta display_buff, y
			; Make the egg fall
			lda time_since_dragon_died
			cmp #$40
			bcs dont_move_dragon_egg
			sta $0250
			sta $0254
			clc
			adc #$08
			sta $0258
			sta $025C
			dont_move_dragon_egg:
			; Repeat
			inc time_since_dragon_died
			continue_dragon_death_scroll:
			jmp end_loop
			the_ender_dragon_hasnt_been_dead:
		; Check if the dragon just died
			lda player_energy ; Dragon energy
			beq :+
			jmp didnt_just_kill_the_ender_dragon
			:
			; The dragon's energy is zero
			inc time_since_dragon_died
			; Play the ender dragon death sound
			; Enable channels
				lda #$1B
				sta apu_enable
			; Pulse
				lda #%01010100
				sta $4000
				lda #%10010101
				sta $4004
				lda #%10010110
				sta $4001
				lda #%10010100
				sta $4005
				lda #$F4
				sta $4002
				lda #$F3
				sta $4006
				lda #%00001000
				sta $4003
				sta $4007
			; Noise
				lda #$F3
				sta $400C
				sta $400F
				lda #%00001010
				sta $400E
			; DMC
				lda #$4E
				sta $4010
				lda $00
				sta $4012
				lda #$FF
				sta $4013
			; Draw the dragon egg
			; Egg top-left
				; Vertical position
					lda #$10
					sta $0250
					sta $0254
				; Attributes
					lda #$47
					sta $0251
					lda #$02
					sta $0252
					sta $025A
				; Horizontal position
					lda #$78
					sta $0253
					sta $025B
			; Egg 1 top-right
				; Attributes
					lda #$47
					sta $0255
				; Horizontal position
					lda #$80
					sta $0257
					sta $025F
			; Egg 1 bottom-left
				; Vertical position
					lda #$18
					sta $0258
					sta $025C
				; Attributes
					lda #$48
					sta $0259
					lda #$42
					sta $0256
					sta $025E
			; Egg 1 bottom-right
				; Attributes
					lda #$48
					sta $025D
			; Delete the crosshair
				lda #$FF
				sta $0208
				sta $020C
				sta $0210
				sta $0214
			jmp end_loop
			didnt_just_kill_the_ender_dragon:
		; Poll for controller inputs
			lda #$01
			sta controller
			lda #$00
			sta controller
		; A button
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_a_button_edf
			lda end_paused
			bne done_checking_a_button_edf
			lda item_amounts + 1
			and #$F0
			beq done_checking_a_button_edf
			lda pl
			cmp #$45
			bcc done_checking_a_button_edf
			; We are safe to place a block as the game is paused, the crosshair is on the bottom half of the display area, and we have at least one stone block to place
			sbc #$05
			asl a
			asl a
			and #$E0
			sta reg_adr
			lda end_scroll
			eor #$FF
			sec
			sbc #$78
			lsr a
			lsr a
			lsr a
			clc
			adc reg_adr
			tay
			lda display_buff_middle, y
			bne done_checking_a_button_edf ; There is already a block there, so abort
			lda #$23
			sta display_buff_middle, y
			lda item_amounts + 1
			sec
			sbc #$10
			sta item_amounts + 1
		done_checking_a_button_edf:
		; Get rid of the arrow once its far away
			lda crossbow_cooldown
			cmp #$28
			bne :+
			lda #$FF
			sta crossbow_arrow_y
			:
		; B button
			lda controller
			and #%00000001
			sta reg_adr
			cmp #%00000001
			bne done_checking_b_button_edf
			lda break_pressed
			bne done_checking_b_button_edf
			lda crossbow_cooldown
			bne done_checking_b_button_edf
			lda end_paused
			bne done_checking_b_button_edf
			; Draw the arrow
			lda pl
			sbc #$06
			sta crossbow_arrow_y
			; Set the cooldown
			lda #$30
			sta crossbow_cooldown
			; Check for hits
			ldx end_scroll
			ldy pl
			; Check if we broke the first end crystal
				cpx #$FF - $94
				bcs didnt_break_crystal_1
				cpx #$FF - $9C
				bcc didnt_break_crystal_1
				cpy #$2C
				bcc didnt_break_crystal_1
				cpy #$34
				bcs didnt_break_crystal_1
				lda #$00
				sta crystal_1_exists
				lda #$FF
				sta $0250
				sta $0254
				sta $0258
				sta $025C
			didnt_break_crystal_1:
			; Check if we broke the second end crystal
				cpx #$FF - $64
				bcs didnt_break_crystal_2
				cpx #$FF - $6C
				bcc didnt_break_crystal_2
				cpy #$2C
				bcc didnt_break_crystal_2
				cpy #$34
				bcs didnt_break_crystal_2
				lda #$00
				sta crystal_2_exists
				lda #$FF
				sta $02E0
				sta $02E4
				sta $02E8
				sta $02EC
			didnt_break_crystal_2:
			; Check if we hit the dragon
				ldx dragon_x
				lda pl
				sbc dragon_y
				tay
				cpx #$FF - $8C
				bcs didnt_hit_the_dragon
				cpx #$FF - $9C
				bcc didnt_hit_the_dragon
				cpy #$04
				bcc didnt_hit_the_dragon
				cpy #$14
				bcs didnt_hit_the_dragon
				dec player_energy ; Actually the dragon's energy
				inc player_energy_changed
			didnt_hit_the_dragon:
		done_checking_b_button_edf:
		; Set the previous state of the break button for later use
			lda reg_adr
			sta break_pressed
		; Decrease the crossbow cooldown
			lda crossbow_cooldown
			beq :+ ; The cooldown is already zero, so there is nothing to do
			dec crossbow_cooldown
			:
		; Select button
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_select_button_edf
			lda pressed_up_left_down
			cmp #$03
			bne done_checking_select_button_edf
			lda #$0C
			sta player_energy ; Dragon energy
			inc player_energy_changed
		done_checking_select_button_edf:
		; Start button
			lda controller
			and #%00000001
			tax
			cmp #%00000001
			bne done_checking_start_button_edf
			lda start_pressed
			bne done_checking_start_button_edf
			lda end_paused
			eor #$01 ; Flip bit 0
			sta end_paused
			beq :+
			lda #$03
			sta apu_enable
			; Play the pause sound
			lda $30
			sta jingle_position
			jmp :++
			:
			lda #$0B
			sta apu_enable
			; Configure playback sample rate
			lda #%00000010
			sta $400E
			; Configure length counter load value
			lda #%01001111
			sta $400F
			; Optional: Initialize $400C
			lda #%00100111
			sta $400C
			; Play the pause sound
			lda $30 ; Index of the pause sound
			sta jingle_position
			:
		done_checking_start_button_edf:
		stx start_pressed
		; Check if the game is paused
		lda end_paused
		beq :+
		jmp the_ender_dragon_fight_is_paused
		:
		; D pad up
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_up_edf
			; Move the crosshair up
			lda pl
			cmp #$0D
			bcc done_checking_d_pad_up_edf
			dec pl
		done_checking_d_pad_up_edf:
		; D pad down
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_down_edf
			; Move the crosshair down
			lda pl
			cmp #$84
			bcs done_checking_d_pad_down_edf
			inc pl
		done_checking_d_pad_down_edf:
		; D pad left
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_left_edf
			; Rotate left
			inc dragon_x
			inc dragon_x
			inc dragon_x
			inc end_scroll
			inc end_scroll
			inc end_scroll
			inc dragon_energy_1_x
			inc dragon_energy_2_x
			inc dragon_energy_3_x
			inc dragon_energy_4_x
		done_checking_d_pad_left_edf:
		; D pad right
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_right_edf
			; Rotate right
			dec dragon_x
			dec dragon_x
			dec dragon_x
			dec end_scroll
			dec end_scroll
			dec end_scroll
			dec dragon_energy_1_x
			dec dragon_energy_2_x
			dec dragon_energy_3_x
			dec dragon_energy_4_x
		done_checking_d_pad_right_edf:
		; Draw sprites
		ldx #$02
		; Dragon 1
			; Vertical position
				lda time
				sta  reg_adr ; Divide by 3
				lsr          ;  |
				adc #21      ;  |
				lsr          ;  |
				adc reg_adr  ;  |
				ror          ;  |
				lsr          ;  |
				adc reg_adr  ;  |
				ror          ;  |
				lsr          ;  |
				adc reg_adr  ;  |
				ror          ;  |
				lsr          ;__|__
				clc
				adc dragon_y
				sta $0218
			; Attributes
				lda #$30
				sta $0219
				stx $021A
			; Horizontal position
				lda dragon_x
				sta $021B
		; Dragon 2
			; Vertical position
				lda time
				lsr a
				lsr a
				clc
				adc dragon_y
				clc
				adc #$08
				sta $021C
			; Attributes
				lda #$31
				sta $021D
				stx $021E
			; Horizontal position
				lda dragon_x
				clc
				adc #$06
				sta $021F
		; Dragon 3
			; Vertical position
				lda time
				lsr a
				lsr a
				clc
				adc dragon_y
				sta $0220
			; Attributes
				lda #$32
				sta $0221
				stx $0222
			; Horizontal position
				lda dragon_x
				clc
				adc #$08
				sta $0223
		; Dragon 4
			; Vertical position
				lda dragon_y
				clc
				adc #$09
				sta $0224
			; Attributes
				lda #$33
				sta $0225
				stx $0226
			; Horizontal position
				lda dragon_x
				clc
				adc #$0E
				sta $0227
		; Dragon 5
			; Vertical position
				lda dragon_y
				clc
				adc #$10
				sta $0228
			; Attributes
				lda #$34
				sta $0229
				stx $022A
			; Horizontal position
				lda dragon_x
				clc
				adc #$0B
				sta $022B
		; Dragon 6
			; Vertical position
				lda dragon_y
				clc
				adc #$16
				sta $022C
			; Attributes
				lda #$35
				sta $022D
				stx $022E
			; Horizontal position
				lda dragon_x
				clc
				adc #$10
				sta $022F
		; Dragon 7
			; Vertical position
				lda dragon_y
				clc
				adc #$16
				sta $0230
			; Attributes
				lda #$36
				sta $0231
				stx $0232
			; Horizontal position
				lda dragon_x
				clc
				adc #$18
				sta $0233
		; Dragon 8
			; Vertical position
				lda dragon_y
				clc
				adc #$0E
				sta $0234
			; Attributes
				lda #$37
				sta $0235
				stx $0236
			; Horizontal position
				lda dragon_x
				clc
				adc #$13
				sta $0237
		; Dragon 9
			; Vertical position
				lda dragon_y
				clc
				adc #$0E
				sta $0238
			; Attributes
				lda #$38
				sta $0239
				stx $023A
			; Horizontal position
				lda dragon_x
				clc
				adc #$1B
				sta $023B
		; Dragon 10
			; Vertical position
				lda dragon_y
				clc
				adc #$06
				sta $023C
			; Attributes
				lda #$39
				sta $023D
				stx $023E
			; Horizontal position
				lda dragon_x
				clc
				adc #$16
				sta $023F
		; Dragon 11
			; Vertical position
				lda time
				lsr a
				lsr a
				lsr a
				clc
				adc dragon_y
				clc
				adc #$04
				sta $0240
			; Attributes
				lda #$40
				sta $0241
				stx $0242
			; Horizontal position
				lda dragon_x
				clc
				adc #$1E
				sta $0243
		; Dragon 12
			; Vertical position
				lda $0218 ; Dragon 1's position, which is time / 3
				clc
				adc #$03
				sta $0260
			; Attributes
				lda #$41
				sta $0261
				stx $0262
			; Horizontal position
				lda dragon_x
				clc
				adc #$2C
				sta $0263
		; Dragon 13
			; Vertical position
				lda time
				lsr a
				lsr a
				clc
				adc dragon_y
				clc
				adc #$07
				sta $0264
			; Attributes
				lda #$42
				sta $0265
				stx $0266
			; Horizontal position
				lda dragon_x
				clc
				adc #$25
				sta $0267
		; Dragon 14
			; Vertical position
				lda time
				lsr a
				lsr a
				clc
				adc dragon_y
				clc
				adc #$02
				sta $0268
			; Attributes
				lda #$43
				sta $0269
				stx $026A
			; Horizontal position
				lda dragon_x
				clc
				adc #$25
				sta $026B
		; Dragon 15
			; Vertical position
				lda time
				lsr a
				lsr a
				lsr a
				sta reg_adr
				clc
				adc dragon_y
				clc
				adc #$0A
				sta $026C
			; Attributes
				lda #$61
				sta $026D
				clc
				ror reg_adr
				ror reg_adr
				txa
				adc reg_adr
				sta $026E
			; Horizontal position
				lda dragon_x
				clc
				adc #$23
				sta $026F
		; Cross-bow end top-left
			; Vertical position
				lda #$B4
				sta $02B0
				sta $02B4
			; Attributes
				lda #$4D
				sta $02B1
				lda #$00
				sta $02B2
			; Horizontal position
				lda #$C8
				sta $02B3
				sta $02BB
		; Cross-bow end top-right
			; Attributes
				lda #$4E
				sta $02B5
				lda #$00
				sta $02B6
			; Horizontal position
				lda #$D0
				sta $02B7
				sta $02BF
		; Cross-bow end bottom-left
			; Vertical position
				lda #$BC
				sta $02B8
				sta $02BC
			; Attributes
				lda #$4F
				sta $02B9
				lda #$00
				sta $02BA
		; Cross-bow bottom-right
			; Attributes
				lda #$3F
				sta $02BD
				lda #$00
				sta $02BE
		; Sprite 0
			; Vertical position
				lda #$8B
				sta $0200
			; Attributes
				lda #$2F
				sta $0201
				lda #$00
				sta $0202
			; Horizontal position
				lda #$04
				clc
				adc end_scroll
				sta $0203
		lda crystal_1_exists
		bne :+
		jmp crystal_1_gone
		:
		; Crystal 1 top-left
			; Vertical position
				lda time
				adc #$28
				sta $0250
				sta $0254
			; Attributes
				lda #$2D
				sta $0251
				stx $0252
			; Horizontal position
				lda end_scroll
				adc #$10
				sta $0253
				sta $025B
		; Crystal 1 top-right
			; Attributes
				lda #$2E
				sta $0255
				stx $0256
			; Horizontal position
				lda end_scroll
				adc #$18
				sta $0257
				sta $025F
		; Crystal 1 bottom-left
			; Vertical position
				lda $0250
				adc #$08
				sta $0258
				sta $025C
			; Attributes
				lda #$3D
				sta $0259
				stx $025A
		; Crystal 1 bottom-right
			; Attributes
				lda #$3E
				sta $025D
				stx $025E
		; Spawn dragon energy
		lda scroll_time
		and #$07
		bne crystal_1_gone ; Limit how fast energy is expelled
		lda dragon_x
		adc end_scroll
		cmp #$70 ; Distance between the right wing tip and the edge of the screen
		bcs crystal_1_gone ; See if the dragon is close enough
		; Attempt to spawn dragon energy 1
			lda dragon_energy_1_y
			cmp #$FF
			bne :+
			lda #$14
			adc end_scroll
			sta dragon_energy_1_x
			lda #$2C
			sta dragon_energy_1_y
			jmp crystal_1_gone ; Don't spawn any more
			:
		; Attempt to spawn dragon energy 2
			lda dragon_energy_2_y
			cmp #$FF
			bne :+
			lda #$14
			adc end_scroll
			sta dragon_energy_2_x
			lda #$2C
			sta dragon_energy_2_y
			jmp crystal_1_gone ; Don't spawn any more
			:
		; Attempt to spawn dragon energy 3
			lda dragon_energy_3_y
			cmp #$FF
			bne :+
			lda #$14
			adc end_scroll
			sta dragon_energy_3_x
			lda #$2C
			sta dragon_energy_3_y
			jmp crystal_1_gone ; Don't spawn any more
			:
		; Attempt to spawn dragon energy 4
			lda dragon_energy_4_y
			cmp #$FF
			bne :+
			lda #$14
			adc end_scroll
			sta dragon_energy_4_x
			lda #$2C
			sta dragon_energy_4_y
			jmp crystal_1_gone ; Don't spawn any more
			:
		crystal_1_gone:
		lda crystal_2_exists
		bne :+
		jmp crystal_2_gone
		:
		; Crystal 2 top-left
			; Vertical position
				lda time
				adc #$28
				sta $02E0
				sta $02E4
			; Attributes
				lda #$F9
				sta $02E1
				stx $02E2
			; Horizontal position
				lda end_scroll
				adc #$E0
				sta $02E3
				sta $02EB
		; Crystal 2 top-right
			; Attributes
				lda #$FA
				sta $02E5
				stx $02E6
			; Horizontal position
				lda end_scroll
				clc
				adc #$E8
				sta $02E7
				sta $02EF
		; Crystal 2 bottom-left
			; Vertical position
				lda $02E4
				clc
				adc #$08
				sta $02E8
				sta $02EC
			; Attributes
				lda #$FB
				sta $02E9
				stx $02EA
		; Crystal 2 bottom-right
			; Attributes
				lda #$FC
				sta $02ED
				stx $02EE
		; Spawn dragon energy
		lda scroll_time
		and #$07
		bne crystal_2_gone ; Limit how fast energy is expelled
		lda dragon_x
		adc end_scroll
		cmp #$60 ; Distance between the right wing tip and the edge of the screen
		bcc crystal_2_gone ; See if the dragon is close enough
		; Attempt to spawn dragon energy 1
			lda dragon_energy_1_y
			cmp #$FF
			bne :+
			lda #$E4
			adc end_scroll
			sta dragon_energy_1_x
			lda #$2C
			sta dragon_energy_1_y
			jmp crystal_2_gone ; Don't spawn any more
			:
		; Attempt to spawn dragon energy 2
			lda dragon_energy_2_y
			cmp #$FF
			bne :+
			lda #$E4
			adc end_scroll
			sta dragon_energy_2_x
			lda #$2C
			sta dragon_energy_2_y
			jmp crystal_2_gone ; Don't spawn any more
			:
		; Attempt to spawn dragon energy 3
			lda dragon_energy_3_y
			cmp #$FF
			bne :+
			lda #$E4
			adc end_scroll
			sta dragon_energy_3_x
			lda #$2C
			sta dragon_energy_3_y
			jmp crystal_2_gone ; Don't spawn any more
			:
		; Attempt to spawn dragon energy 4
			lda dragon_energy_4_y
			cmp #$FF
			bne :+
			lda #$E4
			adc end_scroll
			sta dragon_energy_4_x
			lda #$2C
			sta dragon_energy_4_y
			jmp crystal_2_gone ; Don't spawn any more
			:
		crystal_2_gone:
		; Crosshair top-left
			; Vertical position
				lda pl
				sta $0208
				sta $020C
			; Attributes
				lda #$02
				sta $0209
				lda #$01
				sta $020A
			; Horizontal position
				lda #$78
				sta $020B
				sta $0213
		; Crosshair top-right
			; Attributes
				lda #$02
				sta $020D
				lda #$41
				sta $020E
			; Horizontal position
				lda #$80
				sta $020F
				sta $0217
		; Crosshair bottom-left
			; Vertical position
				lda pl
				clc
				adc #$08
				sta $0210
				sta $0214
			; Attributes
				lda #$02
				sta $0211
				lda #$81
				sta $0212
		; Crosshair bottom-right
			; Attributes
				lda #$02
				sta $0215
				lda #$C1
				sta $0216
		; Slot 3 amount (stone for placing)
			; Vertical position
				lda #$D4
				sta $02D8
			; Attributes
				lda item_amounts + 1
				and #$F0
				lsr a
				lsr a
				lsr a
				lsr a
				clc
				adc #$50
				sta $02D9
				lda #$01
				sta $02DA
			; Horizontal position
				lda #$92
				sta $02DB
		; Dragon breath 1
			; Vertical position
				lda $0244
				cmp #$FF
				beq :++
				cmp #$90
				bne :+
				dec player_health
				inc player_health_changed
				; Check if the player died
				lda player_health
				bne :+
				ldx #$00
				stx end_scroll
				sprite_del_loop1:
					lda #$FF
					sta $0200, x
					txa
					clc
					adc #$04
					tax
					bne sprite_del_loop1
				jmp start_repeat
				:
				inc $0244
			; Attributes
				lda scroll_time
				and #$04
				lsr a
				lsr a
				clc
				adc #$44
				sta $0245
				lda #$02
				sta $0246
			; Horizontal position
				lda dragon_x
				clc
				adc #$12
				sta $0247
			; Check if a block was hit
				lda $0244
				cmp #$80
				bcs :+ ; The dragon breath is below the blocks
				cmp #$45
				bcc :+
				sbc #$05
				asl a
				asl a
				and #$E0
				sta reg_adr
				lda $0247
				sec
				sbc end_scroll
				clc
				adc #$08
				lsr a
				lsr a
				lsr a
				clc
				adc reg_adr
				tay
				lda #$00
				cmp display_buff_middle, y
				beq :+
				sta display_buff_middle, y
				lda #$FF
				sta $0244
				:
		; Dragon breath 2
			; Vertical position
				lda $0248
				cmp #$FF
				beq :++
				cmp #$90
				bne :+
				dec player_health
				inc player_health_changed
				; Check if the player died
				lda player_health
				bne :+
				ldx #$00
				stx end_scroll
				sprite_del_loop2:
					lda #$FF
					sta $0200, x
					txa
					clc
					adc #$04
					tax
					bne sprite_del_loop2
				jmp start_repeat
				:
				inc $0248
			; Attributes
				lda scroll_time
				and #$04
				lsr a
				lsr a
				clc
				adc #$44
				sta $0249
				lda #$02
				sta $024A
			; Horizontal position
				lda dragon_x
				clc
				adc #$08
				sta $024B
			; Check if a block was hit
				lda $0248
				cmp #$80
				bcs :+ ; The dragon breath is below the blocks
				cmp #$45
				bcc :+
				sbc #$05
				asl a
				asl a
				and #$E0
				sta reg_adr
				lda $024B
				sec
				sbc end_scroll
				clc
				adc #$08
				lsr a
				lsr a
				lsr a
				clc
				adc reg_adr
				tay
				lda #$00
				cmp display_buff_middle, y
				beq :+
				sta display_buff_middle, y
				lda #$FF
				sta $0248
				:
		; Dragon breath 3
			; Vertical position
				lda $024C
				cmp #$FF
				beq :++
				cmp #$90
				bne :+
				dec player_health
				inc player_health_changed
				; Check if the player died
				lda player_health
				bne :+
				ldx #$00
				stx end_scroll
				sprite_del_loop3:
					lda #$FF
					sta $0200, x
					txa
					clc
					adc #$04
					tax
					bne sprite_del_loop3
				jmp start_repeat
				:
				inc $024C
			; Attributes
				lda scroll_time
				and #$04
				lsr a
				lsr a
				clc
				adc #$44
				sta $024D
				lda #$02
				sta $024E
			; Horizontal position
				lda dragon_x
				clc
				adc #$1C
				sta $024F
			; Check if a block was hit
				lda $024C
				cmp #$80
				bcs :+ ; The dragon breath is below the blocks
				cmp #$45
				bcc :+
				sbc #$05
				asl a
				asl a
				and #$E0
				sta reg_adr
				lda $024F
				sec
				sbc end_scroll
				clc
				adc #$08
				lsr a
				lsr a
				lsr a
				clc
				adc reg_adr
				tay
				lda #$00
				cmp display_buff_middle, y
				beq :+
				sta display_buff_middle, y
				lda #$FF
				sta $024C
				:

		; Move the dragon
			lda scroll_time
			and #$03
			beq :+
			jmp :++
			:
			ldx dragon_time
			lda dragon_x
			clc
			adc dragon_motion_x, x
			sta dragon_x
			lda dragon_y
			clc
			adc dragon_motion_y, x
			sta dragon_y
			:

		; Make the dragon exhale purple fire breath
			lda dragon_y
			cmp #$30
			bcs :+++
			lda fire_breath_time
			cmp #$00
			bne :+
			lda $0244
			cmp #$FF
			bne :+++
			lda dragon_y
			adc #$18
			sta $0244
			jmp :+++
			:
			cmp #$01
			bne :+
			lda $0248
			cmp #$FF
			bne :++
			lda dragon_y
			adc #$18
			sta $0248
			jmp :++
			:
			cmp #$02
			bne :+
			lda $024C
			cmp #$FF
			bne :+
			lda dragon_y
			adc #$18
			sta $024C
			:

		; Move the dragon energy
			; Dragon energy 1
				lda dragon_energy_1_y
				cmp #$A0
				bcs done_moving_dragon_energy_1
				lda #$00
				sta reg_adr
				; Move horizontaly
				lda dragon_x
				adc #$10
				cmp dragon_energy_1_x
				bne :+
				inc reg_adr ;  Set the x positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_1_x":
				inc dragon_energy_1_x
				jmp :++
				:         ; else:
				dec dragon_energy_1_x
				:
				; Move vertically
				lda dragon_y
				adc #$0A
				cmp dragon_energy_1_y
				bne :+
				inc reg_adr ;  Set the y positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_1_y":
				inc dragon_energy_1_y
				jmp :++
				:         ; else:
				dec dragon_energy_1_y
				:
				; Check if its position equals the dragon's position
				lda reg_adr
				cmp #$02 ; Both x and y are equivelant
				bne done_moving_dragon_energy_1
				lda #$FF
				sta dragon_energy_1_y
				lda player_energy ; Dragon energy in this case. Player energy is no longer used in the end
				cmp #$19
				bcs done_moving_dragon_energy_1
				inc player_energy
				inc player_energy_changed
			done_moving_dragon_energy_1:
			; Dragon energy 2
				lda dragon_energy_2_y
				cmp #$A0
				bcs done_moving_dragon_energy_2
				lda #$00
				sta reg_adr
				; Move horizontaly
				lda dragon_x
				adc #$10
				cmp dragon_energy_2_x
				bne :+
				inc reg_adr ;  Set the x positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_2_x":
				inc dragon_energy_2_x
				jmp :++
				:         ; else:
				dec dragon_energy_2_x
				:
				; Move vertically
				lda dragon_y
				adc #$0A
				cmp dragon_energy_2_y
				bne :+
				inc reg_adr ;  Set the y positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_2_y":
				inc dragon_energy_2_y
				jmp :++
				:         ; else:
				dec dragon_energy_2_y
				:
				; Check if its position equals the dragon's position
				lda reg_adr
				cmp #$02 ; Both x and y are equivelant
				bne done_moving_dragon_energy_2
				lda #$FF
				sta dragon_energy_2_y
				lda player_energy ; Dragon energy in this case. Player energy is no longer used in the end
				cmp #$19
				bcs done_moving_dragon_energy_2
				inc player_energy
				inc player_energy_changed
			done_moving_dragon_energy_2:
			; Dragon energy 3
				lda dragon_energy_3_y
				cmp #$A0
				bcs done_moving_dragon_energy_3
				lda #$00
				sta reg_adr
				; Move horizontaly
				lda dragon_x
				adc #$10
				cmp dragon_energy_3_x
				bne :+
				inc reg_adr ;  Set the x positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_3_x":
				inc dragon_energy_3_x
				jmp :++
				:         ; else:
				dec dragon_energy_3_x
				:
				; Move vertically
				lda dragon_y
				adc #$0A
				cmp dragon_energy_3_y
				bne :+
				inc reg_adr ;  Set the y positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_3_y":
				inc dragon_energy_3_y
				jmp :++
				:         ; else:
				dec dragon_energy_3_y
				:
				; Check if its position equals the dragon's position
				lda reg_adr
				cmp #$02 ; Both x and y are equivelant
				bne done_moving_dragon_energy_3
				lda #$FF
				sta dragon_energy_3_y
				lda player_energy ; Dragon energy in this case. Player energy is no longer used in the end
				cmp #$19
				bcs done_moving_dragon_energy_3
				inc player_energy
				inc player_energy_changed
			done_moving_dragon_energy_3:
			; Dragon energy 4
				lda dragon_energy_4_y
				cmp #$A0
				bcs done_moving_dragon_energy_4
				lda #$00
				sta reg_adr
				; Move horizontaly
				lda dragon_x
				adc #$10
				cmp dragon_energy_4_x
				bne :+
				inc reg_adr ;  Set the x positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_4_x":
				inc dragon_energy_4_x
				jmp :++
				:         ; else:
				dec dragon_energy_4_x
				:
				; Move vertically
				lda dragon_y
				adc #$0A
				cmp dragon_energy_4_y
				bne :+
				inc reg_adr ;  Set the y positon to equal
				jmp :+++
				:
				bcc :+    ; if a > "dragon_energy_4_y":
				inc dragon_energy_4_y
				inc dragon_energy_4_y
				jmp :++
				:         ; else:
				dec dragon_energy_4_y
				dec dragon_energy_4_y
				:
				; Check if its position equals the dragon's position
				lda reg_adr
				cmp #$02 ; Both x and y are equivelant
				bne done_moving_dragon_energy_4
				lda #$FF
				sta dragon_energy_4_y
				lda player_energy ; Dragon energy in this case. Player energy is no longer used in the end
				cmp #$19
				bcs done_moving_dragon_energy_4
				inc player_energy
				inc player_energy_changed
			done_moving_dragon_energy_4:

		start_repeat:
		; Repeat
			inc scroll_time
			lda scroll_time
			beq :+
			inc fire_breath_time
			:
			lda scroll_time
			asl a
			asl a
			bne :+
			inc dragon_time
			lda dragon_time
			and #$0F
			sta dragon_time
			:
			lda scroll_time
			lsr a
			and #$0F
			tax
			lda end_crystal_pos, x
			sta time
			; Randomize the dragon breath
			jsr get_rand_0_to_255
			and #$AF
			bne :+
			lda #$00
			sta fire_breath_time
			:
			the_ender_dragon_fight_is_paused:
			jmp end_loop
	
	not_in_the_end:
	; Check if we just got enough energy to go to the end
		lda player_energy
		cmp #$19
		bne :+
		inc in_the_end
		dec inventory_open
		inc inventory_pallete_update
		:
	
	; Check if the game is paused
		lda in_game
		beq game_paused
	
	; Decrement hunger bar
		lda time
		bne :+
		lda player_hunger
		beq out_of_hunger
		dec player_hunger
		inc player_hunger_changed
		lda player_health
		cmp #$14
		bcs :+
		inc player_health
		inc player_health_changed
		jmp :+
		out_of_hunger:
		dec player_health
		inc player_health_changed
		; Make damage sound
		; Configure playback sample rate
		lda #%00000111
		sta $400E
		; Configure length counter load value
		lda #%01011000
		sta $400F
		; Initialize $400C
		lda #%00001110
		sta $400C
		:

	; Check if the player's head is in a block
		; First check if there isn't current damage cooldown
		lda damage_cooldown
		bne done_ckecking_for_suffocation
		; If the player's head is in a block, they will take
		; damage. We need to decrease the "player_health"
		; variable.    Contents of "px"
		ldy px         ; px: XXXX xxxx
		lsr px         ; px: 0XXX Xxxx
		lsr px         ; px: 00XX XXxx
		lsr px         ; px: 000X XXXx
		lsr px         ; px: 0000 XXXX
		lda py         ;  a: YYYY yyyy <-- Contents of "a" register start here
		and #%11110000 ;  a: YYYY 0000
		clc            
		adc px         ;  a: YYYY XXXX
		sty px         ; px: XXXX xxxx
		tay
		lda blocks, y ; This is commented out because beq already checks if the accululator is zero -.
		;cmp #$00 ; Air block <----------------------------------------------------------------------'
		beq done_ckecking_for_suffocation
		lda #$07 ; Time before the damage cooldown runs out
		sta damage_cooldown
		dec player_health ; if we are not in air, but in a solid block, take damage
		inc player_health_changed
		; Make damage sound
		; Configure playback sample rate
		lda #%00000111
		sta $400E
		; Configure length counter load value
		lda #%01011000
		sta $400F
		; Initialize $400C
		lda #%00001110
		sta $400C
		done_ckecking_for_suffocation:

	game_paused:
	; Geting input from controller
		lda #0
		sta pvx
		sta pvy
		; Poll for inputs
			lda #$01
			sta controller
			lda #$00
			sta controller
		; A button
			lda controller
			and #%00000001
			cmp #%00000001
			bne not_pressing_a_button
			; Check if we can interact with the inventory gui or not
			lda in_game
			cmp #$01
			bne not_pressing_a_button
			; If A is pressed, check if we have the meat slot selected
			lda selected_hotbar_slot
			cmp #$00
			bne :+
			; We are trying to eat
			lda item_amounts
			and #$F0
			beq :+ ; We have no food
			; If we do have food, decrease food and add to hunger
			lda item_amounts
			sec
			sbc #$10
			sta item_amounts
			; Make eating sound
			; Configure playback sample rate
			lda #%00000100
			sta $400E
			; Configure length counter load value
			lda #%11111000
			sta $400F
			; Initialize $400C
			lda #%00100010
			sta $400C
			; Set the duration
			lda #$08
			sta eating_sound_time
			:
			; If A is pressed, check if we have the open inventory button selected
			lda selected_hotbar_slot
			cmp #4
			beq :+
			; We will not open/close the inventory
			lda place_pressed
			cmp #0
			bne done_checking_a_button
			lda in_game ; Trick to only trigger button when in game
			sta place_pressed
			jmp done_checking_a_button
			:
			; Check if we are already pressing the open inventory button
			lda #1
			cmp pressing_oib
			beq done_checking_a_button
			; We will open/close the inventory
			inc pressing_oib
			; "a" is already 1
			sec
			sbc inventory_open
			sta inventory_open
			sta inventory_pallete_update ; Tell the NMI to update the inventory pallette
			; Play the open inventory jingle or close inventory jingle based on what we are doing
			; We also will tint the screen if the inventory is open
			ldx #$10 ; Load jingle number 1 (the second jingle)
			;     BGR-----  <---- Bit layout
			ldy #%11100000 ; Screen tint to be darker
			cmp #$01
			beq :+
			ldx #$20 ; Or we load jingle number 2
			ldy #0 ; No screen tint
			:
			stx jingle_position
			sty color_emphasis
			jmp done_checking_a_button
		not_pressing_a_button:
		lda #$00
		sta pressing_oib
		done_checking_a_button:
		; Check if the inventory is open
			lda #$00
			cmp inventory_open
			beq :+
			jsr update_inventory
			jmp in_game_logic_finished
			:
		; B button
			; Get controller input
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_b_button
			; Check if we are selecting the inventory button
			lda #4
			cmp selected_hotbar_slot
			bne :+
			; Check if we have lithium pickaxes
			lda item_amounts + 2
			and #$0F
			bne :+
			dec selected_hotbar_slot
			jmp done_checking_b_button
			:
			; Break blocks
			lda break_pressed
			cmp #0
			bne done_checking_b_button
			lda in_game ; Trick to only trigger button when in game
			sta break_pressed
			jmp done_checking_b_button
		done_checking_b_button:
		; Select button
			lda controller
			and #%00000001
			cmp #%00000001
			bne :+
			; The select button is pressed
			; "a" is already 1
			cmp select_pressed
			beq done_checking_select_button
			sta select_pressed
			; The select button was just pressed
			lda in_game
			cmp #$01
			bne done_checking_select_button
			; If "in_game" is 1, scroll selected hotbar slot
			inc selected_hotbar_slot
			lda selected_hotbar_slot
			cmp #5
			bne done_checking_select_button
			lda #0
			sta selected_hotbar_slot
			jmp done_checking_select_button
			:
			; The select button is not pressed
			lda #$00
			sta select_pressed
		done_checking_select_button:
		; Start button
			; Set strafing to zero and x to zero for later
			ldx #$00
			stx strafing
			lda controller
			and #%00000001
			cmp #%00000001
			bne :++
			; Strafe if start is being pressed
			; "a" is already one
			sta strafing
			; Check if we just pressed it
			cpx start_pressed
			bne done_checking_start_button
			; We will enter the game
			; "a" is alrady one
			cmp in_game
			beq :+
			; We are crrently on the title scren
			sta in_game ; Enter the game
			; Play the enter game jingle
			lda #$00 ; Load jingle number zero
			sta jingle_position
			:
			; We will swap the crosshair position between top and bottom
			lda #$07
			sec
			sbc pl ; pl = 1 - pl
			sta pl
			inx ; Change "x" from zero to one
			:
			stx start_pressed ; Store if start is currently being pressed
		done_checking_start_button:
		; Make sure we can't play the game unless "in_game" is set to 1
			lda in_game
			cmp #$01
			beq :+
			jmp check_for_code ; Secret game code
		:
		; D pad up
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_up
			; Move forward
			lda pdx
			sta pvx
			lda pdy
			sta pvy
		done_checking_d_pad_up:
		; D pad down
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_down
			; Move backward
			lda #0
			sec
			sbc pdx
			sta pvx
			lda #0
			sec
			sbc pdy
			sta pvy
		done_checking_d_pad_down:
		; D pad left
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_left
			; Check if we are strafing
			lda strafing
			cmp #0
			bne strafe_left
			; We aren't strafing
			; Rotate to the left
			lda pa
			sec
			sbc #5
			sta pa
			; Update delta x
			lda pa
			sta trig_input
			jsr get_cos
			lda trig_output
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta pdx
			lda #0
			cmp trig_out_neg
			beq :+
			; A is already zero
			sec
			sbc pdx
			sta pdx
			:
			; Update delta y
			lda pa
			sta trig_input
			jsr get_sin
			lda trig_output
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta pdy
			lda #0
			cmp trig_out_neg
			beq :+
			; A is already zero
			sec
			sbc pdy
			sta pdy
			:
			jmp done_checking_d_pad_left
			strafe_left:
			; We need to strafe to the left
			lda pdy
			sta pvx
			lda #0
			sec
			sbc pdx
			sta pvy
		done_checking_d_pad_left:
		; D pad right
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_d_pad_right
			; Check if we are 
			lda strafing
			cmp #0
			bne strafe_right
			; We aren't strafing
			; Rotate to the right
			lda pa
			sec
			adc #5
			sta pa
			; Update delta x
			lda pa
			sta trig_input
			jsr get_cos
			lda trig_output
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta pdx
			lda #0
			cmp trig_out_neg
			beq :+
			; A is already zero
			sec
			sbc pdx
			sta pdx
			:
			; Update delta y
			lda pa
			sta trig_input
			jsr get_sin
			lda trig_output
			lsr a
			lsr a
			lsr a
			lsr a
			lsr a
			sta pdy
			lda #0
			cmp trig_out_neg
			beq :+
			; A is already zero
			sec
			sbc pdy
			sta pdy
			:
			jmp done_checking_d_pad_right
			strafe_right:
			; We need to strafe to the right
			lda #0
			sec
			sbc pdy
			sta pvx
			lda pdx
			sta pvy
		done_checking_d_pad_right:

	; Move player
		; Make movement sounds
		lda #0  ; We ask if "pvx" is zero. If the
		cmp pvx ; player's x velocity is not zero,
		bne :+  ; we jump to here. _ Else, we check
		cmp pvy                    ; the y velocity.
		beq no_walking_sound       ; If it's zero,
		: ; <----------------------+ We make no sound.
		lda time
		and #$03
		cmp #$00
		bne no_walking_sound
		; Configure playback sample rate
		lda #%00000100
		sta $400E
		; Configure length counter load value
		lda #%11100000
		sta $400F
		; Initialize $400C
		lda #%00000000
		sta $400C
		no_walking_sound:
		; Set starting x
		lda px
		tax
		; Move x
		clc
		adc pvx
		sta px
		; Check collision
		ldy px
		lsr px
		lsr px
		lsr px
		lsr px
		lda py
		and #%11110000
		clc
		adc px
		sty px
		tay
		lda blocks, y
		cmp #$00
		beq :+
		; We colide on x, so move back
		stx px
		:
		; Set starting y
		lda py
		tax
		; Move y
		clc
		adc pvy
		sta py
		; Check collision
		ldy px
		lsr px
		lsr px
		lsr px
		lsr px
		lda py
		and #%11110000
		clc
		adc px
		sty px
		tay
		lda blocks, y
		cmp #$00
		beq :+
		; We colide on x, so move back
		stx py
		:

	; Draw 3D
		lda pa
		sec
		sbc #$20
		sta ray_angle
		lda #$01
		sta line_x
		draw_next_line:
		; Get line height and draw line
		lda ray_angle
		clc
		adc #2
		sta ray_angle
		inc check_top_map
		jsr get_line_height
		jsr display_line_top
		dec check_top_map
		jsr get_line_height
		jsr display_line_bottom
		; Repeat for every ray
		inc line_x
		lda line_x
		cmp #$20
		bcc draw_next_line

	; Update break button
		lda break_pressed
		cmp #1
		bne :+
		lda #0
		sta break_pressed
		:

	; Update place button
		lda place_pressed
		cmp #1
		bne :+
		lda #0
		sta place_pressed
		:
	jmp in_game_logic_finished
	check_for_code:
	; Check for the super-duper secret code
		; D pad up
			lda controller
			and #%00000001
			tay
			cmp #%00000001
			bne done_checking_code_up
			lda just_coded_up
			bne done_checking_code_up
			lda pressed_up_left_down
			cmp #$00
			bne :+
			inc pressed_up_left_down
			jmp done_checking_code_up
			:
			lda #$FF
			sta pressed_up_left_down
		done_checking_code_up:
		sty just_coded_up
		; D pad down
			lda controller
			and #%00000001
			tay
			cmp #%00000001
			bne done_checking_code_down
			lda just_coded_down
			bne done_checking_code_down
			lda pressed_up_left_down
			cmp #$02
			bne :+
			inc pressed_up_left_down
			jmp done_checking_code_down
			:
			lda #$FF
			sta pressed_up_left_down
		done_checking_code_down:
		sty just_coded_down
		; D pad left
			lda controller
			and #%00000001
			tay
			cmp #%00000001
			bne done_checking_code_left
			lda just_coded_left
			bne done_checking_code_left
			lda pressed_up_left_down
			cmp #$01
			bne :+
			inc pressed_up_left_down
			jmp done_checking_code_left
			:
			lda #$FF
			sta pressed_up_left_down
		done_checking_code_left:
		sty just_coded_left
		; D pad right
			lda controller
			and #%00000001
			cmp #%00000001
			bne done_checking_code_right
			lda #$FF
			sta pressed_up_left_down
		done_checking_code_right:
	in_game_logic_finished:
	; Draw sprites
		; Check if we should draw the crosshair or hotbar item selector
			lda #$00
			cmp in_game
			bne :+
			jmp draw_start_button_animations
			:
			cmp inventory_open
			beq :+
			lda #$FF
			sta $0250
			sta $0254
			sta $0258
			sta $025C
			jmp dont_draw_crosshair
			:
		; Selected hotbar slot top-left
			; Vertical position
				lda #$B9
				sta $0204
			; Attributes
				lda #$FF
				sta $0205
				lda #$01
				sta $0206
			; Horizontal position
				lda selected_hotbar_slot
				clc
				ror a
				ror a
				ror a
				ror a
				adc #$3B
				sta $0207
		; Selected hotbar slot bottom-right
			; Vertical position
				lda #$D5
				sta $0200
			; Attributes
				lda #$FF
				sta $0201
				lda #$C1
				sta $0202
			; Horizontal position
				lda selected_hotbar_slot
				clc
				ror a
				ror a
				ror a
				ror a
				adc #$57
				sta $0203
		; Check if we should draw the crosshair
			lda selected_hotbar_slot
			bne :+
			lda #$FF
			sta $0208
			sta $020C
			sta $0210
			sta $0214
			sta $0250
			sta $0254
			sta $0258
			sta $025C
			jmp dont_draw_crosshair
			:
			cmp #$4
			bne :+
			lda item_amounts + 2
			and #$0F
			beq :+
			; Lithium pickaxe top-left
				; Vertical position
					lda #$3F
					clc
					adc pl
					sta $0208
					sta $020C
				; Attributes
					lda #$2C
					sta $0209
					lda #$41
					sta $020A
				; Horizontal position
					lda #$78
					sta $020B
					sta $0213
			; Lithium pickaxe top-right
				; Attributes
					lda #$2B
					sta $020D
					lda #$41
					sta $020E
				; Horizontal position
					lda #$80
					sta $020F
					sta $0217
			; Lithium pickaxe bottom-left
				; Vertical position
					lda #$47
					clc
					adc pl
					sta $0210
					sta $0214
				; Attributes
					lda #$3C
					sta $0211
					lda #$41
					sta $0212
			; Lithium pickaxe bottom-right
				; Attributes
					lda #$3B
					sta $0215
					lda #$41
					sta $0216
			lda #$FF
			sta $0250
			sta $0254
			sta $0258
			sta $025C
			jmp dont_draw_crosshair
			:
		; Crosshair top-left
			; Vertical position
				lda #$3F
				clc
				adc pl
				sta $0208
				sta $020C
			; Attributes
				lda #$02
				sta $0209
				lda #$01
				sta $020A
			; Horizontal position
				lda #$75
				sta $020B
				sta $0213
		; Crosshair top-right
			; Attributes
				lda #$02
				sta $020D
				lda #$41
				sta $020E
			; Horizontal position
				lda #$7D
				sta $020F
				sta $0217
		; Crosshair bottom-left
			; Vertical position
				lda $0208
				clc
				adc #$08
				sta $0210
				sta $0214
			; Attributes
				lda #$02
				sta $0211
				lda #$81
				sta $0212
		; Crosshair bottom-right
			; Attributes
				lda #$02
				sta $0215
				lda #$C1
				sta $0216
		; Help square top-left
			; Vertical position
				lda pl
				asl a
				asl a
				asl a
				adc #$27
				sta $0250
				sta $0254
			; Attributes
				lda #$FD
				sta $0251
				lda #$01
				sta $0252
			; Horizontal position
				lda #$75
				sta $0253
				sta $025B
		; Help square top-right
			; Attributes
				lda #$FD
				sta $0255
				lda #$41
				sta $0256
			; Horizontal position
				lda #$7D
				sta $0257
				sta $025F
		; Help square bottom-left
			; Vertical position
				lda pl
				asl a
				asl a
				asl a
				adc #$2F
				sta $0258
				sta $025C
			; Attributes
				lda #$01
				sta $0259
				lda #$81
				sta $025A
		; Help square bottom-right
			; Attributes
				lda #$01
				sta $025D
				lda #$C1
				sta $025E
		jmp dont_draw_crosshair
		draw_start_button_animations:
			; Press start highlight 1
				; Vertical position
					lda #$68
					sta $0200
				; Attributes
					lda #$68
					sta $0201
					lda day_time
					and #$01
					adc #$01
					sta $0202
				; Horizontal position
					lda #$CE
					sta $0203
			; Press start highlight 2
				; Vertical position
					lda #$7E
					sta $0204
				; Attributes
					lda #$69
					sta $0205
					lda day_time
					and #$01
					adc #$03
					sta $0206
				; Horizontal position
					lda #$CE
					sta $0207
			; Press start highlight 3
				; Vertical position
					lda #$68
					sta $0208
				; Attributes
					lda #$6A
					sta $0209
					lda day_time
					and #$01
					adc #$01
					sta $020A
				; Horizontal position
					lda #$F4
					sta $020B
			; Press start highlight 4
				; Vertical position
					lda #$7E
					sta $020C
				; Attributes
					lda #$6B
					sta $020D
					lda day_time
					and #$01
					sta $020E
				; Horizontal position
					lda #$F4
					sta $020F
			; Press start highlight 5
				; Vertical position
					lda #$69
					sta $0210
				; Attributes
					lda #$6C
					sta $0211
					lda day_time
					lda #$02
					sta $0212
				; Horizontal position
					lda day_time
					and #$07
					asl a
					adc #$D9
					sta $0213
			; Press start highlight 6
				; Vertical position
					lda day_time_inc_wait
					lsr a
					lsr a
					lsr a
					lsr a
					lsr a
					lsr a
					adc #$7C
					sta $0214
				; Attributes
					lda #$6D
					sta $0215
					lda #$00
					sta $0216
				; Horizontal position
					lda day_time_inc_wait
					lsr a
					lsr a
					sta reg_adr
					lda #$FC
					sbc reg_adr
					sta $0217
		dont_draw_crosshair:
		; Small cloud 1 left
			; Vertical position
				lda #$37
				sta $0218
				sta $021C
			; Attributes
				lda #$09
				sta $0219
				lda #$22
				sta $021A
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$00
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $021B
		; Small cloud 1 right
			; Attributes
				lda #$0A
				sta $021D
				lda #$22
				sta $021E
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$08
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $021F
		; Small cloud 2 left
			; Vertical position
				lda #$2D
				sta $0220
				sta $0224
			; Attributes
				lda #$0A
				sta $0221
				lda #$62
				sta $0222
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$C3
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $0223
		; Small cloud 2 right
			; Attributes
				lda #$09
				sta $0225
				lda #$62
				sta $0226
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$CB
				sec
				sbc reg_adr
				sec
				sbc day_time
				sec
				sbc day_count
				sta $0227
		; Big cloud top-left-left
			; Vertical position
				lda #$10
				sta $0228
				sta $022C
				sta $0238
				sta $023C
				sta $0248
			; Attributes
				lda #$04
				sta $0229
				lda #$22
				sta $022A
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$41
				sec
				sbc reg_adr
				ldy day_time
				sty reg_adr
				asl reg_adr
				sec
				sbc reg_adr
				ldy day_count
				sty reg_adr
				asl reg_adr
				asl reg_adr
				clc
				adc reg_adr
				sta $022B
				sta $0233
		; Big cloud top-left
			; Attributes
				lda #$05
				sta $022D
				lda #$22
				sta $022E
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$49
				sec
				sbc reg_adr
				ldy day_time
				sty reg_adr
				asl reg_adr
				sec
				sbc reg_adr
				ldy day_count
				sty reg_adr
				asl reg_adr
				asl reg_adr
				clc
				adc reg_adr
				sta $022F
				sta $0237
		; Big cloud bottom-left-left
			; Vertical position
				lda #$18
				sta $0230
				sta $0234
				sta $0240
				sta $0244
				sta $024C
			; Attributes
				lda #$14
				sta $0231
				lda #$22
				sta $0232
		; Big cloud bottom-left
			; Attributes
				lda #$15
				sta $0235
				lda #$22
				sta $0236
		; Big cloud top-center
			; Attributes
				lda #$06
				sta $0239
				lda #$22
				sta $023A
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$51
				sec
				sbc reg_adr
				ldy day_time
				sty reg_adr
				asl reg_adr
				sec
				sbc reg_adr
				ldy day_count
				sty reg_adr
				asl reg_adr
				asl reg_adr
				clc
				adc reg_adr
				sta $023B
				sta $0243
		; Big cloud top-right
			; Attributes
				lda #$07
				sta $023D
				lda #$22
				sta $023E
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$59
				sec
				sbc reg_adr
				ldy day_time
				sty reg_adr
				asl reg_adr
				sec
				sbc reg_adr
				ldy day_count
				sty reg_adr
				asl reg_adr
				asl reg_adr
				clc
				adc reg_adr
				sta $023F
				sta $0247
		; Big cloud bottom-center
			; Attributes
				lda #$16
				sta $0241
				lda #$22
				sta $0242
		; Big cloud bottom-right
			; Attributes
				lda #$17
				sta $0245
				lda #$22
				sta $0246
		; Big cloud top-right-right
			; Attributes
				lda #$08
				sta $0249
				lda #$22
				sta $024A
			; Horizontal position
				lda pa
				asl a
				asl a
				sta reg_adr
				lda #$61
				sec
				sbc reg_adr
				ldy day_time
				sty reg_adr
				asl reg_adr
				sec
				sbc reg_adr
				ldy day_count
				sty reg_adr
				asl reg_adr
				asl reg_adr
				clc
				adc reg_adr
				sta $024B
				sta $024F
		; Big cloud bottom-right-right
			; Attributes
				lda #$18
				sta $024D
				lda #$22
				sta $024E
		
		; If the inventory is open, don't draw the sun
			lda #$01
			cmp inventory_open
			bne :+
			cmp in_game
			bne dont_draw_sun
			jmp inventory_open_sprites
			:
		; Check if the sun is rising or setting
			lda day_time
			cmp #$60
			bcc :+
			jmp rising_sun_alias
			:
		; The sun is setting in the west
		; Check if the sun is in view
			lda day_time
			lsr a
			lsr a
			lsr a
			sta reg_adr
			lda pa
			sec
			sbc reg_adr
			cmp #$62
			bcs :+
			jmp  dont_draw_sun
			:
			lda pa
			clc
			adc #$5E
			cmp #$8E
			bcc :+
			jmp sun_in_view1
			:
		; The sun isn't in view
			dont_draw_sun:
			lda #$FF
			sta $0260
			sta $0264
			sta $0268
			sta $026C
		jmp sun_not_in_view
		inventory_open_sprites:
		lda day_time_inc_wait
		cmp #$00
		bne :+
		jmp flash_the_stage_text
		:
		lda game_progress
		cmp #$00
		bne :+
		jmp flash_the_stage_text
		:
		; Stage text 1
			; Vertical position
				lda #$44
				sta $0260
			; Attributes
				lda #$4A
				sta $0261
				lda #$01
				sta $0262
			; Horizontal position
				lda #$30
				sta $0263
		lda game_progress
		cmp #$02
		bcs :+
		; Stage text 2
			; Vertical position
				lda #$44
				sta $0264
			; Attributes
				lda #$73
				sta $0265
				lda #$01
				sta $0266
			; Horizontal position
				lda #$38
				sta $0267
		; Stage text 3
			; Vertical position
				lda #$44
				sta $0268
			; Attributes
				lda #$74
				sta $0269
				lda #$01
				sta $026A
			; Horizontal position
				lda #$40
				sta $026B
		; Stage text 4
			; Vertical position
				lda #$44
				sta $026C
			; Attributes
				lda #$75
				sta $026D
				lda #$01
				sta $026E
			; Horizontal position
				lda #$48
				sta $026F
		; Stage text 5
			; Vertical position
				lda #$44
				sta $0200
			; Attributes
				lda #$76
				sta $0201
				lda #$01
				sta $0202
			; Horizontal position
				lda #$50
				sta $0203
		; Stage text 6
			; Vertical position
				lda #$44
				sta $0204
			; Attributes
				lda #$77
				sta $0205
				lda #$01
				sta $0206
			; Horizontal position
				lda #$58
				sta $0207
		; Stage text 7
			; Vertical position
				lda #$44
				sta $0208
			; Attributes
				lda #$78
				sta $0209
				lda #$01
				sta $020A
			; Horizontal position
				lda #$60
				sta $020B
		jmp sun_not_in_view
		:
		bne :+
		; Stage text 2
			; Vertical position
				lda #$44
				sta $0264
			; Attributes
				lda #$4B
				sta $0265
				lda #$01
				sta $0266
			; Horizontal position
				lda #$38
				sta $0267
		; Stage text 3
			; Vertical position
				lda #$44
				sta $0268
			; Attributes
				lda #$4C
				sta $0269
				lda #$01
				sta $026A
			; Horizontal position
				lda #$40
				sta $026B
		; Stage text 4
			; Vertical position
				lda #$44
				sta $026C
			; Attributes
				lda #$60
				sta $026D
				lda #$01
				sta $026E
			; Horizontal position
				lda #$48
				sta $026F
		; Stage text 5
			; Vertical position
				lda #$44
				sta $0200
			; Attributes
				lda #$6E
				sta $0201
				lda #$01
				sta $0202
			; Horizontal position
				lda #$50
				sta $0203
		; Stage text 6
			; Vertical position
				lda #$44
				sta $0204
			; Attributes
				lda #$6F
				sta $0205
				lda #$01
				sta $0206
			; Horizontal position
				lda #$58
				sta $0207
		; Stage text 7
			; Vertical position
				lda #$44
				sta $0208
			; Attributes
				lda #$7A
				sta $0209
				lda #$01
				sta $020A
			; Horizontal position
				lda #$60
				sta $020B
		jmp sun_not_in_view
		:
		; Stage text 2
			; Vertical position
				lda #$44
				sta $0264
			; Attributes
				lda #$4B
				sta $0265
				lda #$01
				sta $0266
			; Horizontal position
				lda #$38
				sta $0267
		; Stage text 3
			; Vertical position
				lda #$44
				sta $0268
			; Attributes
				lda #$4C
				sta $0269
				lda #$01
				sta $026A
			; Horizontal position
				lda #$40
				sta $026B
		; Stage text 4
			; Vertical position
				lda #$44
				sta $026C
			; Attributes
				lda #$3A
				sta $026D
				lda #$01
				sta $026E
			; Horizontal position
				lda #$48
				sta $026F
		; Stage text 5
			; Vertical position
				lda #$44
				sta $0200
			; Attributes
				lda #$70
				sta $0201
				lda #$01
				sta $0202
			; Horizontal position
				lda #$50
				sta $0203
		; Stage text 6
			; Vertical position
				lda #$44
				sta $0204
			; Attributes
				lda #$71
				sta $0205
				lda #$01
				sta $0206
			; Horizontal position
				lda #$58
				sta $0207
		; Stage text 7
			; Vertical position
				lda #$44
				sta $0208
			; Attributes
				lda #$72
				sta $0209
				lda #$01
				sta $020A
			; Horizontal position
				lda #$60
				sta $020B
		jmp sun_not_in_view
		flash_the_stage_text:
			lda #$FF
			sta $0260
			sta $0264
			sta $0268
			sta $026C
			sta $0200
			sta $0204
			sta $0208
		jmp sun_not_in_view
		sun_in_view1:
		; Sun top-left
			; Vertical position
				lda day_time
				sta $0260
			; Attributes
				lda #$03
				sta $0261
				lda #$22
				sta $0262
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				sec
				sbc reg_adr
				sta reg_adr
				lda #$7C
				sbc reg_adr
				sta $0263
		jmp :+
		rising_sun_alias:
		jmp rising_sun
		:
		; Sun top-right
			; Vertical position
				lda day_time
				sta $0264
			; Attributes
				lda #$28
				sta $0265
				lda #$22
				sta $0266
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				sec
				sbc reg_adr
				sta reg_adr
				lda #$84
				sbc reg_adr
				sta $0267
		; Sun bottom-left
			; Vertical position
				lda day_time
				clc
				adc #$08
				sta $0268
			; Attributes
				lda #$0F
				sta $0269
				lda #$22
				sta $026A
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				sec
				sbc reg_adr
				sta reg_adr
				lda #$7C
				sbc reg_adr
				sta $026B
		; Sun bottom-right
			; Vertical position
				lda day_time
				clc
				adc #$08
				sta $026C
			; Attributes
				lda #$1F
				sta $026D
				lda #$22
				sta $026E
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				sec
				sbc reg_adr
				sta reg_adr
				lda #$84
				sbc reg_adr
				sta $026F
		jmp sun_not_in_view
		rising_sun:
		; The sun is rising in the east
		; Check if the sun is in view
			lda day_time
			lsr a
			lsr a
			lsr a
			sta reg_adr
			lda pa
			clc
			adc #$1E
			clc
			adc reg_adr
			cmp #$3E
			bcs :+
			lda day_time
			clc
			adc #$20
			cmp #$20
			bcs sun_in_view2
			:
		; The sun isn't in view
			lda #$FF
			sta $0260
			sta $0263
			sta $0264
			sta $0267
			sta $0268
			sta $026B
			sta $026C
			sta $026F
		jmp sun_not_in_view
		sun_in_view2:
		; Sun top-left
			; Vertical position
				lda #$C0
				sec
				sbc day_time
				sta $0260
			; Attributes
				lda #$03
				sta $0261
				lda #$22
				sta $0262
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				clc
				adc reg_adr
				sta reg_adr
				lda #$7C
				sec
				sbc reg_adr
				sta $0263
		; Sun top-right
			; Vertical position
				lda #$C0
				sec
				sbc day_time
				sta $0264
			; Attributes
				lda #$28
				sta $0265
				lda #$22
				sta $0266
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				clc
				adc reg_adr
				sta reg_adr
				lda #$84
				sec
				sbc reg_adr
				sta $0267
		; Sun bottom-left
			; Vertical position
				lda #$C8
				sec
				sbc day_time
				sta $0268
			; Attributes
				lda #$0F
				sta $0269
				lda #$22
				sta $026A
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				clc
				adc reg_adr
				sta reg_adr
				lda #$7C
				sec
				sbc reg_adr
				sta $026B
		; Sun bottom-right
			; Vertical position
				lda #$C8
				sec
				sbc day_time
				sta $026C
			; Attributes
				lda #$1F
				sta $026D
				lda #$22
				sta $026E
			; Horizontal position
				lda day_time
				lsr a
				sta reg_adr
				lda pa
				asl a
				asl a
				clc
				adc reg_adr
				sta reg_adr
				lda #$84
				sbc reg_adr
				sta $026F
		sun_not_in_view:
		; Check if we are in the game to know if we should render the hotbar items
			ldx in_game
			cpx #$00
			bne :+
			jmp dont_render_more_sprites
			:
		; Slot 1 contents top-left
			; Vertical position
				lda #$C4
				sta $0270
			; Attributes
				lda #$0B
				sta $0271
				lda #$00
				sta $0272
			; Horizontal position
				lda #$45
				sta $0273
		; Slot 1 contents top-right
			; Vertical position
				lda #$C4
				sta $0274
			; Attributes
				lda #$0C
				sta $0275
				lda #$00
				sta $0276
			; Horizontal position
				lda #$4D
				sta $0277
		; Slot 1 contents bottom-left
			; Vertical position
				lda #$CC
				sta $0278
			; Attributes
				lda #$1B
				sta $0279
				lda #$00
				sta $027A
			; Horizontal position
				lda #$45
				sta $027B
		; Slot 1 contents bottom-right
			; Vertical position
				lda #$CC
				sta $027C
			; Attributes
				lda #$1C
				sta $027D
				lda #$00
				sta $027E
			; Horizontal position
				lda #$4D
				sta $027F
		; Slot 2 contents top-left
			; Vertical position
				lda #$C4
				sta $0280
			; Attributes
				lda #$0D
				sta $0281
				lda #$00
				sta $0282
			; Horizontal position
				lda #$65
				sta $0283
		; Slot 2 contents top-right
			; Vertical position
				lda #$C4
				sta $0284
			; Attributes
				lda #$0E
				sta $0285
				lda #$00
				sta $0286
			; Horizontal position
				lda #$6D
				sta $0287
		; Slot 2 contents bottom-left
			; Vertical position
				lda #$CC
				sta $0288
			; Attributes
				lda #$1D
				sta $0289
				lda #$00
				sta $028A
			; Horizontal position
				lda #$65
				sta $028B
		; Slot 2 contents bottom-right
			; Vertical position
				lda #$CC
				sta $028C
			; Attributes
				lda #$1E
				sta $028D
				lda #$00
				sta $028E
			; Horizontal position
				lda #$6D
				sta $028F
		; Slot 3 contents top-left
			; Vertical position
				lda #$C4
				sta $0290
			; Attributes
				lda #$12
				sta $0291
				lda #$00
				sta $0292
			; Horizontal position
				lda #$85
				sta $0293
		; Slot 3 contents top-right
			; Vertical position
				lda #$C4
				sta $0294
			; Attributes
				lda #$13
				sta $0295
				lda #$00
				sta $0296
			; Horizontal position
				lda #$8D
				sta $0297
		; Slot 3 contents bottom-left
			; Vertical position
				lda #$CC
				sta $0298
			; Attributes
				lda #$22
				sta $0299
				lda #$00
				sta $029A
			; Horizontal position
				lda #$85
				sta $029B
		; Slot 3 contents bottom-right
			; Vertical position
				lda #$CC
				sta $029C
			; Attributes
				lda #$23
				sta $029D
				lda #$00
				sta $029E
			; Horizontal position
				lda #$8D
				sta $029F
		; Slot 4 contents top-left
			; Vertical position
				lda #$C4
				sta $02A0
			; Attributes
				lda #$19
				sta $02A1
				lda #$00
				sta $02A2
			; Horizontal position
				lda #$A5
				sta $02A3
		; Slot 4 contents top-right
			; Vertical position
				lda #$C4
				sta $02A4
			; Attributes
				lda #$1A
				sta $02A5
				lda #$00
				sta $02A6
			; Horizontal position
				lda #$AD
				sta $02A7
		; Slot 4 contents bottom-left
			; Vertical position
				lda #$CC
				sta $02A8
			; Attributes
				lda #$29
				sta $02A9
				lda #$00
				sta $02AA
			; Horizontal position
				lda #$A5
				sta $02AB
		; Slot 4 contents bottom-right
			; Vertical position
				lda #$CC
				sta $02AC
			; Attributes
				lda #$2A
				sta $02AD
				lda #$00
				sta $02AE
			; Horizontal position
				lda #$AD
				sta $02AF
		; Backpack top-left
			; Vertical position
				lda #$B4
				sta $02B0
			; Attributes
				lda #$10
				sta $02B1
				lda #$00
				sta $02B2
			; Horizontal position
				lda #$C9
				sta $02B3
		; Backpack top-right
			; Vertical position
				lda #$B4
				sta $02B4
			; Attributes
				lda #$11
				sta $02B5
				lda #$00
				sta $02B6
			; Horizontal position
				lda #$D1
				sta $02B7
		; Backpack bottom-left
			; Vertical position
				lda #$BC
				sta $02B8
			; Attributes
				lda #$20
				sta $02B9
				lda #$00
				sta $02BA
			; Horizontal position
				lda #$C9
				sta $02BB
		; Backpack bottom-right
			; Vertical position
				lda #$BC
				sta $02BC
			; Attributes
				lda #$21
				sta $02BD
				lda #$00
				sta $02BE
			; Horizontal position
				lda #$D1
				sta $02BF
		; Version text left-left
			; Vertical position
				lda #$80
				sta $02C0
				sta $02C4
				sta $02C8
				sta $02CC
			; Attributes
				lda #$24
				sta $02C1
				lda #$01
				sta $02C2
			; Horizontal position
				lda #$D4
				sta $02C3
		; Version text center-left
			; Attributes
				lda #$25
				sta $02C5
				lda #$01
				sta $02C6
			; Horizontal position
				lda #$DC
				sta $02C7
		; Version text center-right
			; Attributes
				lda #$26
				sta $02C9
				lda #$01
				sta $02CA
			; Horizontal position
				lda #$E4
				sta $02CB
		; Version text right-right
			; Attributes
				lda #$27
				sta $02CD
				lda #$01
				sta $02CE
			; Horizontal position
				lda #$EC
				sta $02CF
		; Slot 1 amount
			; Vertical position
				lda #$D4
				sta $02D0
			; Attributes
				lda item_amounts
				and #$F0
				lsr a
				lsr a
				lsr a
				lsr a
				clc
				adc #$50
				sta $02D1
				lda #$01
				sta $02D2
			; Horizontal position
				lda #$4F
				sta $02D3
		; Slot 2 amount
			; Vertical position
				lda #$D4
				sta $02D4
			; Attributes
				lda item_amounts
				and #$0F
				clc
				adc #$50
				sta $02D5
				lda #$01
				sta $02D6
			; Horizontal position
				lda #$6F
				sta $02D7
		; Slot 3 amount
			; Vertical position
				lda #$D4
				sta $02D8
			; Attributes
				lda item_amounts + 1
				and #$F0
				lsr a
				lsr a
				lsr a
				lsr a
				clc
				adc #$50
				sta $02D9
				lda #$01
				sta $02DA
			; Horizontal position
				lda #$8F
				sta $02DB
		; Slot 4 amount
			; Vertical position
				lda #$D4
				sta $02DC
			; Attributes
				lda item_amounts + 1
				and #$0F
				clc
				adc #$50
				sta $02DD
				lda #$01
				sta $02DE
			; Horizontal position
				lda #$AF
				sta $02DF
		finished_rendering_hotbar_items:
		; Check if we need to draw the inventory slots
			lda inventory_open
			cmp #$00
			bne :+
			jmp dont_draw_inventory_slots
			:
		; Inventory slot 1 top-left
			; Vertical position
				lda #$53
				sta $02E0
			; Attributes
				lda #$12
				sta $02E1
				lda #$01
				sta $02E2
			; Horizontal position
				lda #$79
				sta $02E3
		; Inventory slot 1 top-right
			; Vertical position
				lda #$53
				sta $02E4
			; Attributes
				lda #$13
				sta $02E5
				lda #$01
				sta $02E6
			; Horizontal position
				lda #$81
				sta $02E7
		; Inventory slot 1 bottom-left
			; Vertical position
				lda #$5B
				sta $02E8
			; Attributes
				lda #$22
				sta $02E9
				lda #$01
				sta $02EA
			; Horizontal position
				lda #$79
				sta $02EB
		; Inventory slot 1 amount
			; Vertical position
				lda #$5B
				sta $02EC
			; Attributes
				lda item_amounts + 2
				and #$F0
				lsr a
				lsr a
				lsr a
				lsr a
				clc
				adc #$50
				sta $02ED
				lda #$01
				sta $02EE
			; Horizontal position
				lda #$81
				sta $02EF
		; Inventory slot 2 top-left
			; Vertical position
				lda #$53
				sta $02F0
			; Attributes
				lda #$2B
				sta $02F1
				lda #$01
				sta $02F2
			; Horizontal position
				lda #$91
				sta $02F3
		; Inventory slot 2 top-right
			; Vertical position
				lda #$53
				sta $02F4
			; Attributes
				lda #$2C
				sta $02F5
				lda #$01
				sta $02F6
			; Horizontal position
				lda #$99
				sta $02F7
		; Inventory slot 2 bottom-left
			; Vertical position
				lda #$5B
				sta $02F8
			; Attributes
				lda #$3B
				sta $02F9
				lda #$01
				sta $02FA
			; Horizontal position
				lda #$91
				sta $02FB
		; Inventory slot 2 amount
			; Vertical position
				lda #$5B
				sta $02FC
			; Attributes
				lda item_amounts + 2
				and #$0F
				clc
				adc #$50
				sta $02FD
				lda #$01
				sta $02FE
			; Horizontal position
				lda #$99
				sta $02FF
		jmp done_drawing_inventory_slots
		dont_draw_inventory_slots:
			lda #$FF
			sta $02E0
			sta $02E3
			sta $02E4
			sta $02E7
			sta $02E8
			sta $02EB
			sta $02EC
			sta $02EF
			sta $02F0
			sta $02F3
			sta $02F4
			sta $02F7
			sta $02F8
			sta $02FB
			sta $02FC
			sta $02FF
		done_drawing_inventory_slots:
		jmp :+
		dont_render_more_sprites:
		lda #$70
		clc
		clear_sprites_loop:
			tax
			lda #$FF
			sta $0200, x
			txa
			adc #$04
			bcc clear_sprites_loop
		:
	; Draw music and sound enable sprites
		lda sound_change_animation_time
		cmp #$00
		bne :+
		jmp dont_draw_sound_sprites
		:
		asl a
		asl a
		asl a
		asl a
		sta trig_input
		jsr get_sin
		lda trig_output
		lsr a
		lsr a
		lsr a
		sta reg_adr
		ldx last_sound_change
		cpx #$02
		bcs :+
		; Draw sprite 1 for enableing music
			; Vertical position
				lda #$40
				sec
				sbc reg_adr
				sta $020C
			; Attributes
				lda #$79
				sta $020D
				lda #$01
				sta $020E
			; Horizontal position
				lda #$B0
				sta $020F
		; Draw sprite 2 for enableing music
			; Vertical position
				lda #$40
				sec
				sbc reg_adr
				sta $0210
			; Attributes
				lda #$66
				sta $0211
				lda #$01
				sta $0212
			; Horizontal position
				lda #$B8
				sta $0213
		; Draw sprite 3 for enableing music
			; Vertical position
				lda #$40
				sec
				sbc reg_adr
				sta $0214
			; Attributes
				lda #$67
				sta $0215
				lda #$01
				sta $0216
			; Horizontal position
				lda #$C0
				sta $0217
		; Draw sprite 4 for enableing music
			; Vertical position
				lda #$40
				sec
				sbc reg_adr
				sta $0250
			; Attributes
				lda last_sound_change
				and #$01
				clc
				adc #$64
				sta $0251
				lda #$01
				sta $0252
			; Horizontal position
				lda #$C8
				sta $0253
		dec sound_change_animation_time
		jmp dont_draw_sound_sprites
		:
		; Draw sprite 1 for enableing music
			; Vertical position
				lda #$50
				sec
				sbc reg_adr
				sta $020C
			; Attributes
				lda #$62
				sta $020D
				lda #$01
				sta $020E
			; Horizontal position
				lda #$B8
				sta $020F
		; Draw sprite 2 for enableing music
			; Vertical position
				lda #$50
				sec
				sbc reg_adr
				sta $0210
			; Attributes
				lda #$63
				sta $0211
				lda #$01
				sta $0212
			; Horizontal position
				lda #$C0
				sta $0213
		; Draw sprite 3 for enableing music
			; Vertical position
				lda #$50
				sec
				sbc reg_adr
				sta $0214
			; Attributes
				lda last_sound_change
				and #$01
				clc
				adc #$64
				sta $0215
				lda #$01
				sta $0216
			; Horizontal position
				lda #$C8
				sta $0217
		dec sound_change_animation_time
		dont_draw_sound_sprites:

	; Randomly start background music
		lda bg_music_position
		cmp #$00
		bne dont_start_bg_music
		lda bg_music_page
		cmp #$03
		bne dont_start_bg_music
		; There isn't any background music plaing right now
		lda time
		cmp #$36
		bne dont_start_bg_music
		lda #$FF
		sta bg_music_position
		sta bg_music_page
		dont_start_bg_music:

	start_playing_music:
	; Play jingles
		lda jingle_position
		cmp #$BF ; Middle of the lithium pickaxe breaking sound
		beq skip_checking_for_jingle_end
		and #$0F
		cmp #$0F
		beq done_playing_current_jingle
		ldx jingle_position
		lda jingles, x
		cmp prev_jingle_note
		beq :+
		jmp didnt_skip_checking_for_jingle_end
		skip_checking_for_jingle_end:
		ldx jingle_position
		lda jingles, x
		didnt_skip_checking_for_jingle_end:
		sta $4002
		sta prev_jingle_note
		lda #%11000011
		sta $4000
		lda #%00001000
		sta $4001
		lda #%11111000
		sta $4003
		:
		inc jingle_position
		done_playing_current_jingle:

	; Check if we just died
		lda time_since_died
		cmp #$01
		bne :+
		; Clear apu addresses so we stop playing the background music and sound effects
		lda #$00
		sta $4000
		sta $4001
		sta $4002
		sta $4003
		sta $4004
		sta $4005
		sta $4006
		sta $4007
		sta $4008
		sta $400A
		sta $400B
		lda #$80
		sta jingle_position
		lda #$00
		sta inventory_open
		:
	
	; Check if we are dead
		lda player_health
		beq :+
		jmp not_dead_yet
		:
		; Our health is zero
		lda time_since_died
		cmp #$30
		beq done_with_death_animation
		cmp #$08
		bcs play_death_music
		; Move Backward
		lda px
		sec
		sbc pdx
		sta px
		lda py
		sec
		sbc pdy
		sta py
		; Redraw the screen
		lda pa
		sec
		sbc #$20
		sta ray_angle
		lda #$01
		sta line_x
		draw_next_line_dead:
		; Get line height and draw line
		lda ray_angle
		clc
		adc #2
		sta ray_angle
		inc check_top_map
		jsr get_line_height
		jsr display_line_top
		dec check_top_map
		jsr get_line_height
		jsr display_line_bottom
		; Repeat for every ray
		inc line_x
		lda line_x
		cmp #$20
		bcc draw_next_line_dead
		; Play death music
		play_death_music:
		ldx jingle_position
		lda jingles, x
		cmp prev_jingle_note
		beq :+
		sta $4002
		sta prev_jingle_note
		lda #%11000011
		sta $4000
		lda #%00001000
		sta $4001
		lda #%11111000
		sta $4003
		:
		; Loop back
		inc jingle_position
		inc time_since_died
		done_with_death_animation:
		; Check for controller input
		lda #$01
		sta controller
		lda #$00
		sta controller
		lda controller ; Skip button A
		lda controller ; Skip button B
		lda controller ; Check for start
		and #%00000001
		bne reset_the_game
		lda controller ; Check for select
		and #%00000001
		bne reset_the_game
		jmp didnt_press_restart_on_controller
		reset_the_game:
		jmp reset
		didnt_press_restart_on_controller:
		; Draw the game over text
		; Char 1
			; Vertical position
				lda #$38
				sta $02E0
			; Attributes
				lda #$7B
				sta $02E1
				lda #$01
				sta $02E2
			; Horizontal position
				lda #$70
				sta $02E3
		; Char 2
			; Vertical position
				lda #$38
				sta $02E4
			; Attributes
				lda #$7C
				sta $02E5
				lda #$01
				sta $02E6
			; Horizontal position
				lda #$78
				sta $02E7
		; Char 3
			; Vertical position
				lda #$38
				sta $0208
			; Attributes
				lda #$7D
				sta $0209
				lda #$01
				sta $020A
			; Horizontal position
				lda #$80
				sta $020B
		; Char 4
			; Vertical position
				lda #$38
				sta $020C
			; Attributes
				lda #$7E
				sta $020D
				lda #$01
				sta $020E
			; Horizontal position
				lda #$88
				sta $020F
		; Char 5
			; Vertical position
				jsr get_rand_0_to_3
				lda #$38
				clc
				adc rand_out
				sta $0210
			; Attributes
				lda #$7F
				sta $0211
				lda #$01
				sta $0212
			; Horizontal position
				lda #$90
				sta $0213
		; Bottom swoop
			; Vertical position
				lda #$40
				sta $0214
			; Attributes
				lda #$FE
				sta $0215
				lda #$01
				sta $0216
			; Horizontal position
				lda #$70
				sta $02F7
		; Repeat
		jmp loop
		not_dead_yet:
	
	; Jump back to the end if that's where we are sup post to be
		lda time_since_tunnel
		beq :+
		rts
		:
	
	; Play background music
		lda time
		sec
		mod_3_loop:
    	sbc #3
    	bcs mod_3_loop
		adc #$02 ; Actually adds 3 becuase carry was set
		cmp #$00
		beq :+
		jmp dont_play_bg_music
		:
		lda enable_music
		bne :+
		jmp dont_play_bg_music
		:
		lda bg_music_position
		cmp #$00
		bne :++
		lda bg_music_page
		cmp #$03 ; Check if we are on the last music page, which is three, since there are four pages
		bne :+
		jmp dont_play_bg_music
		:
		inc bg_music_page
		:
		; Play pulse notes
			; Set note frequency
			lda bg_music_page
			ldx bg_music_position
			cmp #$00
			bne :+
			; On first page
			lda bg_music_pulse_2, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_pulse_2
			:
			cmp #$01
			bne :+
			; On second page
			lda bg_music_pulse_2 + 256, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_pulse_2
			:
			cmp #$02
			bne :+
			; On third page
			lda bg_music_pulse_2 + 512, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_pulse_2
			:
			; On fourth page
			lda bg_music_pulse_2 + 768, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			done_finding_note_frequency_pulse_2:
			cpy prev_note_low_pulse_2
			bne :+
			cmp prev_note_high_pulse_2
			bne wsnpa
			jmp was_same_note_pulse_alias
			wsnpa:
			:
			sty $4006 ; Low byte
			sty prev_note_low_pulse_2
			sta $4007 ; High byte
			sta prev_note_high_pulse_2
			; Set note duration
			lda bg_music_page
			cmp #$01
			bne :+
			lda bg_music_position
			cmp #$68
			bcc :+
			cmp #$B0
			bcs :+
			lda #%00000111
			jmp :++
			:
			lda #%00111001
			:
			sta $4004
			sta pulse_1_volume
			lda #%00001000
			sta $4005
			; Pulse 1 if not being used
			lda jingle_position
			and #$0F
			cmp #$0F
			bne was_same_note_pulse ; Check if the first pulse channel is currently being used to play a sound
			; If it is not, we can continue
			; Set note frequnecy
			lda bg_music_page
			ldx bg_music_position
			cmp #$00
			bne :+
			; On first page
			lda bg_music_pulse_1, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_pulse_1
			:
			cmp #$01
			bne :+
			; On second page
			lda bg_music_pulse_1 + 256, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_pulse_1
			:
			cmp #$02
			bne :+
			; On third page
			lda bg_music_pulse_1 + 512, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_pulse_1
			:
			; On fourth page
			lda bg_music_pulse_1 + 768, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			done_finding_note_frequency_pulse_1:
			sty $4002
			sta $4003
			jmp :+
			was_same_note_pulse_alias:
			jmp was_same_note_pulse
			:
			; Set note duration
			lda bg_music_page
			cmp #$01
			bne :+
			lda bg_music_position
			cmp #$68
			bcc :+
			cmp #$B0
			bcs :+
			lda #%00110010
			jmp :++
			:
			lda #%00110010
			:
			sta $4000
			lda #%00000100
			sta $4001
			was_same_note_pulse:
			; Gradually decrease the volume of the pulse 2 channel
			lda pulse_1_volume
			cmp #%00110000
			beq :+
			sec
			sbc #$01
			sta $4004
			sta pulse_1_volume
			:
		; Play triangle wave notes
			; Set note duration
			lda bg_music_page
			cmp #$01
			bne :+
			lda bg_music_position
			cmp #$68
			bcc :+
			cmp #$B0
			bcs :+
			lda #%00100000
			jmp :++
			:
			lda #%11111111
			:
			sta $4008
			; Set note frequency
			lda bg_music_page
			ldx bg_music_position
			cmp #$00
			bne :+
			; On first page
			lda bg_music_triangle, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_triangle
			:
			cmp #$01
			bne :+
			; On second page
			lda bg_music_triangle + 256, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_triangle
			:
			cmp #$02
			bne :+
			; On third page
			lda bg_music_triangle + 512, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			jmp done_finding_note_frequency_triangle
			:
			; On fourth page
			lda bg_music_triangle + 768, x
			tax
			ldy midi_to_freq_low, x
			lda midi_to_freq_high, x
			done_finding_note_frequency_triangle:
			cpy prev_note_low_triangle
			bne :+
			cmp prev_note_high_triangle
			beq was_same_note_triangle
			:
			sty $400A ; Low byte
			sty prev_note_low_triangle
			sta $400B ; High byte
			sta prev_note_high_triangle
			was_same_note_triangle:
		lda bg_music_position
		cmp #$D7
		bne :++
		lda bg_music_page
		cmp #$03
		bne :++
		; We now need to loop back
		lda loop_mincraft_times
		cmp #$03
		beq :+
		lda #$C8
		sta bg_music_position
		inc loop_mincraft_times
		jmp :+++
		:
		lda #$00
		sta loop_mincraft_times
		:
		inc bg_music_position
		jmp loop
		:
		dont_play_bg_music:
	
	; Spawn mobs
		; Spawn pigs
		jsr get_rand_0_to_3
		lda day_time
		and #$3F
		cmp rand_out
		bne :+
		; We had a random chance of getting here
		; Now we will check to see if we can spawn a mob
		lda blocks + 77
		cmp #$00
		bne :+
		lda blocks + 78
		cmp #$00
		bne :+
		lda blocks + 79
		cmp #$00
		bne :+
		; We can, so we will spawn a mob
		lda #$0F
		sta blocks + 77
		lda #$F0
		sta blocks + 78
		:
		; Spawn cows
		jsr get_rand_0_to_3
		lda day_time
		and #$3F
		cmp rand_out
		bne :+
		; We had a random chance of getting here
		; Now we will check to see if we can spawn a mob
		lda blocks + 166
		cmp #$00
		bne :+
		lda blocks + 182
		cmp #$00
		bne :+
		lda blocks + 198
		cmp #$00
		bne :+
		; We can, so we will spawn a mob
		lda #$02
		sta blocks + 166
		lda #$F2
		sta blocks + 182
		:

	; Update mobs
		jsr get_rand_0_to_3
		lda time
		and #$1F
		cmp rand_out
		beq :+
		jmp dont_update_mobs
		:
		ldx #$10
		; Loop throguh all blocks
		mob_search_loop:
			lda blocks, x
			cmp #$0F ; Pig Body
			beq :+
			jmp check_cow_updates
			:
			; Positive X
			lda blocks + 1, x
			cmp #$F0
			bne :++
			lda blocks + 2, x
			cmp #$00
			bne :++
			lda #$00
			sta blocks, x
			lda #$0F
			sta blocks + 1, x
			lda #$F0
			sta blocks + 2, x
			inx
			; Play pig sound if sounds are enabled
			lda enable_sound
			cmp #$00
			beq :+
			lda #$1F
			sta apu_enable
			lda #%00001111
			sta $4010
			lda #$BD ; The address of the pig oink sample is $EF40, so we subtract $C000 and divide by 64
			sta $4012
			lda #$6C ; The length of the pig oink sample is $06C0, so we put $6C here
			sta $4013
			:
			jmp no_mob_to_update
			:
			; Negative X
			lda blocks - 1, x
			cmp #$F0
			bne :+
			lda blocks - 2, x
			cmp #$00
			bne :+
			lda #$00
			sta blocks, x
			lda #$0F
			sta blocks - 1, x
			lda #$F0
			sta blocks - 2, x
			jmp no_mob_to_update
			:
			; Positive Y
			lda blocks + 16, x
			cmp #$F0
			bne :+
			lda blocks + 32, x
			cmp #$00
			bne :+
			lda #$00
			sta blocks, x
			lda #$0F
			sta blocks + 16, x
			lda #$F0
			sta blocks + 32, x
			txa
			adc #$10
			tax
			jmp no_mob_to_update
			:
			; Negative Y
			lda blocks - 16, x
			cmp #$F0
			bne check_cow_updates
			lda blocks - 32, x
			cmp #$00
			bne check_cow_updates
			lda #$00
			sta blocks, x
			lda #$0F
			sta blocks - 16, x
			lda #$F0
			sta blocks - 32, x
			; Play pig sound if sounds are enabled
			lda enable_sound
			cmp #$00
			beq :+
			lda #$1F
			sta apu_enable
			lda #%00001111
			sta $4010
			lda #$BD
			sta $4012
			lda #$6C
			sta $4013
			:
			jmp no_mob_to_update
			check_cow_updates:
			cmp #$02 ; Cow Body
			beq :+
			jmp no_mob_to_update
			:
			; Positive X
			lda blocks + 1, x
			cmp #$FF
			bne :+
			lda blocks + 2, x
			cmp #$00
			bne :+
			lda #$00
			sta blocks, x
			lda #$02
			sta blocks + 1, x
			lda #$FF
			sta blocks + 2, x
			inx
			jmp no_mob_to_update
			:
			; Negative X
			lda blocks - 1, x
			cmp #$FF
			bne :++
			lda blocks - 2, x
			cmp #$00
			bne :++
			lda #$00
			sta blocks, x
			lda #$02
			sta blocks - 1, x
			lda #$FF
			sta blocks - 2, x
			; Play cow sound if sounds are enabled
			lda enable_sound
			cmp #$00
			beq :+
			lda #$1F
			sta apu_enable
			lda #%00001111
			sta $4010
			lda #$D8
			sta $4012
			lda #$9F
			sta $4013
			:
			jmp no_mob_to_update
			:
			; Positive Y
			lda blocks + 16, x
			cmp #$F2
			bne :++
			lda blocks + 32, x
			cmp #$00
			bne :++
			lda #$00
			sta blocks, x
			lda #$02
			sta blocks + 16, x
			lda #$F2
			sta blocks + 32, x
			txa
			adc #$10
			tax
			; Play cow sound if sounds are enabled
			lda enable_sound
			cmp #$00
			beq :+
			lda #$1F
			sta apu_enable
			lda #%00001111
			sta $4010
			lda #$D8
			sta $4012
			lda #$9F
			sta $4013
			:
			jmp no_mob_to_update
			:
			; Negative Y
			lda blocks - 16, x
			cmp #$F2
			bne no_mob_to_update
			lda blocks - 32, x
			cmp #$00
			bne no_mob_to_update
			lda #$00
			sta blocks, x
			lda #$02
			sta blocks - 16, x
			lda #$F2
			sta blocks - 32, x
			no_mob_to_update:
			inx
			cpx #$E0
			beq dont_update_mobs
			jmp mob_search_loop
		dont_update_mobs:
	; Randomly rotate mobs
		jsr get_rand_0_to_3
		lda time
		and #$3F
		asl a
		cmp rand_out
		beq :+
		jmp dont_rotate_mobs
		:
		ldx #$00
		rotate_mob_loop:
			lda time
			and #$60
			cmp #$00
			bne done_rotating_mobs
			lda blocks, x
			cmp #$0F
			beq :+
			cmp #$02
			bne done_rotating_mobs
			:
			lda blocks + 1, x
			cmp #$F0
			bne :+
			:
			cmp #$F2
			bne :+
			tay
			lda #$00
			sta blocks + 1, x
			cmp blocks + 16, x
			bne :+
			tya
			sta blocks + 16, x
			jmp done_rotating_mobs
			:
			lda blocks - 1, x
			cmp #$F0
			bne :+
			:
			cmp #$F2
			bne :+
			tay
			lda #$00
			sta blocks - 1, x
			cmp blocks - 16, x
			bne :+
			tya
			sta blocks - 16, x
			jmp done_rotating_mobs
			:
			lda blocks + 16, x
			cmp #$F0
			bne :+
			:
			cmp #$F2
			bne :+
			tay
			lda #$00
			sta blocks + 16, x
			cmp blocks - 1, x
			bne :+
			tya
			sta blocks - 1, x
			jmp done_rotating_mobs
			:
			lda blocks - 16, x
			cmp #$F0
			bne done_rotating_mobs
			lda #$00
			sta blocks - 16, x
			cmp blocks + 1, x
			bne done_rotating_mobs
			tya
			sta blocks + 1, x
			done_rotating_mobs:
			inx
			cpx #$00
			beq dont_rotate_mobs
			jmp rotate_mob_loop
		dont_rotate_mobs:
	
	; Decrement damage cooldown
		lda damage_cooldown
		beq :+
		dec damage_cooldown
		:

	; Repeat loop forever
		jmp loop

; Function to tell what the height of a line should
; be based on where its corresponding ray intersects
get_line_height:
	; Calculate world intersection point
	; First, load the player's position into the "point_x" and "point_y" varables
	ldy px
	sty point_x
	ldy py
	sty point_y
	; Loop until the maximum distance has been reached or we hit a block
	lda #0
	sta ray_steps
	ray_step_loop:
		; Continue or break out of loop
		lda #$07
		cmp ray_steps
		bne :+
		jmp skip_finding_distance
		:
		jsr point_intersects
		ldx check_top_map
		cpx #$01
		bne :+
		lsr a
		lsr a
		lsr a
		lsr a
		jmp :++
		:
		and #$0F
		:
		sta line_color
		cmp #$00
		beq :+
		jmp calculate_distance_and_line
		:
		; Keep the "point_x" and "point_y" variables for later use in block manipulation (breaking/placing)
		lda point_x
		sta prev_point_x
		lda point_y
		sta prev_point_y
		; Load the x and y sub blocks
		; +----------+
		; |   x ---> | One block
		; | y        |  16 x 16
		; | |        | sub blocks
		; | V        |
		; +----------+ Contents of "a" register:
		lda point_x  ;   XXXX.xxxx
		and #$0F     ;   0000.xxxx
		asl a        ;   000x.xxx0
		asl a        ;   00xx.xx00
		asl a        ;   0xxx.x000
		asl a        ;   xxxx.0000
		sta reg_adr
		lda point_y  ;   YYYY.yyyy
		and #$0F     ;   0000.yyyy
		clc
		adc reg_adr  ;   xxxx yyyy
		; Store it in the "in_xy" variable
		;         0123 4567
		; Format: xxxx yyyy
		;         0-15 0-15
		sta in_xy
		; Load the ray angle
		; Starting angles
		;          $00   0
		;         _,-*T*-,_
		;        /    |    \
		;   $C0 |_____|_____| $40
		;   192 |     |     |  64
		;        \_   |   _/
		;          ^-,|,-^
		;          $80 128
		; Since the screen is only 32 tiles wide we dont need to have 64 angles in
		; our FOV we can remove the last bit (or floor divide by 2) the angle.
		;          $00   0
		;         _,-*T*-,_
		;        /    |    \
		;   $60 |_____|_____| $20
		;    96 |     |     |  32
		;        \_   |   _/
		;          ^-,|,-^
		;          $40  64
		; This will leave us with having 128 different angles instead of 256.
		; This is 7 bits, but to cut down the size, we can use just the first 32
		; and rotate the x and y positions in "in_xy" to simulate having the other
		; angles. We can easily do 90*, 180*, and 270* rotations, so we can cut
		; down the angle amount by 1/4. We will then only have 32 anlges, which is
		; 5 bits.
		lda ray_angle;   aaaa aaaa
		and #$3E     ;   00aa aaa0
		lsr a        ;   000a aaaa
		sta in_ang
		; Now we need to rotate the input point (the "in_xy" variable) based on
		; what we have cut off from the angle.
		lda ray_angle
		and #%11000000
		cmp #%01000000
		beq in_xy_rotate_90
		cmp #%10000000
		beq in_xy_rotate_180
		cmp #%11000000
		beq in_xy_rotate_270
		jmp done_rotating_in_xy
		in_xy_rotate_90:
		; "in_xy" needs to be rotated 90* counter-clockwise
			lda in_xy ; xxxxyyyy
			tay
			asl a
			asl a
			asl a
			asl a     ; yyyy0000 (high nybl)
			sta in_xy
			tya       ; xxxxyyyy
			lsr a
			lsr a
			lsr a
			lsr a     ; 0000xxxx (low nybl)
			eor #$0F  ; invert low nybble
			ora in_xy ; combine
			sta in_xy
		jmp done_rotating_in_xy
		in_xy_rotate_180:
		; "in_xy" needs to be rotated 180*
			lda in_xy
			eor #$FF ; Logical not on the coordinate
			sta in_xy
		jmp done_rotating_in_xy
		in_xy_rotate_270:
		; "in_xy" needs to be rotated 270* counter-clockwise
			lda in_xy ; xxxxyyyy
			tay
			asl a
			asl a
			asl a
			asl a     ; yyyy0000 (high nybl)
			eor #$F0  ; invert high nybble
			sta in_xy
			tya       ; xxxxyyyy
			lsr a
			lsr a
			lsr a
			lsr a     ; 0000xxxx (low nybl)
			ora in_xy ; combine
			sta in_xy
		done_rotating_in_xy:
		; Get the calculated index from the lookup table
		;   in_ang     in_xy    |
		; 000a aaaa  xxxx yyyy  | Contents of "a" register:
		lda #<raycasting_lookup ;   llll llll  LUT low byte
		clc
		adc in_xy               ; c xxxx yyyy
		sta raycast_lut
		lda #>raycasting_lookup ; c 0hhh hhhh  LUT high byte
		adc in_ang              ;   0hha aaaa
		sta raycast_lut + 1
		; raycast_lut  raycast_lut + 1
		;   llll llll  hhhh hhhh
		;             +
		;   xxxx yyyy  000a aaaa
		; Now that we have the index added to the LUT's position in memory, we
		; can now get the index from the LUT
		ldy #$00
		lda (raycast_lut), y    ;   0amd dddd  LUT output format
		; +---------------------+ Next block -+
		; | Lookup Table Format |             |
		; +---------------------+             V
		;     0 1 2 3 4 5 6 7 8 9 A B C D E F 0
		;   +----------------------------------
		; 0 |                                |
		; 1 |      X ---->                   |
		; 2 |    Y                           |
		; 3 |    |                           |
		; 4 |    |                           |
		; 5 |    V                           |
		; 6 |            One Block           |
		; 7 |                                | Also part of another block
		; 8 |               () Starting Point|
		; 9 |                 \              |
		; A |                  \R            |
		; B |                   \a           | Ending Point:
		; C |                    \y          | 0amd dddd
		; D |                     \          | 0110 1011
		; E |                      \         |   $6 B
		; F |_______________________\_Ending_|_
		; 0 |   Part of Next block   @ Point | Part of another block
		; Because of there being a range of 0-16 on both the x and y axes, we
		; need to have 5 bits for each of them. 5 bits gets us to 0-31, but if
		; we go any less, we get back to 0-15. There is a problem though. 10
		; bits don't fit into one byte. There is a solution: since we never
		; have any point outputed that is inside the block, only on the edge,
		; we can instead specify which axis the edge is parralel to, and just
		; make that 1 or zero being on the edge of the block we are on or the
		; next one. We then only need 7 bits. We now need to get the ending
		; point data out of the LUT value.
		sta reg_adr
		and #$40
		cmp #$40
		bne :+
		; The point is on a vertical line
		; Get X
		lda reg_adr
		and #$20
		lsr a
		sta out_x
		; Get Y
		lda reg_adr
		and #$1F
		sta out_y
		jmp :++
		:
		; The point is on a horizontal line
		; Get Y
		lda reg_adr
		and #$20
		lsr a
		sta out_y
		; Get X
		lda reg_adr
		and #$1F
		sta out_x
		:
		; Now we need to rotate the output point (the "out_x" and "out_y"
		; variables) back based on what we have cut off from the angle.
		lda ray_angle
		and #%11000000
		sta $0150
		cmp #%01000000
		beq out_rotate_90
		cmp #%10000000
		beq out_rotate_180
		cmp #%11000000
		beq out_rotate_270
		jmp done_rotating_out
		out_rotate_90:
		; The output point needs to be rotated 90* clockwise
			lda #$0F
			sec
			sbc out_y
			ldy out_x
			sty out_y
			sta out_x
			lda #$C0
			sta $0151
		jmp done_rotating_out
		out_rotate_180:
		; The output point needs to be rotated 180*
			lda #$0F
			sec
			sbc out_x
			sta out_x
			lda #$0F
			sec
			sbc out_y
			sta out_y
			lda #$80
			sta $0151
		jmp done_rotating_out
		out_rotate_270:
		; The output point needs to be rotated 270* clockwise
			lda #$0F
			sec
			sbc out_x
			ldy out_y
			sty out_x
			sta out_y
			lda #$40
			sta $0151
		done_rotating_out:
		; _   _   ___  _           _     _           _  _____       ____     X     _   _
		; |\  |  /   \ \     _     /     \     _     / |           /        / \    |\  |
		; | \ | |     | \   / \   /       \   / \   /  |___       |        /___\   | \ |
		; |  \| |     |  \ /   \ /         \ /   \ /   |          |       /     \  |  \|
		; *   *  \___/    V     V           V     V    |_____      \____ /       \ *   *
		;  _________    X     _    _  _____      ___  _________  ______  ____   ___   |
		;      |       / \    |   /  |          /   \     |     |       |    \ /   \  |
		;      |      /___\   |  /   |___       \___      |     |___    |____/ \___   |
		;      |     /     \  | /\   |              \     |     |       |          \
		;      |    /       \ |/  \  |_____     \___/     |     |______ |      \___/  @
		; Take a step based on what the output point is
		; We need to first floor "point_x" and "point_y." Then we
		; can add the output offset to them.
		; First we floor the current point. We will floor "point_x"
		; and "point_y". | Contents of "a" register
		lda point_x      ;   XXXX.xxxx
		and #$F0         ;   XXXX.0000
		clc              ;        .... 'x' here is the
		adc out_x        ;   XXXX.xxxx    output x.
		sta point_x
		lda point_y      ;   YYYY.yyyy
		and #$F0         ;   YYYY.0000
		clc              ;        .... 'y' here is the
		adc out_y        ;   YYYY.yyyy    output y.
		sta point_y
		; Iterate loop
		inc ray_steps
		jmp ray_step_loop
	skip_finding_distance:
	lda #0
	sta line_h
rts
calculate_distance_and_line:
	; Breaking and placing blocks if this is the middle ray
	lda #$10
	cmp line_x
	bne not_middle_ray_alias
	; Make sure we dont break a block above or below the one we are looking at
	lda pl
	and #1
	cmp check_top_map
	beq not_middle_ray_alias
	; Breaking
	lda break_pressed
	cmp #2
	bcc :+
	inc break_pressed
	jmp not_middle_ray_alias
	:
	jmp :+
	not_middle_ray_alias:
	jmp not_middle_ray
	:
	cmp #1
	beq :+
	jmp done_with_breaking
	:
	; Get block
	ldy point_x
	lsr point_x
	lsr point_x
	lsr point_x
	lsr point_x
	lda point_y
	and #%11110000
	clc
	adc point_x
	sty point_x
	tay
	ldx blocks, y
	; Break the appropriate block
	lda #$00
	cmp pl
	bne break_bottom
	; Break top
	txa
	and #$0F
	jmp done_breaking
	break_bottom:
	; Break bottom
	txa
	and #$F0
	done_breaking:
	sta blocks, y
	lda #$FD
	sta break_pressed
	; Check if we killed a mob
	; If we did, increase the amount of meat in our inventory
	cpx #$F0 ; Mob head
	bne :+
	lda item_amounts
	and #$F0
	cmp #$F0
	beq :+
	lda item_amounts
	clc
	adc #$10
	sta item_amounts
	jmp no_collectable_block_broken
	:
	; Check if we broke a wood block
	; If we did, increase the amount of wood in our inventory
	txa
	and #$0F
	cmp #$02 ; Wood
	beq :+
	txa
	and #$F0
	cmp #$20 ; Also wood
	bne :++
	:
	lda item_amounts
	and #$0F
	cmp #$0F
	beq :+
	inc item_amounts
	; We will also tell the inventory to display a game progress message that we acquired wood
	lda #$02
	sta game_progress
	jmp no_collectable_block_broken
	:
	; Check if we broke a stone block
	; If we did, increase the amount of stone in our inventory
	txa
	and #$0F
	cmp #$03 ; Stone
	beq :+
	txa
	and #$F0
	cmp #$30 ; Also stone
	bne :+++
	:
	; Check if we are holding a wooden pickaxe
	lda selected_hotbar_slot
	cmp #$03
	beq :+
	lda item_amounts + 1
	and #$F0
	cmp #$F0
	beq :++
	inc_stone:
	lda item_amounts + 1
	clc
	adc #$10
	sta item_amounts + 1
	jmp :++
	:
	lda item_amounts + 2
	and #$F0
	cmp #$F0
	beq :+
	lda item_amounts + 1
	and #$0F
	cmp #$00
	beq inc_stone
	lda item_amounts + 2
	clc
	adc #$10
	sta item_amounts + 2
	dec item_amounts + 1
	:
	; Check if we are holding a lithium pickaxe
	lda selected_hotbar_slot
	cmp #$04
	bne :+
	lda item_amounts + 2
	clc
	adc #$2F
	sta item_amounts + 2
	lda #$B0 ; Lithium pickaxe breaking sound (Mario Invincible/Starman)
	sta jingle_position
	:
	; We will also tell the inventory to display a game progress message that we acquired lithium
	lda #$03
	sta game_progress
	jmp no_collectable_block_broken
	no_collectable_block_broken:
	; Make break sound
    ; Configure playback sample rate
    lda #%00001110
    sta $400E
    ; Configure length counter load value
    lda #%10100000
    sta $400F
    ; Initialize $400C
    lda #%00000100
    sta $400C
	jmp not_middle_ray
	done_with_breaking:
	; Placeing
	lda place_pressed
	cmp #2
	bcc :+
	inc place_pressed
	jmp not_middle_ray
	:
	cmp #1
	bne not_middle_ray
	; Check if we are selecting the meat slot
	lda selected_hotbar_slot
	cmp #$00
	bne :+
	jmp not_middle_ray ; We don't place a block
	:
	; Check if we have no blocks
	lda item_amounts + 1
	and #$F0
	bne :+
	; We have no stone blocks
	jmp not_middle_ray ; We don't place a block
	:
	; Decrease amount of blocks
	lda item_amounts + 1
	sec
	sbc #$10
	sta item_amounts + 1
	; Get block
	ldy prev_point_x
	lsr prev_point_x
	lsr prev_point_x
	lsr prev_point_x
	lsr prev_point_x
	lda prev_point_y
	and #%11110000
	clc
	adc prev_point_x
	sty prev_point_x
	tay
	ldx blocks, y
	; Place the appropriate block
	lda #$00
	cmp pl
	bne place_bottom
	; Place top
	txa
	and #$0F
	clc
	adc #$30
	jmp done_placeing
	place_bottom:
	; Place bottom
	txa
	and #$F0
	clc
	adc #$03
	done_placeing:
	sta blocks, y
	lda #$FD
	sta place_pressed
	; Make place sound
    ; Configure playback sample rate
    lda #%00001100
    sta $400E
    ; Configure length counter load value
    lda #%11110000
    sta $400F
    ; Initialize $400C
    lda #%00000010
    sta $400C
	not_middle_ray:
	;  __   _   .    __ .   . .     _  _____  ___    __  ___  _ ___  _   .  .  __  ___
	; /    /_\  |   /   |   | |    /_\   |   |__    |  \  |  /_  |  /_\  |\ | /   |__
	; \__ /   \ L__ \__  \_/  L__ /   \  |   |___   |__/ _|_  _/ | /   \ | \| \__ |___
	; Square the difference in x
	lda ray_angle
	cmp #$40
	bcc :+
	cmp #$C0
	bcs :+
	; Left
	lda px
	sec
	sbc point_x
	jmp :++
	:
	; Right
	lda point_x
	sec
	sbc px
	:
	and #$7F ; Wrap or modulo by 128
	tax
	lda square_low_lookup, x
	sta diff_x_squared
	lda square_high_lookup, x
	sta diff_x_squared + 1
	; Square the difference in y
	lda ray_angle
	cmp #$80
	bcc :+
	; Up
	lda py
	sec
	sbc point_y
	jmp :++
	:
	; Down
	lda point_y
	sec
	sbc py
	:
	and #$7F ; Wrap or modulo by 128
	tax
	lda square_low_lookup, x
	sta diff_y_squared
	lda square_high_lookup, x
	sta diff_y_squared + 1
	; Add the squared x and y differences together
	lda diff_x_squared
	clc
	adc diff_y_squared
	sta dist_squared
	lda diff_x_squared + 1
	adc diff_y_squared + 1
	tax
	jsr point_intersects
	and #$F0 ; Just get the top block
	cmp #$F0 ; Check if it is a half-sized block
	bne :+
	txa
	asl a
	asl a
	jmp :++
	:
	txa
	:
	; Find the square root of "dist_squared" which will be the length of the ray we want
	asl a
	sta dist_squared + 1
	lda dist_squared
	and #$80
	clc
	rol a
	rol a
	adc dist_squared + 1
	; tax                           | This is an artifact from when the game looked terrible.
	; lda square_root_lookup, x     | This calculation is now already performed in the LUT.
	; asl a                         | the python script that generates the LUT can use floating points so its better.
	; Make sure we don't render too far
	cmp #$2C
	bcc :+
	lda #$00
	sta line_h
	sta line_color
	rts
	:
	; Store the ray distance in the "line_h" variable temporarily
	sta line_h
	; Get the line height based on the distance that the ray had to travel
	lda line_x
	asl a
	sec
	sbc #$1F
	cmp #$80
	bcc :+
	sta reg_adr
	lda #$00
	sec
	sbc reg_adr
	:
	tay
	and #%00001100
	asl a
	asl a
	asl a
	asl a
	adc line_h
	tax
	cpy #$10
	bcs :+
	lda line_height_lookup_1, x ; Convert from ray length to line height
	jmp :++
	:
	lda line_height_lookup_2, x ; Convert from ray length to line height
	:
	sta line_h
	; Color
	ldx line_color
	lda wall_type_to_tile_type, x ; Get what tile number corresponds to the wall number
	sta line_color
	; Check if this block requires shading
	cpx #$05
	beq dont_shade
	; Shading
	lda point_x
	clc
	adc #1
	sta point_x
	lda point_y
	sec
	sbc #1
	sta point_y
	jsr point_intersects
	ldx check_top_map
	cpx #$00
	beq :+
	and #$F0
	:
	cmp #$00
	beq :+
	lda line_color
	adc #17
	sta line_color
	:
	; More Shading
	lda point_y
	sec
	adc #2
	sta point_y
	jsr point_intersects
	; "x" already is loaded with "check_top_map"
	cpx #$00
	beq :+
	and #$F0
	:
	cmp #$00
	beq :+
	lda line_color
	adc #17
	sta line_color
	:
	dont_shade:
rts

; Function to check if a point is in a block
point_intersects:
	ldy point_x
	lsr point_x
	lsr point_x
	lsr point_x
	lsr point_x
	lda point_y
	and #%11110000
	clc
	adc point_x
	sty point_x
	tay
	lda blocks, y
rts

; Function to set a block
set_block_at_point:
	ldy point_x
	lsr point_x
	lsr point_x
	lsr point_x
	lsr point_x
	lda point_y
	and #%11110000
	clc
	adc point_x
	sty point_x
	tay
	lda block_type
	sta blocks, y
rts

; Sin function
get_sin:
	; Load trig input in y for later
	ldy trig_input
	; Modulate trig input by 64
	lda trig_input
	and #%00111111
	sta trig_input
	; Load trig input into x
	ldx trig_input
	; Store y back into trig input to maintain its value for later use
	sty trig_input
	; Modulate trig input by 128 and store it in the accumulator
	lda trig_input
	and #%01111111
	; Every other curve must be flipped left to right
	cmp #$40
	bcc :+
		; This is every other curve
		lda #$3F
		stx trig_input
		sec
		sbc trig_input
		sta trig_input
		ldx trig_input
	:
	; Get the sin value from the table and put it into the accumulator
	lda sin_values, x
	; Store the accululator value in trig output
	sta trig_output
	; Every other two curves must be made negative
	lda #$00
	cpy #$80
	bcc :+
		; This is every other two curves
		lda #$01
	:
	sta trig_out_neg
rts

; Cos function
get_cos:
	lda trig_input
	clc
	adc #$40
	sta trig_input
	jsr get_sin
rts

; Function used by the display tile top and bottom functions to get the tile index
get_tile_index:
	tya
	asl a
	asl a
	asl a
	asl a
	asl a
	clc
	adc line_x
	sta trig_input ; Just a currently unused address
	lda set_tile_type
	; Color
	adc line_color
	; Tile optimization
	cmp #$12
	bcc :+
	tax
	lda tile_optimization - $12, x
	:
	; Store tile value
	ldx trig_input
rts

; Display a tile in the top half of the display area
display_tile_top:
	jsr get_tile_index
	sta display_buff, x
rts

; Display a tile in the bottom half section of the display area
display_tile_bottom:
	jsr get_tile_index
	sta display_buff_middle, x
rts

; Add a vertical line to the top half of the display area
display_line_top:
	; Set starting values
	lda #$00
	sta set_tile_type
	sta line_mod
	lda line_h
	; If the line length is 64, it takes up the entire vertical
	; space, so set the starting tile to be a line body tile
	cmp #64
	bne :+
	lda #$08
	sta set_tile_type
	:
	; Load "line_h" and divide it by 8 to get just the number based on tiles, because tiles are 8x8
	lda line_h
	lsr a
	lsr a
	lsr a
	sta reg_adr
	; Get line starting point
	lda #7
	sec
	sbc reg_adr
	sta line_start
	; Line drawing loop
	ldy #0
	line_drawing_loop:
	; Check for tile change to the edge of the line
	cpy line_start
	bne no_tile_change
	lda line_mod
	cmp #$FF
	beq in_line_body
	lda line_h
	and #$07
	sta set_tile_type
	inc line_start
	lda #$FF
	sta line_mod
	jmp no_tile_change
	; Check for tile change to the body of the line
	in_line_body:
	lda #$08
	sta set_tile_type
	no_tile_change:
	; Draw tiles
	jsr display_tile_top
	; Repeat loop
	iny
	cpy #$08
	bcc line_drawing_loop
rts

; Add a vertical line to the top half of the display area
display_line_bottom:
	; Set starting values
	lda #$0A
	sta set_tile_type
	sta line_mod
	lda line_h
	; If the line length is 64, it takes up the entire vertical
	; space, so set the starting tile to be a line body tile
	cmp #64
	bne :+
	lda #$09
	sta set_tile_type
	:
	; Load "line_h" and divide it by 8 to get just the number based on tiles, because tiles are 8x8
	lda line_h
	lsr a
	lsr a
	lsr a
	sta reg_adr
	; Get line starting point
	lda #7
	clc
	adc reg_adr
	sta line_start
	; Line drawing loop
	ldy #$0F
	line_drawing_loop_bottom:
	; Check for tile change to the edge of the line
	cpy line_start
	bne no_tile_change_bottom
	lda line_mod
	cmp #$FF
	beq in_line_body_bottom
	lda line_h
	and #$07
	clc
	adc set_tile_type
	sta set_tile_type
	dec line_start
	lda #$FF
	sta line_mod
	jmp no_tile_change_bottom
	; Check for tile change to the body of the line
	in_line_body_bottom:
	lda #$09
	sta set_tile_type
	no_tile_change_bottom:
	; Draw tiles
	jsr display_tile_bottom
	; Repeat loop
	dey
	cpy #$08
	bcs line_drawing_loop_bottom
rts

; Function to update the inventory screen
update_inventory:
	lda #$FF
	sta $020C
	sta $0210
	sta $0214
	; Get controller input
		; B button
			lda controller
			and #%00000001
			cmp #%00000001
			bne inventory_done_checking_b_button
			; Check if we can interact with the inventory gui or not
			; "a" is already one
			cmp in_game
			bne inventory_done_checking_b_button
			ldx music_enable_changed
			cpx #$01
			beq inventory_done_checking_b_button
			; "a" is already one
			sec
			sbc enable_music
			sta enable_music
			sta last_sound_change
			ldy #$08
			sty sound_change_animation_time
			cmp #$00
			bne :+
			; Clear apu addresses
			lda #$00
			sta $4000
			sta $4001
			sta $4002
			sta $4003
			sta $4004
			sta $4005
			sta $4006
			sta $4007
			sta $4008
			sta $400A
			sta $400B
			:
			lda #$01
		inventory_done_checking_b_button:
		sta music_enable_changed
		; Select button
			lda controller
			and #%00000001
			cmp #%00000001
			bne inventory_done_checking_select_button
			; Check if we can interact with the inventory gui or not
			; "a" is already one
			cmp in_game
			bne inventory_done_checking_select_button
			lda pressed_up_left_down
			cmp #$03
			bne inventory_done_checking_select_button
			lda #$F0
			sta item_amounts
			lda #$04
			sta item_amounts + 1
			lda #$08
			sta item_amounts + 2
		inventory_done_checking_select_button:
		; Start button
			lda controller
			and #%00000001
			cmp #%00000001
			bne :+
			; The start button is pressed
			; "a" is already 1
			cmp start_pressed
			beq inventory_done_checking_start_button
			sta start_pressed
			; The start button was just pressed
			sec
			sbc in_game
			sta in_game
			; Play the open title screen jingle
			lda #$30 ; Load jingle number three
			sta jingle_position
			jmp inventory_done_checking_start_button
			:
			; The start button is not pressed
			lda #$00
			sta start_pressed
		inventory_done_checking_start_button:
		; Check if we can interact with the inventory gui or not
		lda in_game
		cmp #$01
		beq :+
		rts
		:
		; D pad up
			lda controller
			and #%00000001
			cmp #%00000001
			bne inventory_done_checking_d_pad_up
			lda item_amounts + 1
			and #$0F ; Get the amount of pickaxes we have
			cmp #$0F
			beq inventory_done_checking_d_pad_up ; We can't get more pickaxes if we are already at the limit
			lda item_amounts
			and #$0F ; Get the amount of wood we have
			cmp #$00
			beq inventory_done_checking_d_pad_up ; If we have no wood, we can't turn wood into pickaxes
			; If we have wood and can get more pickaxes, we need to convert them now
			; Since we did all those checks, it's as simple as:
			dec item_amounts     ; Decreasing the amount of wood we have and
			inc item_amounts + 1 ; Increasing our pickaxes
			; Play the sound for making wooden pickaxes
			lda #$70
			sta jingle_position
		inventory_done_checking_d_pad_up:
		; D pad down
			lda controller
			and #%00000001
			cmp #%00000001
			bne inventory_done_checking_d_pad_down
			ldx sound_enable_changed
			cpx #$01
			beq inventory_done_checking_d_pad_down
			; "a" is already one
			sec
			sbc enable_sound
			sta enable_sound
			tax
			adc #$01
			sta last_sound_change
			ldy #$08
			sty sound_change_animation_time
			cpx #$00
			beq :+
			lda #$0F
			sta apu_enable
			ldy #$60 ; Play sound effect on sound
			sty jingle_position
			jmp :++
			:
			lda #$07
			sta apu_enable
			ldy #$50 ; Play sound effect off sound
			sty jingle_position
			:
			lda #$01
		inventory_done_checking_d_pad_down:
		sta sound_enable_changed
		; D pad left
			lda controller
			and #%00000001
			cmp #%00000001
			bne inventory_done_checking_d_pad_left
			lda item_amounts + 2
			and #$F0
			beq inventory_done_checking_d_pad_left
			lda item_amounts + 2
			sec
			sbc #$10
			sta item_amounts + 2
			inc player_energy
			inc player_energy_changed
		inventory_done_checking_d_pad_left:
		; D pad right
			lda controller
			and #%00000001
			cmp #%00000001
			bne inventory_done_checking_d_pad_right
			lda item_amounts + 2
			and #$0F ; Get the amount of lithium pickaxes we have
			cmp #$0F
			beq inventory_done_checking_d_pad_right ; We can't get more pickaxes if we are already at the limit
			lda item_amounts + 2
			and #$F0 ; Get the amount of lithium we have
			cmp #$00
			beq inventory_done_checking_d_pad_right ; If we have no lithium, we can't turn lithium into pickaxes
			; If we have lithium and can get more pickaxes, we need to convert them now
			lda item_amounts + 2
			sec
			sbc #$0F ; Decreasing the amount of lithium we have and increasing our pickaxes
			sta item_amounts + 2
			; Play the sound for making lithium pickaxes
			lda #$70
			sta jingle_position
		inventory_done_checking_d_pad_right:
	; Draw inventory
		; Panel
		ldx #$06
		ldy #$06
		lda #$3E
		draw_next_inventory_tile:
			sta display_buff + 160, x
			inx
			iny
			cpy #$1C
			bne :+
			ldy #$06
			txa
			clc
			adc #$0A
			tax
			lda #$3E
			:
			cpx #$E0
			bcc draw_next_inventory_tile
		; Title
		ldx #$06
		lda #$2E
		draw_left_titlebar:
			sta display_buff + 128, x
			inx
			cpx #$0C
			bne draw_left_titlebar
		lda #$36
		sta display_buff + 128 + $0C
		lda #$F9
		sta display_buff + 128 + $0D
		lda #$FA
		sta display_buff + 128 + $0E
		lda #$FB
		sta display_buff + 128 + $0F
		lda #$F8
		sta display_buff + 128 + $10
		lda #$FA
		sta display_buff + 128 + $11
		lda #$F4
		sta display_buff + 128 + $12
		lda #$FC
		sta display_buff + 128 + $13
		lda #$F6
		sta display_buff + 128 + $14
		lda #$FD
		sta display_buff + 128 + $15
		lda #$3F
		sta display_buff + 128 + $16
		lda #$2E
		ldx #$16
		draw_right_titlebar:
			inx
			sta display_buff + 128, x
			cpx #$1A
			bne draw_right_titlebar
		lda #$64
		sta display_buff + 128 + $1B
		; Contents
		ldx #$00
		lda #$40
		sta display_buff + 256 + 16 + 32
		lda #$48
		sta display_buff + 256 + 17 + 32
		lda #$51
		sta display_buff + 256 + 16 + 32 + 32
		lda #$52
		sta display_buff + 256 + 17 + 32 + 32
		lda #$40
		sta display_buff + 256 + 19 + 32
		lda #$48
		sta display_buff + 256 + 20 + 32
		lda #$51
		sta display_buff + 256 + 19 + 32 + 32
		lda #$52
		sta display_buff + 256 + 20 + 32 + 32
		lda #$63
		sta display_buff + 192 + 24
		lda #$5A
		sta display_buff + 256 + 24
		lda #$6C
		sta display_buff + 256 + 24 + 64
		lda #$75
		sta display_buff + 192 + 25
		lda #$7E
		sta display_buff + 256 + 25
		lda #$87
		sta display_buff + 256 + 25 + 64
		lda #$88
		sta display_buff + 256 + 26 + 64
		lda #$1C
		sta display_buff + 256 + 18 + 32
		lda #$90
		sta display_buff + 256 + 32 + 18 + 32
		; Stage list
		; Title text
		lda #$F3
		sta display_buff + 192 + 7
		lda #$F4
		sta display_buff + 192 + 8
		lda #$F5
		sta display_buff + 192 + 9
		lda #$FE
		sta display_buff + 192 + 10
		lda #$F8
		sta display_buff + 192 + 11
		lda #$F3
		sta display_buff + 192 + 12
		; Wood to pickaxe
		lda #$F2
		sta display_buff + 192 + 64 + 7
		lda #$1C
		sta display_buff + 192 + 64 + 8
		lda #$EB
		sta display_buff + 192 + 64 + 10
		lda #$A2
		sta display_buff + 192 + 64 + 12
		; Lithium to energy
		lda #$12
		sta display_buff + 192 + 128 + 7
		lda #$1C
		sta display_buff + 192 + 128 + 8
		lda #$CF
		sta display_buff + 192 + 128 + 9
		lda #$D0
		sta display_buff + 192 + 128 + 10
		lda #$24
		sta display_buff + 192 + 128 + 12
		; Super power text
		;         S U P E R
		;           P O W E R
		; SUPER
		lda #$F3
		sta display_buff + 192 + 16
		lda #$99
		sta display_buff + 192 + 17
		lda #$F7
		sta display_buff + 192 + 18
		lda #$F8
		sta display_buff + 192 + 19
		lda #$F6
		sta display_buff + 192 + 20
		; POWER
		lda #$F7
		sta display_buff + 224 + 17
		lda #$FC
		sta display_buff + 224 + 18
		lda #$9A
		sta display_buff + 224 + 19
		lda #$F8
		sta display_buff + 224 + 20
		lda #$F6
		sta display_buff + 224 + 21

rts

get_rand_0_to_255:
	lda $0000, x
	sta rand_out
	lda $0100, y
	rra rand_out
	sta rand_out
	tax
	lda $0200, x
	sbc rand_out
	sta rand_out
	tax
	lda $0300, x
	adc rand_out
	tay
	lda $0400, y
	rra rand_out
	adc rand_out
rts

get_rand_0_to_3:
	lda $0000, x
	sta rand_out
	lda $0100, y
	rra rand_out
	sta rand_out
	tax
	lda $0200, x
	sbc rand_out
	sta rand_out
	tax
	inx ; A random thing added to use the last remaining byte in the rom: it makes this function a tiny bit more random
	lda $0300, x
	adc rand_out
	tay
	lda $0400, y
	rra rand_out
	and #$02
	sta rand_out
rts

; Loop that checks if we pressed b
start_end_poem:
	lda #$00
	sta jingle_position
	sta day_time

loop_end_poem:
	; Play remix of Fallen Down
	lda day_time
	and #$1F
	bne :+++
	; Pulse
	ldx jingle_position
	lda end_poem_music, x
	sta $4002
	sta $4006
	lda #%10000011
	sta $4000
	lda #%10000001
	sta $4004
	lda #%00000010
	sta $4001
	sta $4005
	lda #%11011000
	sta $4003
	lda #%11111100
	sta $4007
	; Triangle
	lda jingle_position
	and #$03
	bne :+
	lda #$00
	sta $400A
	sta $400B
	lda playing_triangle_notes
	and #$0F
	cmp #$02
	bcc :+
	lda jingle_position
	lsr a
	lsr a
	and #$0F
	tax
	lda end_poem_music_low, x
	sta $400A
	lda #$FF
	sta $4008
	lda #%00000001
	sta $400B
	:
	; Increment note position
	inc jingle_position
	lda jingle_position
	cmp #$35 ; End of main body
	bne :+
	lda #$05 ; End of intro
	sta jingle_position
	inc playing_triangle_notes
	:
	inc day_time
	:
	; Check if the player pressed the b button
	lda #$01
	sta controller
	lda #$00
	sta controller
	lda controller
	lda controller
	and #$01
	beq loop_end_poem ; The player hasn't pressed b yet
	jmp reset ; The player pressed b which will reset the game
jmp loop_end_poem

; Function that updates the random star index for the end poem background
get_end_poem_star:
	lda star_counter
	cmp #$04
	bcs :+
	stx reg_adr
	sty end_scroll
	jsr get_rand_0_to_255
	ldx reg_adr
	ldy end_scroll
	and #$07
	rol a
	sta star_counter
	inc star_index
	lda star_index
	cmp #$B0
	bne :++
	lda #$80
	sta star_index
	jmp :++
	:
	lda #$00
	:
	dec star_counter
	dec star_counter
	dec star_counter
rts

; This is called every time the previous screen has finished rendering
NMI:
	; Back up registers
		pha
		txa
		pha
		tya
		pha
	
	; Check if we are in the end poem
		lda finished_poem
		beq :+
		inc day_time ; For timing the end poem music
		jmp put_registers_back_in_poem
		:
		lda in_end_poem
		bne :+
		jmp not_in_the_end_poem
		:
		inc day_time ; For timing the end poem music
		; End poem NMI
		; Change the background color palette for everything
			cmp #$02
			beq :+
			lda #$3F
			sta $2006
			lda #$05
			sta $2006
			ldx #$37
			stx $2007
			ldy #$14
			sty $2007
			lda #$3F
			sta $2006
			lda #$09
			sta $2006
			stx $2007
			lda #$3F
			sta $2006
			lda #$0D
			sta $2006
			stx $2007
			sty $2007
			inc in_end_poem
		:
		; Draw the remaining line underneath the previously drawn line for letters like y and g on the right half of the screen
			lda draw_text_line_flag
			cmp #$03
			bne :+
			inc draw_text_line_flag
			lda poem_scroll_low
			and #$0F
			beq :++
			:
			jmp done_finishing_the_previous_line2
			:
			; Set the starting position
				bit $2002
				lda poem_scroll_low
				lsr a ; 00100000
				lsr a ; 00010000
				lsr a ; 00001000
				lsr a ; 00000100
				lsr a ; 00000010
				lsr a ; 00000001
				clc
				adc #$28
				sta reg_adr
				lda poem_scroll_high
				and #$01
				asl a
				asl a
				asl a
				adc reg_adr
				sta $2006
				lda poem_scroll_low
				and #$30
				asl a
				asl a
				adc #$2F
				sta $2006
			ldx #$00 ; Character x position on screen
			; Draw the bottom halves of characters
			draw_next_lower_char2:
			lda lower_line_chars2, x
			clc
			adc #$10
			sta $2007
			; Check if we are starting a new line or continuing to the next character
			lda lower_line_chars2, x
			inx
			cmp #$B0
			bne :+
			cpx #$06
			bcs start_clearing_prev_line2
			:
			cmp #$DC
			bcs :+
			cpx #$0B
			bcc draw_next_lower_char2
			:
			; Clear out the rest of the horrizontal row of characters
			start_clearing_prev_line2:
			lda #$00
			clear_full_prev_line2:
			sta $2007
			inx
			cpx #$11
			bcc clear_full_prev_line2
			done_finishing_the_previous_line2:
		; Write the new text before it gets on screen on the right half of the screen
			lda draw_text_line_flag
			cmp #$02
			bne :+
			inc draw_text_line_flag
			lda poem_scroll_low
			and #$0F
			beq :++
			:
			jmp done_writing_new_text_line2
			:
			; Set the next text line start position
				bit $2002
				lda poem_scroll_low
				lsr a ; 00100000
				lsr a ; 00010000
				lsr a ; 00001000
				lsr a ; 00000100
				lsr a ; 00000010
				lsr a ; 00000001
				clc
				adc #$28
				sta reg_adr
				lda poem_scroll_high
				and #$01
				asl a
				asl a
				asl a
				adc reg_adr
				sta $2006
				lda poem_scroll_low
				and #$30
				asl a
				asl a
				adc #$0F
				sta $2006
			; Start writing text
				ldx #$00 ; Character x position on screen
				write_next_character2:
				; Check if the poem is finished
				lda poem_page
				cmp #$04
				bne :+
				lda #$B0
				jmp writing_the_character2
				:
				; Get the character combo
				lda poem_page
				bne :+
				ldy poem_character_pos
				lda end_poem_text, y
				jmp :++++
				:
				cmp #$01
				bne :+
				ldy poem_character_pos
				lda end_poem_text + 256, y
				jmp :+++
				:
				cmp #$02
				bne :+
				ldy poem_character_pos
				lda end_poem_text + 512, y
				jmp :++
				:
				ldy poem_character_pos
				lda end_poem_text + 768, y
				:
				; Select which character to grab
				ldy poem_character_nybl
				cpy #$01
				beq :+
				lsr a
				lsr a
				lsr a
				lsr a
				jmp :++
				:
				and #$0F
				:
				sta line_start ; Unused address
				; Get formatting chunk
				lda poem_character_pos
				and #%11111100
				ora poem_page
				tay
				lda end_poem_formatting, y
				sta rand_out ; Unused address
				; Get specific character from formatting
				lda poem_character_pos
				asl a
				ora poem_character_nybl
				and #$07
				; Add the formatting to the character
				tay
				lda rand_out ; Format chunk
				format_push_loop2:
					cpy #$00
					beq done_shifting_format_byte2
					asl a
					dey
					jmp format_push_loop2
				done_shifting_format_byte2:
				and #$80
				lsr a
				lsr a
				ora line_start ; Character nybl
				; Write the character
				clc
				adc #$B0
				writing_the_character2:
				sta $2007
				sta lower_line_chars2, x
				sta rand_out ; Unused address
				; Move to next character position
				inx ; Increment the x position of the next character
				inc poem_character_nybl
				lda poem_character_nybl
				cmp #$02
				bne done_writing_character2
				dec poem_character_nybl
				dec poem_character_nybl
				inc poem_character_pos
				bne done_writing_character2
				inc poem_page
				done_writing_character2:
				; Check if we are starting a new line
				cpx #$0B
				bcs clear_the_rest_of_the_line2
				lda rand_out
				cmp #$DC
				bcs clear_the_rest_of_the_line2
				cmp #$B0
				bne :+
				cpx #$06
				bcs clear_the_rest_of_the_line2
				:
				jmp write_next_character2
			clear_the_rest_of_the_line2:
			; Clear out the rest of the horrizontal row of characters
			clear_full_line2:
			lda #$00
			sta $2007
			inx
			cpx #$11
			bcc clear_full_line2
			done_writing_new_text_line2:
		; Draw the remaining line underneath the previously drawn line for letters like y and g on the left half of the screen
			lda draw_text_line_flag
			cmp #$01
			bne :+
			inc draw_text_line_flag
			lda poem_scroll_low
			and #$0F
			beq :++
			:
			jmp done_finishing_the_previous_line
			:
			; Set the starting position
				bit $2002
				lda poem_scroll_low
				lsr a ; 00100000
				lsr a ; 00010000
				lsr a ; 00001000
				lsr a ; 00000100
				lsr a ; 00000010
				lsr a ; 00000001
				clc
				adc #$28
				sta reg_adr
				lda poem_scroll_high
				and #$01
				asl a
				asl a
				asl a
				adc reg_adr
				sta $2006
				lda poem_scroll_low
				and #$30
				asl a
				asl a
				adc #$20
				sta $2006
			; Clear the first 4 characters of the row
			jsr get_end_poem_star ; Star
			sta $2007
			jsr get_end_poem_star ; Star
			sta $2007
			jsr get_end_poem_star ; Star
			sta $2007
			ldx #$00 ; Character x position on screen
			stx $2007
			; Draw the bottom halves of characters
			draw_next_lower_char:
			lda lower_line_chars, x
			clc
			adc #$10
			sta $2007
			lda lower_line_chars, x
			inx
			cmp #$DC
			bcs :+
			cpx #$0B
			bcc draw_next_lower_char
			:
			; Clear out the rest of the horrizontal row of characters
			lda #$00
			clear_full_prev_line:
			sta $2007
			inx
			cpx #$0F
			bcc clear_full_prev_line
			done_finishing_the_previous_line:
		; Write the new text before it gets on screen on the left half of the screen
			lda draw_text_line_flag
			bne :+
			inc draw_text_line_flag
			lda poem_scroll_low
			and #$0F
			beq :++
			:
			jmp done_writing_new_text_line
			:
			; Set the next text line start position
				bit $2002
				lda poem_scroll_low
				lsr a ; 00100000
				lsr a ; 00010000
				lsr a ; 00001000
				lsr a ; 00000100
				lsr a ; 00000010
				lsr a ; 00000001
				clc
				adc #$28
				sta reg_adr
				lda poem_scroll_high
				and #$01
				asl a
				asl a
				asl a
				adc reg_adr
				sta $2006
				lda poem_scroll_low
				and #$30
				asl a
				asl a
				sta $2006
			; Draw stars on the left
				ldx #$00 ; Character x position on screen
				stx $2007
				stx $2007
				jsr get_end_poem_star ; Star
				sta $2007
				stx $2007
			; Start writing text
				write_next_character:
				; Check if the poem is finished
				lda poem_page
				cmp #$04
				bne :+
				lda #$B0
				jmp writing_the_character
				:
				; Get the character combo
				lda poem_page
				bne :+
				ldy poem_character_pos
				lda end_poem_text, y
				jmp :++++
				:
				cmp #$01
				bne :+
				ldy poem_character_pos
				lda end_poem_text + 256, y
				jmp :+++
				:
				cmp #$02
				bne :+
				ldy poem_character_pos
				lda end_poem_text + 512, y
				jmp :++
				:
				ldy poem_character_pos
				lda end_poem_text + 768, y
				:
				; Select which character to grab
				ldy poem_character_nybl
				cpy #$01
				beq :+
				lsr a
				lsr a
				lsr a
				lsr a
				jmp :++
				:
				and #$0F
				:
				sta line_start ; Unused address
				; Get formatting chunk
				lda poem_character_pos
				and #%11111100
				ora poem_page
				tay
				lda end_poem_formatting, y
				sta rand_out ; Unused address
				; Get specific character from formatting
				lda poem_character_pos
				asl a
				ora poem_character_nybl
				and #$07
				; Add the formatting to the character
				tay
				lda rand_out ; Format chunk
				format_push_loop:
					cpy #$00
					beq done_shifting_format_byte
					asl a
					dey
					jmp format_push_loop
				done_shifting_format_byte:
				and #$80
				lsr a
				lsr a
				ora line_start ; Character nybl
				; Write the character
				clc
				adc #$B0
				writing_the_character:
				sta $2007
				sta lower_line_chars, x
				sta rand_out ; Unused address
				; Move to next character position
				inx ; Increment the x position of the next character
				inc poem_character_nybl
				lda poem_character_nybl
				cmp #$02
				bne done_writing_character
				dec poem_character_nybl
				dec poem_character_nybl
				inc poem_character_pos
				bne done_writing_character
				inc poem_page
				done_writing_character:
				; Check if we are starting a new line
				cpx #$0B
				bcs clear_the_rest_of_the_line
				lda rand_out
				cmp #$DC
				bcs clear_the_rest_of_the_line
				jmp write_next_character
			clear_the_rest_of_the_line:
			; Clear out the rest of the horrizontal row of characters
			lda #$00
			clear_full_line:
			sta $2007
			inx
			cpx #$0E
			bcc clear_full_line
			done_writing_new_text_line:
		; Scroll the poem
			bit $2002
			lda #$00
			sta $2005
			lda poem_scroll_low
			sta $2005
			lda poem_scroll_high
			and #$01
			clc
			adc #%10000001
			sta $2000
			lda poem_scroll_sub_pixel
			adc #40
			sta poem_scroll_sub_pixel
			bcc :+
			inc poem_scroll_low
			lda #$00
			sta draw_text_line_flag ; Alow another line to be written
			lda poem_scroll_low
			cmp #240
			bne :+
			lda #$00
			sta poem_scroll_low
			inc poem_scroll_high
			:
		; Check if the poem finished
			lda poem_page
			cmp #$04
			bne :+
			lda poem_character_pos
			cmp #$18
			bcc :+
			inc finished_poem
			:
		; Put registers back and return to interupted code, which just checks for b presses
			put_registers_back_in_poem:
			pla
			tay
			pla
			tax
			pla
			rti
	not_in_the_end_poem:

	; Update the health bar
		lda player_health_changed ; Check if the player's health has changed
		beq dont_update_health_bar
		; Redraw the health bar
		bit $2002
		; Start position
		lda #$2A
		sta $2006
		lda #$24
		sta $2006
		; Starting values
		ldx #$AB ; Full heart tile to start with
		ldy #$00 ; Heart index
		; Start setting tiles
		update_next_heart:
		; Check for tile change
		lda player_health
		lsr a
		sta player_health_changed
		cpy player_health_changed
		bcc :+
		ldx #$B4
		:
		sty player_health_changed
		lda player_health_changed
		sec
		rol a
		cmp player_health
		bne :+
		ldx #$AC
		:
		; Set next tile
		stx $2007
		; Increment and loop back
		iny
		cpy #$0A
		bcc update_next_heart
		; Reset the health update variable
		lda #$00
		sta player_health_changed
		jmp finished_refeshing
		dont_update_health_bar:
	
	; Update the hunger bar
		lda player_hunger_changed ; Check if the player's hunger has changed
		beq dont_update_hunger_bar
		; Redraw the hunger bar
		bit $2002
		; Start position
		lda #$2A
		sta $2006
		lda #$33
		sta $2006
		; Starting values
		ldx #$BD ; Full meat tile to start with
		ldy #$00 ; Meat index
		; Start setting tiles
		update_next_meat:
		; Check for tile change
		lda player_hunger
		lsr a
		sta player_hunger_changed
		cpy player_hunger_changed
		bcc :+
		ldx #$C6
		:
		sty player_hunger_changed
		lda player_hunger_changed
		sec
		rol a
		cmp player_hunger
		bne :+
		ldx #$BE
		:
		; Set next tile
		stx $2007
		; Increment and loop back
		iny
		cpy #$0A
		bcc update_next_meat
		; Reset the hunger update variable
		lda #$00
		sta player_hunger_changed
		jmp finished_refeshing
		dont_update_hunger_bar:
	
	; Update the energy bar
		lda player_energy_changed ; Check if the player's energy has changed
		beq dont_update_energy_bar
		; Redraw the energy bar
		bit $2002
		; Start position
		lda #$2A
		sta $2006
		lda #$64
		sta $2006
		; Starting values
		ldx #$E1 ; Filled tick tile to start with
		ldy #$00 ; Tick index
		; Start setting tiles
		update_next_tick:
		; Check for tile change
		cpy player_energy
		bne :+
		ldx #$CF
		:
		; Set next tile
		stx $2007
		; Increment and loop back
		iny
		cpy #$19
		bcc update_next_tick
		; Reset the energy update variable
		lda #$00
		sta player_energy_changed
		jmp finished_refeshing
		dont_update_energy_bar:
	
	; Check if we are actually in the game
		lda in_game
		cmp #$00
		bne :+
		jmp finished_refeshing
		:

	; Refresh the next part of the screen
		bit $2002
		lda display_frame
		cmp #$00
		bne :+
		; Refresh the top 2 rows of the display area
			; Start position
			lda #$28
			sta $2006
			ldy #$00
			sty $2006
			; Start setting tiles
			set_next_tile1:
			; Set next tile
			lda display_buff, y
			sta $2007
			iny
			cpy #$40
			bcc set_next_tile1
		jmp finished_refeshing
		:
		cmp #$01
		bne :+
		; Refresh the next 2 top rows of the display area
			; Start position
			lda #$28
			sta $2006
			ldy #$40
			sty $2006
			set_next_tile2:
			; Set next tile
			lda display_buff, y
			sta $2007
			iny
			cpy #$80
			bne set_next_tile2
		jmp finished_refeshing
		:
		cmp #$02
		bne :+
		; Refresh the next 2 top/middle rows of the display area
			; Start position
			lda #$28
			sta $2006
			ldy #$80
			sty $2006
			; Start setting tiles
			set_next_tile3:
			; Set next tile
			lda display_buff, y
			sta $2007
			iny
			cpy #$D0
			bcc set_next_tile3
		jmp finished_refeshing
		:
		cmp #$03
		bne :+
		; Refresh the last top/middle 2 rows of the display area
			; Start position
			lda #$28
			sta $2006
			ldy #$D0
			sty $2006
			set_next_tile4:
			; Set next tile
			lda display_buff, y
			sta $2007
			iny
			cpy #$00
			bne set_next_tile4
		jmp finished_refeshing
		:
		cmp #$04
		bne :+
		; Refresh the 2 upper bottom/middle rows of the display area
			; Start position
			lda #$29
			sta $2006
			ldy #$00
			sty $2006
			; Start setting tiles
			set_next_tile5:
			; Set next tile
			lda display_buff_middle, y
			sta $2007
			iny
			cpy #$40
			bcc set_next_tile5
		jmp finished_refeshing
		:
		cmp #$05
		bne :+
		; Refresh the next 2 bottom/middle rows of the display area
			; Start position
			lda #$29
			sta $2006
			ldy #$40
			sty $2006
			set_next_tile6:
			; Set next tile
			lda display_buff_middle, y
			sta $2007
			iny
			cpy #$80
			bne set_next_tile6
		jmp finished_refeshing
		:
		cmp #$06
		bne :+
		; Refresh the 2 upper bottom rows of the display area
			; Start position
			lda #$29
			sta $2006
			ldy #$80
			sty $2006
			; Start setting tiles
			set_next_tile7:
			; Set next tile
			lda display_buff_middle, y
			sta $2007
			iny
			cpy #$D0
			bcc set_next_tile7
		jmp finished_refeshing
		:
		cmp #$07
		bne finished_refeshing
		; Refresh the last and closest to the bottom 2 rows of the display area
			; Start position
			lda #$29
			sta $2006
			ldy #$D0
			sty $2006
			set_next_tile8:
			; Set next tile
			lda display_buff_middle, y
			sta $2007
			iny
			cpy #$00
			bne set_next_tile8
	finished_refeshing:
	inc display_frame
	lda display_frame
	and #$07
	sta display_frame

	; Check if we are in the overworld
		lda time_since_tunnel
		bne :+
		jmp :+++
		:
		; Dimming the sky
		cmp #$68
		beq :+
		jmp nmi_in_the_end
		:
		lda #$3F
		sta $2006
		lda #$00
		sta $2006
		lda #$0F
		sta $2007
		; Enable only the noise channel
		lda #$08
		sta apu_enable
		; Make the noise channel sound like flapping wings
		; Configure playback sample rate
		lda #%00000010
		sta $400E
		; Configure length counter load value
		lda #%01001111
		sta $400F
		; Optional: Initialize $400C
		lda #%00100111
		sta $400C
		; Change the color palette for the ender dragon
		lda #$3F
		sta $2006
		lda #$19
		sta $2006
		lda #$13
		sta $2007
		lda #$00
		sta $2007
		lda #$10
		sta $2007
		; Change the background color palette for the endstone
		lda #$3F
		sta $2006
		lda #$01
		sta $2006
		lda #$37
		sta $2007
		lda #$14
		sta $2007
		lda #$04
		sta $2007
		; Change the background color palette for the dragon's perch
		lda #$3F
		sta $2006
		lda #$09
		sta $2006
		lda #$01
		sta $2007
		lda #$14
		sta $2007
		; Restart the time at zero
		lda #$0F
		sta scroll_time
		; Setup the dragon energy sprites
		ldx #$49
		stx $02F1
		ldy #$02
		sty $02F2
		stx $02F5
		sty $02F6
		stx $02F9
		sty $02FA
		stx $02FD
		sty $02FE
		lda #$FF
		sta dragon_energy_1_y
		sta dragon_energy_2_y
		sta dragon_energy_3_y
		sta dragon_energy_4_y
		; Setup the crossbow arrow sprite
			; Vertical position
				lda #$FF
				sta crossbow_arrow_y
			; Attributes
				lda #$46
				sta $0205
				lda #$00
				sta $0206
			; Horizontal position
				lda #$7C
				sta $0207
		jmp nmi_in_the_end
		:

	; Change sky color based on day time
		lda day_time
		ldx #$3F
		ldy #$00
		; Cyan
		cmp #$18
		bne :+
		stx $2006
		sty $2006
		lda #$21
		sta $2007
		jmp done_changing_sky_color
		:
		; Pink clouds
		cmp #$20
		bne :+
		stx $2006
		lda #$1B
		sta $2006
		lda #$26
		sta $2007
		jmp done_changing_sky_color
		; Orange
		cmp #$30
		bne :+
		stx $2006
		sty $2006
		lda #$27
		sta $2007
		jmp done_changing_sky_color
		:
		; Pink
		cmp #$38
		bne :+
		stx $2006
		sty $2006
		lda #$15
		sta $2007
		jmp done_changing_sky_color
		:
		; Dark Blue
		cmp #$40
		bne :+
		stx $2006
		sty $2006
		lda #$02
		sta $2007
		jmp done_changing_sky_color
		:
		; Darker Blue
		cmp #$44
		bne :+
		stx $2006
		sty $2006
		lda #$01
		sta $2007
		stx $2006
		lda #$1B
		sta $2006
		lda #$02
		sta $2007
		jmp done_changing_sky_color
		:
		; Black
		cmp #$48
		bne :+
		stx $2006
		sty $2006
		lda #$0F
		sta $2007
		stx $2006
		lda #$1B
		sta $2006
		lda #$0F
		sta $2007
		jmp done_changing_sky_color
		:
		; Darker Blue
		cmp #$7C
		bne :+
		stx $2006
		sty $2006
		lda #$01
		sta $2007
		stx $2006
		lda #$1B
		sta $2006
		lda #$01
		sta $2007
		jmp done_changing_sky_color
		:
		; Dark Blue
		cmp #$80
		bne :+
		stx $2006
		sty $2006
		lda #$02
		sta $2007
		stx $2006
		lda #$1B
		sta $2006
		lda #$10
		sta $2007
		jmp done_changing_sky_color
		:
		; Pink
		cmp #$88
		bne :+
		stx $2006
		sty $2006
		lda #$15
		sta $2007
		jmp done_changing_sky_color
		:
		; Orange
		cmp #$90
		bne :+
		stx $2006
		sty $2006
		lda #$27
		sta $2007
		jmp done_changing_sky_color
		:
		; Cyan
		cmp #$98
		bne :+
		stx $2006
		sty $2006
		lda #$21
		sta $2007
		stx $2006
		lda #$1B
		sta $2006
		lda #$30
		sta $2007
		jmp done_changing_sky_color
		:
		; Sky blue
		cmp #$A8
		bne :+
		stx $2006
		sty $2006
		lda #$22
		sta $2007
		:
		done_changing_sky_color:

	; Update the background pallette for the inventory screen
		lda inventory_pallete_update
		cmp #$01
		bne :+
		ldx #$3F
		stx $2006
		lda #$09
		sta $2006
		lda #$09
		sta $2007
		stx $2006
		lda #$0A
		sta $2006
		lda #$28
		sta $2007
		stx $2006
		lda #$0B
		sta $2006
		lda #$36
		sta $2007
		lda #$FF
		sta inventory_pallete_update
		jmp :++
		:
		lda inventory_pallete_update
		cmp #$00
		bne :+
		ldx #$3F
		stx $2006
		lda #$09
		sta $2006
		lda #$17
		sta $2007
		stx $2006
		lda #$0A
		sta $2006
		lda #$2A
		sta $2007
		stx $2006
		ldx #$0B
		stx $2006
		stx $2007
		lda #$FF
		sta inventory_pallete_update
		lda #$00 ; Stop alll currently running animatins running in the inventory if it's being closed
		sta sound_change_animation_time ; We don't want any loose sprites hanging around
		:

	; Change pallettes after death
		lda time_since_died
		cmp #$18
		bcc :+
		ldx #$3F

		ldy #$16
		stx $2006
		lda #$01
		sta $2006
		sty $2007
		stx $2006
		lda #$09
		sta $2006
		sty $2007

		ldy #$28
		stx $2006
		lda #$02
		sta $2006
		sty $2007
		stx $2006
		lda #$0A
		sta $2006
		sty $2007
		
		ldy #$08
		stx $2006
		lda #$03
		sta $2006
		sty $2007
		stx $2006
		lda #$0B
		sta $2006
		sty $2007
		:
	
	jmp :+
	nmi_in_the_end:
		; Render sprites
		lda #$02
		sta $4014
		; Sprite zero hit
		wait_sprite:
    	bit $2002           ; read PPUSTATUS
    	bvs wait_sprite
		lda #$01
		sta sprite_zero_hit
		jmp putting_registers_back
	:

	; Update color emphasis
		lda color_emphasis
		clc
		adc #%00011110
		sta $2001

	; Render sprites
		lda #$02
		sta $4014
	
	putting_registers_back:
	; Set screen scroll offset
		bit $2002
		lda #$07
		sec
		sbc end_scroll
		sta $2005
		lda #$E4
		sta $2005
		lda #%10010010
		sec
		sbc in_game
		sta $2000

	; Decrease frame wait
		lda frame_wait
		beq :+
		dec frame_wait
		:
	
	; Put registers back and return to interupted code
		pla
		tay
		pla
		tax
		pla
		rti

sin_values:
	.byte 000, 003, 006, 009, 012, 016, 019, 022, 025, 028, 031, 034, 037, 040, 043, 046, 049, 051, 054, 057, 060, 063, 065, 068, 071, 073, 076, 078, 081, 083, 085, 088
	.byte 090, 092, 094, 096, 098, 100, 102, 104, 106, 107, 109, 111, 112, 113, 115, 116, 117, 118, 120, 121, 122, 122, 123, 124, 125, 125, 126, 126, 126, 127, 127, 127

raycasting_lookup:
	.incbin "raycasting_lookup.bin"

square_low_lookup:
	.byte $00, $01, $04, $09, $10, $19, $24, $31, $40, $51, $64, $79, $90, $A9, $C4, $E1
	.byte $00, $21, $44, $69, $90, $B9, $E4, $11, $40, $71, $A4, $D9, $10, $49, $84, $C1
	.byte $00, $41, $84, $C9, $10, $59, $A4, $F1, $40, $91, $E4, $39, $90, $E9, $44, $A1
	.byte $00, $61, $C4, $29, $90, $F9, $64, $D1, $40, $B1, $24, $99, $10, $89, $04, $81
	.byte $00, $81, $04, $89, $10, $99, $24, $B1, $40, $D1, $64, $F9, $90, $29, $C4, $61
	.byte $00, $A1, $44, $E9, $90, $39, $E4, $91, $40, $F1, $A4, $59, $10, $C9, $84, $41
	.byte $00, $C1, $84, $49, $10, $D9, $A4, $71, $40, $11, $E4, $B9, $90, $69, $44, $21
	.byte $00, $E1, $C4, $A9, $90, $79, $64, $51, $40, $31, $24, $19, $10, $09, $04, $01 ; The low bytes repeat, so we only need 128 bytes here
square_high_lookup:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $01, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $03, $03, $03, $03
	.byte $04, $04, $04, $04, $05, $05, $05, $05, $06, $06, $06, $07, $07, $07, $08, $08
	.byte $09, $09, $09, $0A, $0A, $0A, $0B, $0B, $0C, $0C, $0D, $0D, $0E, $0E, $0F, $0F
	.byte $10, $10, $11, $11, $12, $12, $13, $13, $14, $14, $15, $15, $16, $17, $17, $18
	.byte $19, $19, $1A, $1A, $1B, $1C, $1C, $1D, $1E, $1E, $1F, $20, $21, $21, $22, $23
	.byte $24, $24, $25, $26, $27, $27, $28, $29, $2A, $2B, $2B, $2C, $2D, $2E, $2F, $30
	.byte $31, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F
	.byte $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F
	.byte $51, $52, $53, $54, $55, $56, $57, $59, $5A, $5B, $5C, $5D, $5F, $60, $61, $62
	.byte $64, $65, $66, $67, $69, $6A, $6B, $6C, $6E, $6F, $70, $72, $73, $74, $76, $77
	.byte $79, $7A, $7B, $7D, $7E, $7F, $81, $82, $84, $85, $87, $88, $8A, $8B, $8D, $8E
	.byte $90, $91, $93, $94, $96, $97, $99, $9A, $9C, $9D, $9F, $A0, $A2, $A4, $A5, $A7
	.byte $A9, $AA, $AC, $AD, $AF, $B1, $B2, $B4, $B6, $B7, $B9, $BB, $BD, $BE, $C0, $C2
	.byte $C4, $C5, $C7, $C9, $CB, $CC, $CE, $D0, $D2, $D4, $D5, $D7, $D9, $DB, $DD, $DF
	.byte $E1, $E2, $E4, $E6, $E8, $EA, $EC, $EE, $F0, $F2, $F4, $F6, $F8, $FA, $FC, $FE

line_height_lookup_1:
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3C, $39, $37, $35, $33, $31, $30, $2E, $2D, $2C, $2A, $29, $28, $28, $27, $26, $25, $24, $24, $23, $23, $22, $21, $21, $20, $20, $20, $1F, $1F, $1E, $1E, $1D, $1D, $1D, $1C, $1C, $1C, $1C, $1B, $1B, $1B, $1A, $1A, $1A, $1A, $19, $19, $19, $19, $18, $18, $18, $18, $18
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3D, $3A, $37, $35, $33, $31, $30, $2E, $2D, $2C, $2B, $2A, $29, $28, $27, $26, $25, $25, $24, $23, $23, $22, $22, $21, $21, $20, $20, $1F, $1F, $1E, $1E, $1E, $1D, $1D, $1D, $1C, $1C, $1C, $1B, $1B, $1B, $1B, $1A, $1A, $1A, $1A, $19, $19, $19, $19, $18, $18, $18, $18
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3E, $3B, $38, $36, $34, $32, $31, $2F, $2E, $2D, $2C, $2A, $29, $29, $28, $27, $26, $25, $25, $24, $23, $23, $22, $22, $21, $21, $20, $20, $1F, $1F, $1F, $1E, $1E, $1E, $1D, $1D, $1D, $1C, $1C, $1C, $1B, $1B, $1B, $1B, $1A, $1A, $1A, $1A, $19, $19, $19, $19, $19, $18
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3D, $3A, $38, $36, $34, $32, $31, $2F, $2E, $2D, $2C, $2B, $2A, $29, $28, $27, $27, $26, $25, $25, $24, $23, $23, $22, $22, $21, $21, $20, $20, $20, $1F, $1F, $1E, $1E, $1E, $1D, $1D, $1D, $1D, $1C, $1C, $1C, $1B, $1B, $1B, $1B, $1A, $1A, $1A, $1A, $1A, $19, $19
line_height_lookup_2:
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3D, $3A, $38, $36, $35, $33, $32, $30, $2F, $2E, $2D, $2C, $2B, $2A, $29, $28, $28, $27, $26, $26, $25, $25, $24, $23, $23, $22, $22, $22, $21, $21, $20, $20, $20, $1F, $1F, $1F, $1E, $1E, $1E, $1D, $1D, $1D, $1C, $1C, $1C, $1C, $1B, $1B, $1B, $1B, $1B, $1A
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3E, $3C, $3A, $38, $36, $35, $33, $32, $31, $30, $2F, $2E, $2D, $2C, $2B, $2A, $29, $29, $28, $27, $27, $26, $26, $25, $25, $24, $24, $23, $23, $22, $22, $22, $21, $21, $20, $20, $20, $1F, $1F, $1F, $1F, $1E, $1E, $1E, $1D, $1D, $1D, $1D, $1C, $1C, $1C
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3F, $3D, $3B, $39, $38, $36, $35, $34, $32, $31, $30, $2F, $2F, $2E, $2D, $2C, $2B, $2B, $2A, $29, $29, $28, $28, $27, $27, $26, $26, $25, $25, $24, $24, $24, $23, $23, $22, $22, $22, $21, $21, $21, $20, $20, $20, $20, $1F, $1F, $1F, $1F, $1E
	.byte $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $40, $3F, $3D, $3C, $3A, $39, $38, $37, $35, $34, $33, $32, $32, $31, $30, $2F, $2E, $2E, $2D, $2C, $2C, $2B, $2B, $2A, $2A, $29, $29, $28, $28, $27, $27, $26, $26, $26, $25, $25, $25, $24, $24, $24, $23, $23, $23, $22, $22, $22, $21

tile_optimization:
	;.byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
	;.byte $10, $11, 
	.byte           $00, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $0A, $1D, $1E, $1F
	.byte $20, $21, $22, $23, $00, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $0A, $2F
	.byte $30, $31, $32, $33, $34, $35, $00, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3E
	.byte $0A, $41, $42, $43, $44, $45, $46, $47, $00, $49, $4A, $4B, $4C, $4D, $4E, $4F
	.byte $50, $50, $0A, $53, $54, $55, $56, $57, $58, $59, $00, $5B, $5C, $5D, $5E, $5F
	.byte $60, $61, $62, $62, $0A, $65, $66, $67, $68, $69, $6A, $6B, $0A, $6D, $6E, $6F
	.byte $70, $71, $72, $73, $74, $74, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $0A, $7F
	.byte $80, $81, $82, $83, $84, $85, $86, $86, $76, $89, $8A, $8B, $8C, $8D, $8E, $8F
	.byte $0A, $91, $92, $93, $94, $95, $96, $97, $98, $98, $76, $9B, $9C, $9D, $9E, $9F
	.byte $A0, $A1, $00, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AA, $0A, $AD, $AE, $AF
	.byte $B0, $B1, $B2, $B3, $00, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BC, $0A, $BF
	.byte $C0, $C1, $C2, $C3, $C4, $C5, $00, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CE
	.byte $0A, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
	.byte $E0, $E0, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $76, $EC, $ED, $EE, $EF
	.byte $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $2D, $FF

palettes:
	.byte $22,$17,$2A,$0B, $22,$10,$3D,$2D, $22,$17,$2A,$0B, $22,$08,$16,$20 ; Background
	.byte $22,$07,$08,$35, $22,$0F,$30,$2C, $22,$28,$38,$20, $22,$0A,$1A,$29 ; Sprites

name_table_tiles_attributes:
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$88,$AA,$AA,$AA,$AA,$AA,$00
	.byte $00,$88,$AA,$AA,$AA,$AA,$AA,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F
	.byte $55,$55,$55,$55,$55,$55,$55,$55
	.byte $55,$55,$55,$55,$55,$55,$51,$55

name_table_tiles:
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F1,$00,$00,$00,$F1,$00,$F1,$F1,$F1,$F1,$00,$00,$F1,$F1,$00,$00
	.byte $00,$00,$F0,$00,$F0,$00,$F0,$F0,$00,$00,$F0,$00,$00,$00,$F0,$00,$F1,$F1,$00,$00,$F1,$00,$F1,$00,$00,$00,$00,$F1,$00,$00,$F1,$00
	.byte $00,$00,$F0,$F0,$00,$F0,$00,$00,$F0,$00,$F0,$00,$00,$00,$F0,$00,$F1,$F1,$F1,$00,$F1,$00,$F1,$00,$00,$00,$00,$F1,$00,$00,$00,$00
	.byte $00,$00,$F0,$00,$00,$F0,$00,$00,$F0,$00,$00,$F0,$00,$F0,$00,$00,$F1,$00,$F1,$00,$F1,$00,$F1,$F1,$F1,$00,$00,$00,$F1,$F1,$00,$00
	.byte $00,$00,$F0,$00,$00,$F0,$00,$00,$F0,$00,$00,$F0,$00,$F0,$00,$00,$F1,$00,$F1,$F1,$F1,$00,$F1,$00,$00,$00,$00,$00,$00,$00,$F1,$00
	.byte $00,$00,$F0,$00,$00,$F0,$00,$00,$F0,$00,$00,$00,$F0,$00,$00,$00,$F1,$00,$00,$F1,$F1,$00,$F1,$00,$00,$00,$00,$F1,$00,$00,$F1,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$00,$00,$00,$F1,$00,$00,$00,$F1,$00,$F1,$F1,$F1,$F1,$00,$00,$F1,$F1,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$F2,$F2,$F2,$00,$F2,$F2,$F2,$00,$00,$00,$00,$F2,$00,$00,$00,$F2,$F2,$F2,$F2,$00,$F2,$F2,$F2,$F2,$F2,$00,$00,$00,$00
	.byte $00,$00,$F2,$00,$00,$00,$00,$F2,$00,$00,$F2,$00,$00,$F2,$00,$F2,$00,$00,$F2,$00,$00,$00,$00,$00,$00,$F2,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$F2,$00,$00,$00,$00,$F2,$00,$F2,$F2,$00,$F2,$00,$00,$00,$F2,$00,$F2,$00,$00,$00,$00,$00,$00,$F2,$00,$F7,$F6,$F8,$F3,$F3
	.byte $00,$00,$F2,$00,$00,$00,$00,$F2,$F2,$00,$00,$00,$F2,$F2,$F2,$F2,$F2,$00,$F2,$F2,$F2,$00,$00,$00,$00,$F2,$00,$0A,$0A,$0A,$0A,$0A
	.byte $00,$00,$F2,$00,$00,$00,$00,$F2,$00,$F2,$00,$00,$F2,$00,$00,$00,$F2,$00,$F2,$00,$00,$00,$00,$00,$00,$F2,$00,$F3,$F4,$F5,$F6,$F4
	.byte $00,$00,$00,$F2,$F2,$F2,$00,$F2,$00,$00,$F2,$00,$F2,$00,$00,$00,$F2,$00,$F2,$00,$00,$00,$00,$00,$00,$F2,$00,$00,$00,$00,$00,$00
	.byte $00,$F0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$AB,$AB,$AB,$AB,$AB,$AB,$AB,$AB,$AB,$AB,$00,$00,$00,$00,$00,$BD,$BD,$BD,$BD,$BD,$BD,$BD,$BD,$BD,$BD,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$CF,$D0,$00,$00
	.byte $00,$00,$00,$00,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$00,$00,$00
	.byte $00,$00,$00,$00,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00
	.byte $00,$00,$00,$00,$76,$76,$76,$76,$EE,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$EF,$76,$76,$76,$76,$00,$00,$00
	.byte $00,$00,$00,$00,$76,$76,$76,$76,$EE,$EC,$FF,$ED,$2D,$EC,$FF,$ED,$2D,$EC,$FF,$ED,$2D,$EC,$FF,$ED,$EF,$76,$76,$76,$76,$00,$00,$00
	.byte $00,$00,$00,$00,$76,$76,$76,$76,$EE,$EC,$FF,$ED,$2D,$EC,$FF,$ED,$2D,$EC,$FF,$ED,$2D,$EC,$FF,$ED,$EF,$76,$F0,$F0,$76,$00,$00,$00
	.byte $00,$00,$00,$00,$76,$76,$76,$76,$EE,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$2D,$EF,$76,$EB,$F0,$76,$00,$00,$00
	.byte $00,$00,$00,$00,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$76,$00,$00,$00

starting_blocks:
	.byte $00,$00,$00,$00,$00,$00,$20,$22,$20,$00,$00,$01,$00,$01,$00,$00
	.byte $00,$00,$44,$44,$44,$44,$44,$20,$00,$00,$00,$00,$20,$00,$00,$00
	.byte $00,$00,$44,$55,$55,$55,$44,$00,$00,$00,$00,$20,$22,$20,$00,$00
	.byte $00,$00,$44,$55,$00,$00,$00,$00,$20,$00,$00,$00,$20,$00,$00,$00
	.byte $00,$00,$44,$55,$00,$00,$44,$20,$22,$20,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$44,$55,$55,$55,$44,$00,$20,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$44,$44,$44,$44,$44,$00,$00,$00,$01,$01,$01,$01,$01,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$11,$11,$11,$11,$11,$01
	.byte $01,$00,$00,$00,$00,$20,$00,$00,$01,$11,$11,$33,$33,$33,$11,$11
	.byte $01,$20,$00,$00,$20,$22,$20,$00,$01,$11,$33,$33,$30,$33,$33,$11
	.byte $21,$22,$20,$00,$00,$20,$00,$00,$01,$11,$33,$30,$00,$03,$33,$11
	.byte $01,$20,$00,$00,$00,$00,$00,$00,$01,$11,$33,$00,$00,$00,$33,$11
	.byte $01,$00,$00,$00,$00,$00,$00,$00,$01,$11,$33,$30,$00,$33,$33,$11
	.byte $01,$20,$00,$00,$00,$00,$00,$00,$01,$11,$11,$33,$00,$33,$11,$11
	.byte $20,$22,$20,$00,$00,$00,$00,$00,$00,$01,$11,$10,$00,$10,$11,$01
	.byte $00,$20,$00,$00,$00,$00,$00,$20,$00,$00,$01,$11,$00,$11,$01,$00
	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $11,$11,$00,$00,$11,$11,$11,$11, $11, $11, $11, $11, $11, $00, $00, $00
	; .byte $11,$11,$00,$00,$11,$11,$11,$11, $11, $11, $11, $11, $11, $00, $00, $00
	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $11,$11,$11,$11,$11,$11,$11,$11, $00, $00, $11, $11, $00, $00, $11, $11
	; .byte $11,$11,$11,$11,$11,$11,$11,$11, $00, $00, $11, $11, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$11,$11,$00,$00, $00, $00, $00, $00, $00, $00, $00, $00
	; .byte $00,$00,$00,$00,$11,$11,$00,$00, $00, $00, $00, $00, $00, $00, $00, $00
	; .byte $00,$00,$00,$00,$11,$11,$11,$11, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$11,$11,$11,$11, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$11,$11,$11,$11, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$11,$11,$11,$11, $00, $00, $00, $00, $00, $00, $11, $11
	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $00, $00, $00, $00, $00, $00, $00, $00
	; .byte $00,$00,$00,$00,$00,$00,$00,$00, $00, $00, $00, $00, $00, $00, $00, $00

wall_type_to_tile_type:
	.byte 00, 54, 00, 108, 162, 216, 54, 54, 54, 54, 54, 54, 54, 54, 54, 162

jingles:
	; Enter game
	.byte $C0, $C0, $C0, $B0, $B0, $A0, $A0, $90 ; #$00
	.byte $78, $78, $78, $7F, $7F, $7F, $7F, $00
	; Open inventory
	.byte $24, $22, $20, $34, $32, $30, $00, $00 ; #$10
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	; Close inventory
	.byte $80, $80, $40, $20, $00, $30, $32, $34 ; #$20
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	; Pause from inventory
	.byte $80, $70, $60, $00, $90, $A0, $00, $00 ; #$30
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	; When the game starts up on the titlescreen
	.byte $C0, $C0, $C0, $D0, $D0, $E0, $E0, $F0 ; #$40
	.byte $F0, $F0, $E8, $D0, $B0, $80, $00, $00
	; When sound effects are turned off
	.byte $20, $20, $20, $40, $40, $40, $48, $48 ; #$50
	.byte $48, $4C, $4C, $4C, $80, $80, $81, $00
	; When sound effects are turned on
	.byte $80, $78, $70, $68, $60, $58, $50, $40 ; #$60
	.byte $30, $20, $18, $00, $00, $00, $00, $00
	; When a wooden pickaxe is made
	.byte $60, $60, $00, $00, $00, $60, $60, $00 ; #$70
	.byte $00, $00, $00, $50, $45, $42, $30, $00
	; Death music
	.byte $80, $80, $70, $70, $71, $71, $70, $70 ; #$80
	.byte $00, $00, $7F, $80, $81, $82, $00, $00
	.byte $60, $60, $00, $00, $70, $70, $70, $00 ; #$90
	.byte $00, $80, $82, $80, $82, $00, $A0, $00
	.byte $B0, $B0, $B0, $B0, $C0, $C0, $C0, $C0 ; #$A0
	.byte $D0, $D0, $E0, $F0, $F0, $F0, $F0, $00
	; Lithium pickaxe breaking jingle
	.byte $80, $80, $00, $80, $00, $E5, $80, $00 ; #$B0
	.byte $00, $80, $00, $E5, $00, $80, $80, $80
    .byte $88, $88, $00, $88, $00, $01, $88, $00 ; #$C0
	.byte $00, $88, $00, $01, $00, $88, $88, $88

bg_music_pulse_2:
	.incbin "bg_music_pulse_2.bin"

bg_music_pulse_1:
	.incbin "bg_music_pulse_1.bin"

bg_music_triangle:
	.incbin "bg_music_triangle.bin"

midi_to_freq_low:
        .byte $B4, $8D, $68, $45, $24, $05, $E7, $CC, $B2, $99, $82, $6C, $58, $44, $32, $21
        .byte $10, $01, $F2, $E5, $D8, $CC, $C0, $B5, $AB, $A1, $98, $90, $88, $80, $79, $72
        .byte $6B, $65, $60, $5A, $55, $50, $4C, $47, $43, $40, $3C, $39, $35, $32, $30, $2D
        .byte $2A, $28, $26, $23, $21, $20, $1E, $1C, $1A, $19, $18, $16, $15, $14, $13, $11
        .byte $10, $10, $0F, $0E, $0D, $0C, $0C, $0B, $0A, $0A, $09, $08, $08, $08, $07, $07
        .byte $06, $06, $05, $05, $05, $05, $04, $04, $04, $04, $03, $03, $03, $03, $02, $02
        .byte $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
        .byte $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00

midi_to_freq_high:
        .byte $02, $02, $02, $02, $02, $02, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
        .byte $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00

end_crystal_pos:
	.byte $08, $07, $04, $02, $01, $00, $00, $01, $03, $06, $0A, $0D, $0F, $0E, $0C, $0A

dragon_motion_x:
	.byte $00, $00, $FD, $FE, $FF, $04, $02, $01, $03, $02, $FF, $01, $FD, $FE, $FF, $00

dragon_motion_y:
	.byte $00, $FE, $FF, $02, $00, $FF, $FF, $00, $01, $00, $01, $00, $FF, $FE, $02, $02

end_poem_text:
	.incbin "end_poem_text.bin"

end_poem_formatting:
	.incbin "end_poem_formatting.bin"

end_poem_music:
	.byte $80, $70, $60, $50, $40 ; #$04
	.byte $38, $4B, $38, $4B, $38, $4B, $38, $4B, $38, $4B, $38, $4B, $54, $5F, $4B, $4B
	.byte $5F, $54, $3F, $43, $3F, $38, $43, $54, $38, $54, $38, $54, $38, $5A, $38, $5A
	.byte $38, $5A, $35, $5A, $38, $47, $38, $47, $3F, $38, $3F, $71, $47, $71, $4B, $71 ; #$34

end_poem_music_low:
	.byte $8F, $71, $5F, $4B
	.byte $8F, $71, $5F, $71
	.byte $5F, $71, $97, $71
	.byte $5F, $71, $5F, $71

.segment "PIG_SOUND" ; $F000 -> $FC00
.incbin "pig_sound.dmc"

.segment "COW_SOUND" ; $FC00 -> $FFFF
.incbin "cow_sound.dmc"

.segment "VECTORS"
.word NMI
.word reset

.segment "CHARS"
.incbin "char_rom.chr"
