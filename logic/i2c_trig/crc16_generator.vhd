

---------------------------------------------------------------------------------------------------------
-- LIBRARIES
---------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;


---------------------------------------------------------------------------------------------------------
-- ENTITY OF CRC16_GENERATOR
---------------------------------------------------------------------------------------------------------


-- CRC16-CCITT-KERMIT
-- http://en.wikipedia.org/wiki/CRC-CCITT
-- http://www.lammertbies.nl/comm/info/crc-calculation.html


entity CRC16_GENERATOR is        
    port (
        CLOCK                               : in  std_logic;
        RESET                               : in  std_logic;    
        DATA_IN_EN                          : in  std_logic;         
        DATA_IN                             : in  std_logic_vector (15 downto 0);
        CRC_OUT                             : out std_logic_vector (15 downto 0)
    );
end CRC16_GENERATOR;


---------------------------------------------------------------------------------------------------------
-- ARCHITECTURE OF CRC16_GENERATOR
---------------------------------------------------------------------------------------------------------


architecture arch1 of CRC16_GENERATOR is


---------------------------------------------------------------------------------------------------------
-- SIGNALS
---------------------------------------------------------------------------------------------------------


type TEMP_ARRAY is array(0 to 16) of std_logic_vector(15 downto 0);
signal TEMP                                    : TEMP_ARRAY;
signal CRC_REGISTER                         : std_logic_vector(15 downto 0);
signal NEXT_CRC                             : std_logic_vector(15 downto 0);
constant INITIAL_CRC_REGISTER               : std_logic_vector(15 downto 0) := x"0000";


---------------------------------------------------------------------------------------------------------
-- BEGIN
---------------------------------------------------------------------------------------------------------


begin


-- CRC Control logic
p: process (CLOCK, RESET)
    begin
        if (RESET = '1') then
            CRC_REGISTER                    <= INITIAL_CRC_REGISTER;
        elsif (rising_edge(CLOCK)) then    
            
            if(DATA_IN_EN = '1') then
                CRC_REGISTER                    <= NEXT_CRC;

            end if;
                
        end if;
        
    end process;
    
                    TEMP(0)                         <= CRC_REGISTER;
  
            g: for i in 1 to 16 generate
                TEMP(i)(0 )                      <= DATA_IN(16-i) xor TEMP(i-1)(15);
                TEMP(i)(1 )                      <= TEMP(i-1)(0);
                TEMP(i)(2 )                      <= TEMP(i-1)(1);
                TEMP(i)(3 )                      <= TEMP(i-1)(2);
                TEMP(i)(4 )                      <= TEMP(i-1)(3);
                TEMP(i)(5 )                      <= TEMP(i-1)(4) xor (DATA_IN(16-i) xor TEMP(i-1)(15)); 
                TEMP(i)(6 )                      <= TEMP(i-1)(5);
                TEMP(i)(7 )                      <= TEMP(i-1)(6);
                TEMP(i)(8 )                      <= TEMP(i-1)(7);
                TEMP(i)(9 )                      <= TEMP(i-1)(8);
                TEMP(i)(10)                      <= TEMP(i-1)(9);
                TEMP(i)(11)                      <= TEMP(i-1)(10);
                TEMP(i)(12)                      <= TEMP(i-1)(11) xor (DATA_IN(16-i) xor TEMP(i-1)(15));
                TEMP(i)(13)                      <= TEMP(i-1)(12);
                TEMP(i)(14)                      <= TEMP(i-1)(13);
                TEMP(i)(15)                      <= TEMP(i-1)(14);
            end generate g;             
                
                NEXT_CRC                        <= TEMP(16);
               
                -- CRC_OUT                         <= CRC_REGISTER;    
                  CRC_OUT(0 )                  <= CRC_REGISTER(7);--15);     
                  CRC_OUT(1 )                  <= CRC_REGISTER(6);--14);  
                  CRC_OUT(2 )                  <= CRC_REGISTER(5);--13);  
                  CRC_OUT(3 )                  <= CRC_REGISTER(4);--12);  
                  CRC_OUT(4 )                  <= CRC_REGISTER(3);--11);  
                  CRC_OUT(5 )                  <= CRC_REGISTER(2);--10);  
                  CRC_OUT(6 )                  <= CRC_REGISTER(1);--9 );  
                  CRC_OUT(7 )                  <= CRC_REGISTER(0);--8 );   
                  CRC_OUT(8 )                  <= CRC_REGISTER(15);--7 );     
                  CRC_OUT(9 )                  <= CRC_REGISTER(14);--6 );  
                  CRC_OUT(10)                  <= CRC_REGISTER(13);--5 );  
                  CRC_OUT(11)                  <= CRC_REGISTER(12);--4 );  
                  CRC_OUT(12)                  <= CRC_REGISTER(11);--3 );  
                  CRC_OUT(13)                  <= CRC_REGISTER(10);--2 );  
                  CRC_OUT(14)                  <= CRC_REGISTER(9);--1 );  
                  CRC_OUT(15)                  <= CRC_REGISTER(8);--0 );     
                   


---------------------------------------------------------------------------------------------------------
--  THE END
---------------------------------------------------------------------------------------------------------


end architecture;


---------------------------------------------------------------------------------------------------------
--  THE END
---------------------------------------------------------------------------------------------------------