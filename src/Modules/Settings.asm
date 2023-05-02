;**** **** **** **** **** **** **** **** **** **** **** **** ****
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Settings
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
;**** **** **** **** **** **** **** **** **** **** **** **** ****

FLAG_SETTINGS_EDT_REQUIRED_ARM_FLAG     EQU 001h


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Set default parameters
;
; Sets default programming parameters
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
set_default_parameters:
    mov Temp1, #_Pgm_Gov_P_Gain
    mov @Temp1, #0FFh                       ; _Pgm_Gov_P_Gain
    imov    Temp1, #DEFAULT_PGM_STARTUP_POWER_MIN   ; Pgm_Startup_Power_Min
    imov    Temp1, #DEFAULT_PGM_STARTUP_BEEP        ; Pgm_Startup_Beep
    imov    Temp1, #DEFAULT_PGM_DITHERING           ; Pgm_Dithering
    imov    Temp1, #DEFAULT_PGM_STARTUP_POWER_MAX   ; Pgm_Startup_Power_Max
    imov    Temp1, #0FFh                        ; _Pgm_Rampup_Slope
    imov    Temp1, #DEFAULT_PGM_RPM_POWER_SLOPE ; Pgm_Rpm_Power_Slope
    imov    Temp1, #(24 SHL PWM_FREQ)           ; Pgm_Pwm_Freq
    imov    Temp1, #DEFAULT_PGM_DIRECTION           ; Pgm_Direction
    imov    Temp1, #0FFh                        ; _Pgm_Input_Pol

    inc Temp1                           ; Skip Initialized_L_Dummy
    inc Temp1                           ; Skip Initialized_H_Dummy

    imov    Temp1, #0FFh                        ; _Pgm_Enable_TX_Program
    imov    Temp1, #DEFAULT_PGM_BRAKING_STRENGTH    ; Pgm_Braking_Strength
    imov    Temp1, #0FFh                        ; _Pgm_Gov_Setup_Target
    imov    Temp1, #0FFh                        ; _Pgm_Startup_Rpm
    imov    Temp1, #0FFh                        ; _Pgm_Startup_Accel
    imov    Temp1, #0FFh                        ; _Pgm_Volt_Comp
    imov    Temp1, #DEFAULT_PGM_COMM_TIMING     ; Pgm_Comm_Timing
    imov    Temp1, #0FFh                        ; _Pgm_Damping_Force
    imov    Temp1, #0FFh                        ; _Pgm_Gov_Range
    imov    Temp1, #0FFh                        ; _Pgm_Startup_Method
    imov    Temp1, #0FFh                        ; _Pgm_Min_Throttle
    imov    Temp1, #0FFh                        ; _Pgm_Max_Throttle
    imov    Temp1, #DEFAULT_PGM_BEEP_STRENGTH       ; Pgm_Beep_Strength
    imov    Temp1, #DEFAULT_PGM_BEACON_STRENGTH ; Pgm_Beacon_Strength
    imov    Temp1, #DEFAULT_PGM_BEACON_DELAY        ; Pgm_Beacon_Delay
    imov    Temp1, #0FFh                        ; _Pgm_Throttle_Rate
    imov    Temp1, #DEFAULT_PGM_DEMAG_COMP      ; Pgm_Demag_Comp
    imov    Temp1, #0FFh                        ; _Pgm_BEC_Voltage_High
    imov    Temp1, #0FFh                        ; _Pgm_Center_Throttle
    imov    Temp1, #0FFh                        ; _Pgm_Main_Spoolup_Time
    imov    Temp1, #DEFAULT_PGM_ENABLE_TEMP_PROT    ; Pgm_Enable_Temp_Prot
    imov    Temp1, #0FFh                        ; _Pgm_Enable_Power_Prot
    imov    Temp1, #0FFh                        ; _Pgm_Enable_Pwm_Input
    imov    Temp1, #0FFh                        ; _Pgm_Pwm_Dither
    imov    Temp1, #DEFAULT_PGM_BRAKE_ON_STOP       ; Pgm_Brake_On_Stop
    imov    Temp1, #DEFAULT_PGM_LED_CONTROL     ; Pgm_LED_Control
    imov    Temp1, #DEFAULT_PGM_POWER_RATING    ; Pgm_Power_Rating
    imov    Temp1, #DEFAULT_VAR_PWM_LO_THRES    ; Pgm_Var_PWM_lo_thres
    imov    Temp1, #DEFAULT_VAR_PWM_HI_THRES	; Pgm_Var_PWM_hi_thres
    imov    Temp1, #DEFAULT_FORCE_EDT_ARM       ; Pgm_Flag_Settings

    ret


;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; Decode settings
;
; Decodes programmed settings and set RAM variables accordingly
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
decode_settings:
    mov Temp1, #Pgm_Direction       ; Load programmed direction
    mov A, @Temp1
    dec A
    mov C, ACC.1                    ; Set bidirectional mode
    mov Flag_Pgm_Bidir, C
    mov C, ACC.0                    ; Set direction (Normal / Reversed)
    mov Flag_Pgm_Dir_Rev, C

    ; Check startup power
    mov Temp1, #Pgm_Startup_Power_Max
    mov A, #80                  ; Limit to at most 80
    subb    A, @Temp1
    jnc ($+4)
    mov @Temp1, #80

    ; Check low rpm power slope
    mov Temp1, #Pgm_Rpm_Power_Slope
    mov A, #13                  ; Limit to at most 13
    subb    A, @Temp1
    jnc ($+4)
    mov @Temp1, #13

    mov Low_Rpm_Pwr_Slope, @Temp1

    ; Decode demag compensation
    mov Temp1, #Pgm_Demag_Comp
    mov A, @Temp1
    mov Demag_Pwr_Off_Thresh, #255  ; Set default

    cjne    A, #2, decode_demag_high

    mov Demag_Pwr_Off_Thresh, #160  ; Settings for demag comp low

decode_demag_high:
    cjne    A, #3, decode_demag_done

    mov Demag_Pwr_Off_Thresh, #130  ; Settings for demag comp high

decode_demag_done:
    ; Decode temperature protection limit
    mov Temp_Prot_Limit, #0
    mov Temp1, #Pgm_Enable_Temp_Prot
    mov A, @Temp1
    mov Temp2, A                   ; Temp2 = *Pgm_Enable_Temp_Prot;
    jz  decode_temp_done

    ; ******************************************************************
    ; Power rating only applies to BB21 because voltage references behave diferently
    ; depending on an external voltage regulator is used or not.
    ; For BB51 (MCU_TYPE == 2) 1s power rating code path is mandatory
    ; ******************************************************************
IF MCU_TYPE < 2
    ; Read power rating and decode temperature limit
    mov Temp1, #Pgm_Power_Rating
    cjne @Temp1, #01h, decode_temp_use_adc_use_vdd_3V3_vref
ENDIF

    ; Set A to temperature limit depending on power rating
decode_temp_use_adc_use_internal_1V65_vref:
    mov A, #(TEMP_LIMIT_1S - TEMP_LIMIT_STEP)
    sjmp    decode_temp_step
decode_temp_use_adc_use_vdd_3V3_vref:
    mov A, #(TEMP_LIMIT_2S - TEMP_LIMIT_STEP)

    ; Increase A while Temp2-- != 0;
decode_temp_step:
    add A, #TEMP_LIMIT_STEP
    djnz    Temp2, decode_temp_step

decode_temp_done:
    ; Set Temp_Prot_Limit to the temperature limit calculated in A
    mov Temp_Prot_Limit, A

    mov Temp1, #Pgm_Beep_Strength   ; Read programmed beep strength setting
    mov Beep_Strength, @Temp1       ; Set beep strength

    mov Temp1, #Pgm_Braking_Strength    ; Read programmed braking strength setting
    mov A, @Temp1

    ; Decode braking strength depending on PwmBitsCount
    mov Temp2, PwmBitsCount

decode_braking_strength_pwm11bits:
    cjne Temp2, #3, decode_braking_strength_pwm10bits

    ; Scale braking strength to pwm resolution
    ; Note: Added for completeness
    ; Currently 11-bit pwm is only used on targets with built-in dead time insertion
    rl  A
    rl  A
    rl  A
    mov Temp2, A
    anl A, #07h
    mov Pwm_Braking_H, A
    mov A, Temp2
    anl A, #0F8h
    mov Pwm_Braking_L, A
    sjmp decode_braking_strength_done

decode_braking_strength_pwm10bits:
    cjne Temp2, #2, decode_braking_strength_pwm9bits

    rl  A
    rl  A
    mov Temp2, A
    anl A, #03h
    mov Pwm_Braking_H, A
    mov A, Temp2
    anl A, #0FCh
    mov Pwm_Braking_L, A
    sjmp decode_braking_strength_done

decode_braking_strength_pwm9bits:
    cjne Temp2, #1, decode_braking_strength_pwm8bits

    rl  A
    mov Temp2, A
    anl A, #01h
    mov Pwm_Braking_H, A
    mov A, Temp2
    anl A, #0FEh
    mov Pwm_Braking_L, A
    sjmp decode_braking_strength_done

decode_braking_strength_pwm8bits:
    mov Pwm_Braking_H, #0
    mov Pwm_Braking_L, A

decode_braking_strength_done:
    cjne    @Temp1, #0FFh, decode_pwm_dithering
    mov Pwm_Braking_L, #0FFh        ; Apply full braking if setting is max

decode_pwm_dithering:
    mov Temp1, #Pgm_Dithering       ; Read programmed dithering setting
    mov A, @Temp1
    add A, #0FFh                    ; Carry set if A is not zero
    mov Flag_Dithering, C           ; Set dithering enabled

    ; Initialize unified dithering pattern table
    mov Temp1, #Dithering_Patterns  ; 3-bit dithering (8-bit to 11-bit)
    mov @Temp1, #00h                ; 00000000
    imov    Temp1, #01h             ; 00000001
    imov    Temp1, #11h             ; 00010001
    imov    Temp1, #25h             ; 00100101
    imov    Temp1, #55h             ; 01010101
    imov    Temp1, #5Bh             ; 01011011
    imov    Temp1, #77h             ; 01110111
    imov    Temp1, #7fh             ; 01111111

    ; Update Pgm_Var_PWM_hi_thres
    ; Bluejay needs hi threshold to be the loaded one minus lo threshold for later fast comparations
    clr C
    mov Temp1, #Pgm_Var_PWM_hi_thres
    mov A, @Temp1
    mov Temp1, #Pgm_Var_PWM_lo_thres
    subb A, @Temp1
    jnc decode_variable_pwm_threshold_update
decode_variable_pwm_threshold_correction:
    ; This makes hi threshold is the same than lo so 48khz is skipped
    clr A
decode_variable_pwm_threshold_update:
    ; Update hi threshold
    mov Temp1, #Pgm_Var_PWM_hi_thres
    mov @Temp1, A

decode_done:
    ; All decoding done
    ret

;**** **** **** **** **** **** **** **** **** **** **** **** ****
;
; pwm bits count calculation
;
;**** **** **** **** **** **** **** **** **** **** **** **** ****
calculate_pwm_bits:
    ; Number of bits in pwm high byte
    ; PWM_BITS_H  EQU (2 + IS_MCU_48MHZ - PWM_CENTERED - PWM_FREQ)
    clr C
    mov A, #2
    add A, #IS_MCU_48MHZ
    subb    A, #PWM_CENTERED

    ; Load and decode Pgm_Pwm_Freq [24, 48, 96] -> [0, 1, 2]
    ; Let Temp1 = Pgm_Pwm_Freq / 24
    mov Temp1, #Pgm_Pwm_Freq

calculate_pwm_bits_variable_pwm_bits:
    ; If pwm is variable do not substract and set variable pwm flag
    cjne    @Temp1, #192, calculate_pwm_bits_pwm96bits
    setb    Flag_Variable_Pwm_Bits
    sjmp    calculate_pwm_bits_pwm_decoded

calculate_pwm_bits_pwm96bits:
    ; If pwm is 96 khz substract 2
    cjne    @Temp1, #96, calculate_pwm_bits_pwm48bits
    subb    A, #2
    sjmp    calculate_pwm_bits_pwm_decoded

calculate_pwm_bits_pwm48bits:
    ; If pwm is 48 khz substract 1, otherwise do not substract (24khz)
    cjne    @Temp1, #48, calculate_pwm_bits_pwm_decoded
    subb    A, #1

calculate_pwm_bits_pwm_decoded:
    ; Clip result to [0-3] and store result
    anl A, #03h
    mov PwmBitsCount, A

calculate_pwm_bits_done:
    ret
