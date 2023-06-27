library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.AshaTypes.ALL;

entity actor is
    Port ( 
		Clock 				   :	in  std_logic; 			          --! Taktsignal
		Reset 				   :	in  std_logic; 					 	 --! Resetsignal
		Switches 			   : 	in  std_logic_vector(3 downto 0); --! Die acht Schalter
		ButtonsIn 			   :   in  std_logic_vector(3 downto 0);--! Die vier Taster
		SensorVibe 			   : 	in  std_logic;					 	    --! Eingang: Virbationssensor
		SensorDoor 			   : 	in  std_logic; 					    --! Eingang: Tuersensor
		ADCRegister			   :	in  ADCRegisterType; 				 --! Datenregister aller ADC-Werte
		LEDsOut 			      :	out std_logic_vector(5 downto 0) := (others => '0');	--! Die acht LEDs
		SevenSegmentValue	   :	out std_logic_vector (15 downto 0);	--! treibt die 7-Segment-Anzeigen
		PWM1FanInsideValue   : 	out std_logic_vector(7 downto 0); 	--! Signalquellwert Luefter innen
		PWM2FanOutsideValue  : 	out std_logic_vector(7 downto 0); 	--! Signalquellwert Luefter aussen
		PWM3LightValue 		: 	out std_logic_vector(7 downto 0);	--! Signalquellwert Licht
		PWM4PeltierValue 	   : 	out std_logic_vector(7 downto 0);	--! Signalquellwert Peltier		
		PeltierDirection 	   : 	out std_logic;						      --! Signalquellwert Peltier	Richtung
		----- Werte von Bluetooth
		LEDsBT 					   :	in std_logic_vector(5 downto 0);	 --! Die acht LEDs
		SevenSegmentValueBT		:	in std_logic_vector (15 downto 0);--! 7SegmentEingang von BT
		PWM1FanInsideValueBT 	:	in std_logic_vector(7 downto 0);	 --! Signalquellwert Luefter innen, von Bt
		PWM2FanOutsideValueBT 	:	in std_logic_vector(7 downto 0);	 --! Signalquellwert Luefter aussen, von Bt
		PWM3LightValueBT 		   :	in std_logic_vector(7 downto 0);	 --! Signalquellwert Licht, von Bt
		PWM4PeltierValueBT		:	in std_logic_vector(7 downto 0);	 --! Signalquellwert Peltier, von Bt
		PeltierDirectionBT		:   in std_logic;						    --! Signalquellwert Peltier Richtung, von Bt
		----- Werte von Regelung
		PWM1FanInsideValueControl	:	in std_logic_vector(7 downto 0); --! Signalquellwert Luefter innen, von Regelung
		PWM2FanOutsideValueControl :	in std_logic_vector(7 downto 0); --! Signalquellwert Luefter aussen, von Regelung
		PWM3LightValueControl 		:	in std_logic_vector(7 downto 0); --! Signalquellwert Licht, von Regelung
		PWM4PeltierValueControl		:	in std_logic_vector(7 downto 0); --! Signalquellwert Peltier, von Regelung
		PeltierDirectionControl		:	in std_logic;					      --! Signalquellwert Peltier Richtung, von Regelung
		ControlLightDiffOut 		   :   in unsigned(12 downto 0);		   --! Aktuelle Regeldifferenz Licht
		ControlTempDiffOut  		   :   in unsigned(12 downto 0)		   --! Aktuelle Regeldifferenz Temperatur
	);
end actor;

architecture Behavioral of actor is

-- Zustandsautomat für Modus Auswahl
type state_typeM is (Asha1,Asha2,Asha3,
                     SensorRead1,SensorRead2,SensorRead3,
                     ManualActor1,ManualActor2,ManualActor3,
                     AutoActor1,AutoActor2,AutoActor3,
                     Bluetooth1,Bluetooth2,Bluetooth3);--type of state machine(M for Modus).
signal current_m,next_m:state_typeM;--current and next state declaration.

-- Zustandsautomat für Sensor Zustaende.
type state_typeS is (Init, Init2, Light, Light2, TempIn, TempIn2, TempOut, TempOut2, Vibe, Vibe2, Door, Door2 );  --type of state machine(S for Sensor).
signal current_s,next_s: state_typeS;  --current and next state declaration.

type state_typeR is (InitR, LightD, LightD2, TempD, TempD2);  
signal current_r,next_r: state_typeR; 

begin
-- FSM Prozess zur Realisierung der Speicherelemente - Abhängig vom Takt den nächsten Zustand setzen
--> In Versuch 6 zu implementieren!-
FSM_seq: process (Clock,Reset)
	begin
   --falls reset Taste gedruckt wird , dann wir setzen das wert von current_s mit Init
   if(Reset = '1') then
           current_s <= Init;
           current_m <= Asha1;
           current_r <= InitR;
	else if(rising_edge(Clock)) then --falls Flanke von Clock hoch ist , dann wir aktualisieren current_s mit dem Wert von next_s
	       current_s <= next_s;
	       current_m <= next_m;
           current_r <= next_r;
	   end if;
	end if;
	end process FSM_seq;
	
-- FSM Prozess (kombinatorisch) zur Realisierung der Modul Zustände aus den Typen per Switch Case:  state_typeM
-- Setzt sich aus aktuellem Zustand und folgendem Zustand zusammen: current_m,next_m
--> In Versuch 6-10 zu implementieren
FSM_modul:process(current_m, ButtonsIn(0),ButtonsIn(1))
begin
 next_m <= current_m ;
 case current_m is
        when Asha1=> --ASHA state
            if(ButtonsIn(0) = '1') then
                next_m <= Asha2;
            elsif(ButtonsIn(1) = '1') then
                next_m <= Asha3;
            else 
                next_m <= Asha1;
            end if;
        
        when Asha2=>
            if(ButtonsIn(0) = '0') then
                next_m <= SensorRead1;
            else
                next_m <= Asha2;
            end if;
            
        when Asha3=>
            if(ButtonsIn(1) = '0') then
                next_m <= Bluetooth1;
            else
                next_m <= Asha3;
            end if;
        
        when  SensorRead1 =>
            if(ButtonsIn(0) = '1') then
   
                next_m <= SensorRead2;
            elsif(ButtonsIn(1) = '1') then

                next_m <= SensorRead3;
            else

                next_m <= SensorRead1;
            end if;
                
        when SensorRead2=>
            if(ButtonsIn(0) = '0') then
                next_m <= ManualActor1;
            else

                next_m <= SensorRead2;
            end if;
            
        when SensorRead3=>
            if(ButtonsIn(1) = '0') then

                next_m <= Asha1;
            else

                next_m <= SensorRead3;
            end if;
        
        when  ManualActor1 =>
            if(ButtonsIn(0) = '1') then
                next_m <= ManualActor2;
            elsif(ButtonsIn(1) = '1') then
                next_m <= ManualActor3;
            else
                next_m <= ManualActor1;
            end if;
                
        when ManualActor2=>
            if(ButtonsIn(0) = '0') then
                next_m <= AutoActor1;
            else
                next_m <= ManualActor2;
            end if;
            
        when ManualActor3=>
            if(ButtonsIn(1) = '0') then
                next_m <= SensorRead1;
            else
                next_m <= ManualActor3;
            end if;
        
         when  AutoActor1 =>
            if(ButtonsIn(0) = '1') then
                next_m <= AutoActor2;
            elsif(ButtonsIn(1) = '1') then
                next_m <= AutoActor3;
            else
                next_m <= AutoActor1;
            end if;
                
        when AutoActor2=>
            if(ButtonsIn(0) = '0') then
                next_m <= Bluetooth1;
            else
                next_m <= AutoActor2;
            end if;
            
        when AutoActor3=>
            if(ButtonsIn(1) = '0') then
                next_m <= ManualActor1;
            else
                next_m <= AutoActor3;
            end if;
        
         when  Bluetooth1 =>
            if(ButtonsIn(0) = '1') then
                next_m <= Bluetooth2;
            elsif(ButtonsIn(1) = '1') then
                next_m <= Bluetooth3;
            else
                next_m <= Bluetooth1;
            end if;
                
        when Bluetooth2=>
            if(ButtonsIn(0) = '0') then
                next_m <= Asha1;
            else
                next_m <= Bluetooth2;
            end if;
            
        when Bluetooth3=>
            if(ButtonsIn(1) = '0') then
                next_m <= AutoActor1;
            else
                next_m <= Bluetooth3;
            end if;
        
    when others => null;
        -- DEFAULT Werte setzen TODO

    end case;

end process;    

-- FSM Prozess (kombinatorisch) zur Realisierung der Ausgangs- und Übergangsfunktionen
	-- Hinweis: 12 Bit ADC-Sensorwert für Lichtsensor: 	  ADCRegister(3),
	-- 			12 Bit ADC-Sensorwert für Temp. (außen):  ADCRegister(1),
	-- 			12 Bit ADC-Sensorwert für Temp. (innen):  ADCRegister(0),
--> In Versuch 6-10 zu implementieren!-

FSM_comb:process (current_s,current_m, ButtonsIn(2) , ADCRegister, SensorVibe, SensorDoor , Switches)
begin
    -- to avoid latches always set current state (Versuch 6)
    next_s <= current_s;
    -- Modus 0: "ASHA" Auf 7 Segment Anzeige
    case current_m is
        when Asha1|Asha2|Asha3 => --ASHA state
             LEDsOut<= b"111111";
             SevenSegmentValue <= x"FFFF";
    -- Versuch 6
    -- Modus 1: "Sensorwerte Auslesen"
    -- Durchschalten der Sensoren per BTN2
    -- Ausgabe des ausgewalten Sensors ueber SiebenSegmentAnzeige
    -- when state ... TODO
         when SensorRead1|SensorRead2|SensorRead3 => --ASHA state
         
            case current_s is 
                when Init =>
                     LEDsOut<= b"000000"; -- leuchten wir alle LEDs 
                     SevenSegmentValue <= x"0000";-- und sollen wir auch das Wort "ASHA" auf den Siebensigmentanzeigen
                     if( ButtonsIn(2) = '0') then
                     next_s <= Init2; -- jetzt aktulaisieren wir next_s mit dem nachsten Status Init2
                     end if;
                when Init2 =>
                    if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                        LEDsOut<= b"000000";
                        SevenSegmentValue <= x"0000";
                    else --falls Taste gedrückt wird 
                        LEDsOut<= b"001000"; -- leuchten wir nur die vierte Led
                        SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                        SevenSegmentValue(11 downto 0) <= ADCRegister(3); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von Lichtsensor 
                        next_s <= light; -- jetzt aktulaisieren wir next_s mit dem nachsten Status light
                    end if;
                when light =>
                     LEDsOut<= b"001000"; -- leuchten wir nur die vierte Led
                     SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                     SevenSegmentValue(11 downto 0) <= ADCRegister(3); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von Lichtsensor 
                     if( ButtonsIn(2) = '0') then  --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status light2
                        next_s <= light2;
                     end if;
                when light2 =>
                    if( ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                         LEDsOut<= b"001000";
                         SevenSegmentValue <= (others => '0');
                         SevenSegmentValue(11 downto 0) <= ADCRegister(3);
                    else --falls Taste gedrückt wird 
                        LEDsOut<= b"000100"; -- leuchten wir nur die dritte Led
                        SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                        SevenSegmentValue(11 downto 0) <= ADCRegister(0); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (innen)
                        next_s <= TempIn; -- jetzt aktulaisieren wir next_s mit dem nachsten Status TempIn
                    end if;
                 when TempIn =>
                         LEDsOut<= b"000100"; -- leuchten wir nur die dritte Led
                         SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                         SevenSegmentValue(11 downto 0) <= ADCRegister(0); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (innen)
                         if( ButtonsIn(2) = '0') then  --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status TempIn2
                            next_s <= TempIn2;
                         end if;
                 when TempIn2 =>
                        if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                             LEDsOut<= b"000100";
                             SevenSegmentValue <= (others => '0');
                             SevenSegmentValue(11 downto 0) <= ADCRegister(0);
                        else --falls Taste gedrückt wird 
                            LEDsOut<= b"000010"; -- leuchten wir nur die zweite Led
                            SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                            SevenSegmentValue(11 downto 0) <= ADCRegister(1); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (aussen)
                            next_s <= TempOut; -- jetzt aktulaisieren wir next_s mit dem nachsten Status TempOut
                        end if;
                   when TempOut=>
                            LEDsOut<= b"000010"; -- leuchten wir nur die zweite Led
                            SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                            SevenSegmentValue(11 downto 0) <= ADCRegister(1); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (aussen)
                            if( ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status TempOut2
                               next_s <= TempOut2;
                            end if;
                    when TempOut2=>
                            if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                                 LEDsOut<= b"000010";
                                 SevenSegmentValue <= (others => '0');
                                 SevenSegmentValue(11 downto 0) <= ADCRegister(1);
                            else
                                LEDsOut<= b"000001"; -- leuchten wir nur die erste Led
                                SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                                SevenSegmentValue(0) <= SensorVibe; -- wir ?ndern das wert von SevenSegmentValue  mit dem wert von Bewegungssensor 
                                next_s <= Vibe; -- jetzt aktulaisieren wir next_s mit dem nachsten Status Vibe
                            end if;
                    when  Vibe =>
                             LEDsOut<= b"000001"; -- leuchten wir nur die erste Led
                             SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                             SevenSegmentValue(0) <= SensorVibe; -- wir ?ndern das wert von SevenSegmentValue mit dem wert von Bewegungssensor
                             if( ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status Vibe2
                                next_s <= Vibe2;
                             end if;
                     when Vibe2 =>
                            if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                                 LEDsOut<= b"000001";
                                 SevenSegmentValue <= (others => '0');
                                 SevenSegmentValue(0) <= SensorVibe;
                            else
                                LEDsOut<= b"001000"; -- leuchten wir nur die vierte Led
                                SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                                SevenSegmentValue(11 downto 0) <= ADCRegister(3); -- wir ?ndern das wert von SevenSegmentValue  mit dem wert von Lichtsensor 
                                next_s <= light; -- jetzt aktulaisieren wir next_s mit dem nachsten Status light
                            end if;
                      when others => null;

                      end case;
    -- Versuch 7
    -- Modus 2: Manuelle Aktorsteuerung	
    -- nur erlauben, wenn keine Regelung aktiv ist!		
        -- when ... TODO
      when ManualActor1|ManualActor2|ManualActor3 => --ASHA state
        LEDsOut<= b"010000";
            case current_s is 
                when Init =>
                     LEDsOut<= b"010101"; -- leuchten wir alle LEDs 
                     SevenSegmentValue <= x"0000";-- und sollen wir auch das Wort "ASHA" auf den Siebensigmentanzeigen
                     if( ButtonsIn(2) = '0') then
                        next_s <= Init2; -- jetzt aktulaisieren wir next_s mit dem nachsten Status Init2
                     end if;
                when Init2 =>
                    if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                        LEDsOut<= b"010101";
                        SevenSegmentValue <= x"0000";
                    else --falls Taste gedrückt wird 
                        LEDsOut<= b"010101"; -- leuchten wir nur die vierte Led
                        SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                        SevenSegmentValue(11 downto 0) <= ADCRegister(3); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von Lichtsensor 
                        next_s <= light; -- jetzt aktulaisieren wir next_s mit dem nachsten Status light
                    end if;
                when light =>
                     LEDsOut<= b"010101"; -- leuchten wir nur die vierte Led
                     SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                     SevenSegmentValue(11 downto 0) <= ADCRegister(3); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von Lichtsensor 
                     if( ButtonsIn(2) = '0') then  --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status light2
                        next_s <= light2;
                     end if;
                when light2 =>
                    if( ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                         LEDsOut<= b"010101";
                         SevenSegmentValue <= (others => '0');
                         SevenSegmentValue(11 downto 0) <= ADCRegister(3);
                    else --falls Taste gedrückt wird 
                        LEDsOut<= b"010101"; -- leuchten wir nur die dritte Led
                        SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                        SevenSegmentValue(11 downto 0) <= ADCRegister(0); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (innen)
                        next_s <= TempIn; -- jetzt aktulaisieren wir next_s mit dem nachsten Status TempIn
                    end if;
                 when TempIn =>
                         LEDsOut<= b"010101"; -- leuchten wir nur die dritte Led
                         SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                         SevenSegmentValue(11 downto 0) <= ADCRegister(0); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (innen)
                         if( ButtonsIn(2) = '0') then  --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status TempIn2
                            next_s <= TempIn2;
                         end if;
                 when TempIn2 =>
                        if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                             LEDsOut<= b"010101";
                             SevenSegmentValue <= (others => '0');
                             SevenSegmentValue(11 downto 0) <= ADCRegister(0);
                        else --falls Taste gedrückt wird 
                            LEDsOut<= b"010101"; -- leuchten wir nur die zweite Led
                            SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                            SevenSegmentValue(11 downto 0) <= ADCRegister(1); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (aussen)
                            next_s <= TempOut; -- jetzt aktulaisieren wir next_s mit dem nachsten Status TempOut
                        end if;
                   when TempOut=>
                            LEDsOut<= b"010101"; -- leuchten wir nur die zweite Led
                            SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                            SevenSegmentValue(11 downto 0) <= ADCRegister(1); -- wir ?ndern das wert von SevenSegmentValue mit dem wert von ADC-Sensorwert für Temp (aussen)
                            if( ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status TempOut2
                               next_s <= TempOut2;
                            end if;
                    when TempOut2=>
                            if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                                 LEDsOut<= b"010101";
                                 SevenSegmentValue <= (others => '0');
                                 SevenSegmentValue(11 downto 0) <= ADCRegister(1);
                            else
                                LEDsOut<= b"010101"; -- leuchten wir nur die erste Led
                                SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                                SevenSegmentValue(0) <= SensorVibe; -- wir ?ndern das wert von SevenSegmentValue  mit dem wert von Bewegungssensor 
                                next_s <= Vibe; -- jetzt aktulaisieren wir next_s mit dem nachsten Status Vibe
                            end if;
                    when  Vibe =>
                             LEDsOut<= b"010101"; -- leuchten wir nur die erste Led
                             SevenSegmentValue <= (others => '0'); -- SevenSegmentValue zurücksetzen
                             SevenSegmentValue(0) <= SensorVibe; -- wir ?ndern das wert von SevenSegmentValue mit dem wert von Bewegungssensor
                             if( ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , ?ndern wir next_s mit dem nachsten Status Vibe2
                                next_s <= Vibe2;
                             end if;
                     when Vibe2 =>
                            if(ButtonsIn(2) = '0') then --falls Taste nicht gedrückt wird , dann Leds und Siebensegmentanzeigen bleiben wie Früher
                                 LEDsOut<= b"010101";
                                 SevenSegmentValue <= (others => '0');
                                 SevenSegmentValue(0) <= SensorVibe;
                            else
                                LEDsOut<= b"010101"; -- leuchten wir nur die vierte Led
                                SevenSegmentValue <= (others => '0');  -- SevenSegmentValue zurücksetzen
                                SevenSegmentValue(11 downto 0) <= ADCRegister(3); -- wir ?ndern das wert von SevenSegmentValue  mit dem wert von Lichtsensor 
                                next_s <= light; -- jetzt aktulaisieren wir next_s mit dem nachsten Status light
                            end if;
                      when others => null;
                      end case;
         --wenn das erste switch eingeschaltet wird dann das wert von PWM1FanInsideValue wird uebergeben     
         -- das bedeutet das innere FAN soll starten
        if(Switches(0) = '1') then
            PWM1FanInsideValue <= b"11110011";
        else
            --sonst bleibt off
            PWM1FanInsideValue <= b"00000000";
        end if;
         --wenn das zweite switch eingeschaltet wird dann das wert von PWM2FanOutsideValue wird uebergeben     
         -- das bedeutet das aussere FAN soll starten
        if(Switches(1) = '1') then
            PWM2FanOutsideValue <= b"11110000";
        else
             --sonst bleibt off
            PWM2FanOutsideValue <= b"00000000";
        end if;
        
         --wenn das dritte switch eingeschaltet wird dann das wert von PWM3LightValue wird uebergeben     
         -- das bedeutet das led soll beleuchten
        if(Switches(2) = '1') then
             PWM3LightValue <= b"00001001";
        else
             --sonst bleibt off
             PWM3LightValue <= b"00000000";
        end if;
        
        --wenn das vierte  switch eingeschaltet wird dann die werte von PWM4PeltierValue und PeltierDirection werden uebergeben   
        if(Switches(3) = '1') then
             PWM4PeltierValue <= b"01011111";
             PeltierDirection <= '1';
        else
             PWM4PeltierValue <= b"00000000";
             PeltierDirection <= '0';
        end if;
        
      when AutoActor1|AutoActor2|AutoActor3 => --ASHA state
        LEDsOut<= b"100000";
        if(Switches(3) = '0') then
            if(Switches(0) = '1' and Switches(1) = '0') then
                SevenSegmentValue <= (others => '0');  
                SevenSegmentValue(11 downto 0) <= std_logic_vector(ControlLightDiffOut(11 downto 0)); 
            elsif (Switches(1) = '1' and Switches(0) = '0') then
                SevenSegmentValue <= (others => '0');  
                SevenSegmentValue(12 downto 0) <= std_logic_vector(ControlTempDiffOut); 
            elsif (Switches(1) = '0' and Switches(0) = '0') then
                SevenSegmentValue <= (others => '0');  
            else
                next_r <= current_r;
                case current_r is
                    when InitR =>
                        if(ButtonsIn(0) = '1') then
                            next_r <= LightD;
                        else
                            next_r <= InitR;
                        end if;
                    when LightD =>
                        if(ButtonsIn(0) = '0') then
                            next_r <= LightD2;
                        else
                            next_r <= LightD;
                        end if;
                    when LightD2 =>
                        SevenSegmentValue <= (others => '0');  
                        SevenSegmentValue(11 downto 0) <= std_logic_vector(ControlLightDiffOut(11 downto 0)); 
                        if(ButtonsIn(0) = '1') then
                            next_r <= TempD;
                        else
                            next_r <= LightD2;
                        end if;
                    when TempD =>
                        if(ButtonsIn(0) = '0') then
                            next_r <= TempD2;
                        else
                            next_r <= TempD;
                        end if;
                    when TempD2 =>
                        SevenSegmentValue <= (others => '0');  
                        SevenSegmentValue(12 downto 0) <= std_logic_vector(ControlTempDiffOut);
                        next_r <= InitR;
                    when others => null;
                end case;
            end if;

        else 
            if(Switches(0) = '1') then
                PWM3LightValue <= PWM3LightValueControl;
            else
                PWM3LightValue <= (others => '0');
            end if;
            if(Switches(2) = '1') then
                if(Switches(1) = '1')then
                    PWM2FanOutsideValue <= PWM2FanOutsideValueControl;
                else
                    PWM2FanOutsideValue <=  (others => '0');
                end if;
            else
                if(Switches(1) = '1')then
                    PWM1FanInsideValue <= PWM1FanInsideValueControl;
                else
                    PWM1FanInsideValue <=  (others => '0');
                end if;
            end if;
        end if;
      when Bluetooth1|Bluetooth2|Bluetooth3 => --ASHA state
        LEDsOut<= b"110000";
    -- Versuch 9
    -- Modus 3: geregelte Aktorsteuerung	
        -- when ... TODO
        
    -- Versuch 10
    -- Modus 4: Steuerung ueber Smartphone-App
            -- when ... TODO
    when others =>
        -- DEFAULT Werte setzen TODO

    end case;
end process;
end Behavioral;
