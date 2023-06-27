--! Standardbibliothek benutzen
library IEEE;
--! Logikelemente verwenden
use IEEE.STD_LOGIC_1164.ALL;
--! Numerisches Rechnen ermoeglichen
use IEEE.NUMERIC_STD.ALL;

--! @brief ASHA-Modul - Regelung
--! @details Dieses Modul enthaelt die Regelung
entity AshaRegelung is
  Port ( 
    Clock : in std_logic; 											--! Taktsignal
    Reset : in std_logic; 											--! Resetsignal
    EnClockLight : in std_logic;									--! Enable-Signal fuer die Lichtregelung
    EnClockTemp  : in std_logic; 							   --! Enable-Signal fuer die Temperaturregelung
    SensordataLight   : in std_logic_vector(11 downto 0); 			--! Aktuelle Lichtwerte
    SensordataTempIn  : in std_logic_vector(11 downto 0); 			--! Aktuelle Innentemperatur
	 SensordataTempOut : in std_logic_vector(11 downto 0);   		--! Aktuelle AuÃŸentemperatur
	 PWM1FanInsideValueControl  : out std_logic_vector(7 downto 0) := (others => '0'); 	--! PWM-Wert innerere Luefter
    PWM2FanOutsideValueControl : out std_logic_vector(7 downto 0)  := (others => '0');   --! PWM-Wert aeusserer Luefter
    PWM3LightValueControl   : out std_logic_vector(7 downto 0) := (others => '0'); 	   --! PWM-Wert Licht
    PWM4PeltierValueControl : out std_logic_vector(7 downto 0); 	   --! PWM-Wert Peltier
    PeltierDirectionControl : out std_logic := '0'; 						      --! Pelier Richtung heizen (=1)/kuehlen(=0)
    ControlLightDiffOut : out unsigned(12 downto 0); 				--! Aktuelle Regeldifferenz Licht
    ControlTempDiffOut  : out unsigned(12 downto 0)            --! Aktuelle Regeldifferenz Temperatur
	 ); 				
end AshaRegelung;

architecture Behavioral of AshaRegelung is

begin

-- Versuch 9: Realisierung der Lichtsteuerung
lightControl: process (Clock)
begin
    if (rising_edge(Clock)) then
        if(Reset = '1') then
            PWM3LightValueControl <= (others => '0');
        else 
            if(EnClockLight = '1') then
                if(unsigned(SensordataLight) > 4091 )then --weniger als 10 lux
                    PWM3LightValueControl <= b"11111111"; -- duty cycle 100%   das wert 255
                elsif (unsigned(SensordataLight) > 4076) then --weniger als 50 lux
                    PWM3LightValueControl <= b"10000000"; -- duty cycle 50% das wert 128
                elsif (unsigned(SensordataLight) > 4021 ) then --weniger als 200 lux
                    PWM3LightValueControl <= b"01000000"; -- duty cycle 25% das wert 64
                else --mehr als 200 lux
                    PWM3LightValueControl <= b"00000000"; -- duty cycle 0%   das wert 0
                end if ;
            end if;
        end if;
    end if;
end process lightControl;

-- Versuch 9: Realisierung der Temperatursteuerung
-- Ziel: Innen zwei Grad waermer als draussen
-- 2°C entsprechen einem Wert von ca. 16;
-- um schnelles Umschalten zu verhindern, wird ein Toleranzbereich genommen
tempControl: process (EnClockTemp)
begin
    if(Reset = '1') then
        PWM1FanInsideValueControl <= (others => '0');
        PWM2FanOutsideValueControl <= (others => '0');
        PWM1FanInsideValueControl <= b"00000000";
        PWM2FanOutsideValueControl <= b"00000000";
    elsif (rising_edge(EnClockTemp)) then
        if(to_integer(unsigned(SensordataTempIn)) - to_integer(unsigned(SensordataTempOut)) < 15) then --differenz weniger als 1.9c = 15v
            PeltierDirectionControl <= '1'; -- heizen
            PWM1FanInsideValueControl <= b"11111111"; -- die beide Luerfter immer laufen
            PWM2FanOutsideValueControl <= b"11111111";
        elsif(to_integer(unsigned(SensordataTempIn)) - to_integer(unsigned(SensordataTempOut)) > 17) then --differenz mehr als 2.1c = 17v
            PeltierDirectionControl <= '0'; --kuelen
            PWM1FanInsideValueControl <= b"11111111"; -- die beide Luerfter immer laufen
            PWM2FanOutsideValueControl <= b"11111111";
        else
            PeltierDirectionControl <= '0'; --kuelen
            PWM1FanInsideValueControl <= b"11111111"; -- die beide Luerfter immer laufen
            PWM2FanOutsideValueControl <= b"11111111";
        end if;
     end if;

end process tempControl;
		
		
-- Versuch 9: Ansteuerung der 7-Seg-Anzeige			
SevenSegOutput: process (Clock)

begin
	if (rising_edge(Clock)) then
	   if(Reset = '1') then
            ControlTempDiffOut(11 downto 0) <= (others => '0');
            ControlLightDiffOut(11 downto 0) <= (others => '0');
	   else
	   
	        ControlLightDiffOut(11 downto 0) <= unsigned(SensordataLight);
	        
            if(unsigned(SensordataTempIn)  > unsigned(SensordataTempOut) ) then
            ControlTempDiffOut(11 downto 0) <= unsigned(SensordataTempIn) - unsigned(SensordataTempOut); -- Temperatur Differenz
            ControlTempDiffOut(12) <= '1'; -- 1 falls SensordataTempIn grosser als SensordataTempOut
            else
            ControlTempDiffOut(11 downto 0) <= unsigned(SensordataTempOut) - unsigned(SensordataTempIn);
            ControlTempDiffOut(12) <= '0'; -- 0 falls SensordataTempIn kleiner oder gleich  SensordataTempOut
            end if;
	   end if;
	end if;
end process SevenSegOutput;

end Behavioral;
