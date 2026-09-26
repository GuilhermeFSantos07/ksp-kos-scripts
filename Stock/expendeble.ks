CLEARSCREEN.

// PARÂMETROS DE MISSÃO
SET LATITUDE_BASE TO SHIP:LATITUDE. //Pega a latitude atual
SET INCLINACAO_ALVO TO 0. // Ajuste de inclinação
SET ALTITUDE_ORBITA TO 1000 * 150. //Orbita Alvo

// AJUSTES
SET VEL_ORBITAL_ALVO TO 2250. //Velocidade alvo
SET GT_VEL_INI TO 50. //Velocidade para começar a gravity turn
SET GT_ALT_END TO 1000 * 52. //Altitude Final da gravity turn
SET MAX_G TO 3.0. //Maximo de força G durante o lançamento
SET PRE_MECO_FUEL TO 150. //Inicialização do pré MECO

// CALCULO DE AZIMUTE DE LANÇAMENTO
LOCAL lat_rad IS LATITUDE_BASE * (CONSTANT:PI / 180).
LOCAL inc_rad IS INCLINACAO_ALVO * (CONSTANT:PI / 180).
LOCAL sin_raz IS COS (inc_rad) / COS (lat_rad).
LOCAL az_ideal IS ARCSIN (MIN(1.0, MAX(-1, sin_raz))).
// CALCULO DE VELOCIDADE DE ROTAÇÂO DO PLANETA
LOCAL v_kerbin IS (2 * CONSTANT:PI * SHIP:BODY:RADIUS / SHIP:BODY:ROTATIONPERIOD) * COS(lat_rad).
LOCAL v_leste IS (VEL_ORBITAL_ALVO * SIN(az_ideal)) - v_kerbin.
LOCAL v_norte IS VEL_ORBITAL_ALVO * COS(az_ideal).
// CALCULO FINAL
LOCAL AZIMUTE_FINAL IS ARCTAN2 (v_leste, v_norte).
IF AZIMUTE_FINAL < 0 {SET AZIMUTE_FINAL TO AZIMUTE_FINAL + 360.}

// INTERFACE DE TELEMETRIA
FUNCTION DESENHAR_TELA {
    CLEARSCREEN.
    PRINT "====================================================" AT (0,0).
    PRINT "         COMPUTADOR DE BORDO - SISTEMA GNC          " AT (0,1).
    PRINT "====================================================" AT (0,2).
    PRINT " STATS DE VOO               | METRICAS DO PEG       " AT (0,4).
    PRINT "----------------------------+-----------------------" AT (0,5).
    PRINT " Fase Atual :               | Tgo (Seg)   :         " AT (0,6).
    PRINT " Pitch Alvo :               | Pitch PEG   :         " AT (0,7).
    PRINT " Azimute    :               | Alt. Alvo   :         " AT (0,8).
    PRINT "----------------------------+-----------------------" AT (0,9).
    PRINT " TELEMETRIA DE ÓRBITA       | ESTADO DO VEÍCULO     " AT (0,10).
    PRINT "----------------------------+-----------------------" AT (0,11).
    PRINT " Altitude   :               | Empuxo      :         " AT (0,12).
    PRINT " Vel. Orbit :               | Massa       :         " AT (0,13).
    PRINT " Apoastro   :               | Throttle    :         " AT (0,14).
    PRINT " Periastro  :               | Staging     :         " AT (0,15).
    PRINT "====================================================" AT (0,16).
}

// INICIALIZAÇÃO E CONTAGEM
DESENHAR_TELA().
PRINT "AGUARDANDO LANÇAMENTO" AT (14,6). //Atualização da telemetria
PRINT ROUND (AZIMUTE_FINAL, 2) + " deg" AT(14,8). //Atualização da telemetria
PRINT ROUND (ALTITUDE_ORBITA/1000, 0) + " km" AT (43, 8). //Atualização da telemetria

FROM { LOCAL count IS 3. } UNTIL count = 0 STEP {SET count TO count - 1.} DO { //Countdown
    PRINT "CONTAGEM: " + count + " " AT (14, 6).
    WAIT 1.
}

// INICIALIZAÇÃO DE VARIAVEIS
LOCAL pitch_alvo IS 90. //Variavel para controlar o pitch
LOCAL direcao_alvo IS HEADING(AZIMUTE_FINAL, pitch_alvo). //Variavel para controlar a direção
LOCAL throttle_ideial IS 1.0. //Variavel para controlar o Throttle
LOCAL primeiro_estagio_con IS FALSE. //Variavel para controlar o MECO
LOCAL pre_meco_ativo IS FALSE. //Variavel para controlar o processo de MECO
LOCAL gt_com IS FALSE. //Variavel para controlar o começo da Gravity Turn
LOCAL gt_alt_com IS 0. //Variavel para controlar a altitude do começo da Gravity Turn

LOCK STEERING TO direcao_alvo.
LOCK THROTTLE TO throttle_ideial.
// DECOLAGEM
PRINT "DECOLAGEM" AT (14, 6).
STAGE.

// FASE 1: GRAVITY TURN
UNTIL SHIP:ALTITUDE >= GT_ALT_END {
    IF NOT gt_com AND SHIP:VELOCITY:SURFACE:MAG >= GT_VEL_INI {
        SET gt_com TO TRUE.
        SET gt_alt_com TO SHIP:ALTITUDE.
    }
    IF gt_com {
        LOCAL progresso IS MIN(1.0, MAX(0.0, (SHIP:ALTITUDE - gt_alt_com) / (GT_ALT_END - gt_alt_com))).
        SET pitch_alvo TO 90 - (90 * SQRT (progresso)).
    }

    // --- LÓGICA DE STAGING E PRE-MECO ---
    IF NOT primeiro_estagio_con {
        IF STAGE:LIQUIDFUEL < PRE_MECO_FUEL AND STAGE:LIQUIDFUEL > 1 {
            SET pre_meco_ativo TO TRUE.
            PRINT "PREP SEPARAÇÃO" AT (43, 15).
        }

        IF MAXTHRUST = 0 {
            SET pre_meco_ativo TO FALSE.
            SET throttle_ideial to 0.
            PRINT "SEPARANDO..." AT (43,15).
            WAIT 0.5.
            STAGE.
            WAIT 0.5.
            RCS ON.
            SET primeiro_estagio_con TO TRUE.
            PRINT "2º ESTAGIO" AT (43,15). 
        }
    }

    // --- INTERCEPÇÃO DE CONTROLE ---
    IF pre_meco_ativo {
        SET direcao_alvo TO SHIP:PROGRADE.
        SET throttle_ideial TO 0.4.
    } ELSE{
        SET direcao_alvo TO HEADING (AZIMUTE_FINAL, pitch_alvo).

        LOCAL acc_max IS SHIP:AVAILABLETHRUST / SHIP:MASS.
        LOCAL g_limit IS 1.0.
        IF acc_max > 0 {
            SET g_limit TO (MAX_G * 9.80665) / acc_max.
        }
        LOCAL meco_limit IS 1.0.

        SET throttle_ideial TO MIN(1.0, MIN(g_limit, meco_limit)).
    }

    // --- ATUALIZAÇÃO DA TELEMETRIA ---
    PRINT ROUND (pitch_alvo, 1) + " deg " AT (14,7).
    PRINT ROUND (SHIP:ALTITUDE/1000, 1) + " km " AT (14,12).
    PRINT ROUND (SHIP:APOAPSIS/1000, 1) + " km " AT (14,14).
    PRINT ROUND (throttle_ideial * 100, 0) + " % " AT (43,14).
    WAIT 0.05.
}