--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.STD_LOGIC_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief ASHA-Modul - PWM-Signale erzeugen
--! @details  Dieses Modul erzeugt die PWM-Signale fuer PWM-Aktoren
entity AshaPWM is
  Port ( 
    Clock : in std_logic; 									--! Taktsignal
    Reset : in std_logic; 									--! Resetsignal
    EnPWMClock : in std_logic; 								--! Enable-Signal fuer die PWM-Abarbeitung
    PWM1FanInsideValue : in std_logic_vector(7 downto 0); 	--! Signalquellwert Luefter innen
    PWM2FanOutsideValue : in std_logic_vector(7 downto 0);	--! Signalquellwert Luefter aussen
    PWM3LightValue : in std_logic_vector(7 downto 0); 		--! Signalquellwert Licht
    PWM4PeltierValue : in std_logic_vector(7 downto 0); 	--! Signalquellwert Peltier
    PWM1FanInsideSignal : out std_logic; 					--! PWM-Aktorsignal Luefter innen
    PWM2FanOutsideSignal : out std_logic; 					--! PWM-Aktorsignal Luefter aussen
    PWM3LightSignal : out std_logic; 						--! PWM-Aktorsignal Licht
    PWM4PeltierSignal : out std_logic); 					--! PWM-Aktorsignal Peltier
end AshaPWM;

architecture Behavioral of AshaPWM is

signal PWMCounter : unsigned(7 downto 0) := "00000000"; 


begin

    -- Die nachfolgenden Zeilen müssen nach der Implementierung von 
    -- PWM_Gen wieder entfernt werden! TODO
	--PWM1FanInsideSignal<='1';
	--PWM2FanOutsideSignal<='1';
	--PWM3LightSignal<='1';
	--PWM4PeltierSignal<='1';
	--PWMCounter<=(others=>'0'); 
	
  --! PWM Generierung -> Versuch 7
  -- Hinweis: Die Aktoren sind low-active!
  PWM_Gen:Process (Clock)
  begin
    if rising_edge(Clock) then
         -- wenn reset 1 ist , dann werden all signale zuruckgesetzt
         if(Reset = '1') then
               PWM1FanInsideSignal<='1';
               PWM2FanOutsideSignal<='1';
               PWM3LightSignal<='1';
               PWM4PeltierSignal<='1';
               PWMCounter<=(others=>'0'); 
	
            else 
                  -- sonst wir uberprufen ob EnPWMClock 1 ist 
                  if(EnPWMClock = '1') then
                    --wenn PWMCounter kleiner als 255
                     if(PWMCounter < 254) then
                            -- verlgeichen wir alle werte von PWM1FanInsideValue , PWM2FanOutsideValue , PWM3LightValue und PWM4PeltierValue
                            -- mit dem PWMCounter
                            if( PWMCounter < unsigned(PWM1FanInsideValue) ) then
                                --falls kleiner dann das wert von PWM1FanInsideSignal wird mit 0 gesetzt
                                -- das bedeutet innere fan ist jetzt aktiv
                                PWM1FanInsideSignal <= '0';
                              else
                                --sonst nicht aktive
                                PWM1FanInsideSignal <= '1';
                            end if;
                            
                            if(PWMCounter < unsigned(PWM2FanOutsideValue) ) then
                                 --falls kleiner dann das wert von PWM2FanOutsideSignal wird mit 0 gesetzt
                                -- das bedeutet aussere fan ist jetzt aktiv
                                PWM2FanOutsideSignal <= '0';
                              else
                                --sonst nicht aktive
                                PWM2FanOutsideSignal <= '1';
                            end if;
                            
                            if( PWMCounter < unsigned(PWM3LightValue) ) then
                                 --falls kleiner dann das wert von PWM3LightSignal wird mit 0 gesetzt
                                -- das bedeutet das LED ist jetzt aktiv
                                PWM3LightSignal <= '0';
                              else
                                --sonst nicht aktive
                                PWM3LightSignal <= '1';
                            end if;
                            

                            if( PWMCounter < unsigned(PWM4PeltierValue) ) then
                                --falls kleiner dann das wert von PWM4PeltierSignal wird mit 0 gesetzt
                                -- das bedeutet das Peltier ist jetzt aktiv
                                PWM4PeltierSignal <= '0';
       
                           else
                                --sonst nicht aktive
                                PWM4PeltierSignal <= '1';
                           end if;
                            
                            --PWMCounter wird jetzt inkrementiert
                            PWMCounter <= PWMCounter + 1;
                        else  
                            --falls PWMCounter grosser als 254 , wird es zuruckgesetzt
                            PWMCounter<=(others=>'0');

                        end if;
                     end if;
         end if;

   end if;
  end Process PWM_Gen; 

end Behavioral;
