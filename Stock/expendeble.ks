CLEARSCREEN.

// PARÂMETROS DE MISSÃO
SET LATITUDE_BASE TO SHIP:LATITUDE. //Pega a latitude atual
SET INCLINACAO_ALVO TO 0. // Ajuste de inclinação
SET ALTITUDE_ORBITA TO 1000 * 150. //Orbita Alvo
SET VEL_ORBITAL_ALVO TO 2250.

// AJUSTES
SET GT_VEL_INI TO 50. //Velocidade para começar a gravity turn
SET GT_ALT_END TO 1000 * 52. //Altitude Final da gravity turn
SET MAX_G TO 3.0. //Maximo de força G durante o lançamento

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
PRINT "AGUARDANDO LANÇAMENTO" AT (14,6).
PRINT ROUND (AZIMUTE_FINAL, 2) + " deg" AT(14,8).
PRINT ROUND (ALTITUDE_ORBITA/1000, 0) + " km" AT (43, 8).

FROM { LOCAL count IS 3. } UNTIL count = 0 STEP {SET count TO count - 1.} DO {
    PRINT "CONTAGEM: " + count + " " AT (14, 6).
    WAIT 1.
}

// DECOLAGEM
SET THROTTLE_IDEAL TO 1.0.
PRINT "DECOLAGEM" AT (14, 6).
LOCK THROTTLE TO THROTTLE_IDEAL.
STAGE.

// INICIALIZAÇÃO DE VARIAVEIS
LOCAL target_pitch IS 90.
LOCAL gt_alt_ini IS 0.
LOCAL gt_comecou IS FALSE.
LOCK STEERING TO HEADING (AZIMUTE_FINAL, target_pitch).

// FASE 1: GRAVITY TURN
UNTIL SHIP:ALTITUDE >= GT_ALT_END {
    IF NOT gt_comecou AND SHIP:VELOCITY:SURFACE:MAG >= GT_VEL_INI {
        SET gt_comecou TO TRUE.
        SET gt_alt_ini TO SHIP:ALTITUDE.
    }

    IF gt_comecou {
        LOCAL progresso IS (SHIP:ALTITUDE - gt_alt_ini) / (GT_ALT_END - gt_alt_ini).
        
    }
}