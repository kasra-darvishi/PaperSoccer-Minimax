library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity timer is
generic(ClockFrequencyHz : integer);
port(
    Clk     : in std_logic;
    nRst    : in std_logic; -- Negative reset
    Seconds : inout integer);
end entity;
 
architecture rtl of timer is
 
    -- Signal for counting clock periods
    signal Ticks : integer;
 
begin
 
    process(Clk) is
    begin
        if rising_edge(Clk) then
 
            -- If the negative reset signal is active
            if nRst = '1' then
                Ticks   <= 0;
                Seconds <= 0;
            else
                -- True once every second
                if Ticks = ClockFrequencyHz - 15000000 then
                    Ticks <= 0;
                    Seconds <= Seconds + 1;
                else
                    Ticks <= Ticks + 1;
                end if;
 
            end if;
        end if;
    end process;
 
end architecture;