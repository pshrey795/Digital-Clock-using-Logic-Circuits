--VHDL code of digital-clock submitted by Shrey J. Patel, 2019CS10400


library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


--Main entity starts here
entity digital_clock is
    port(clk: in std_logic;                           --Display state / Time setting state(for entries below this)
        b1: in std_logic;                             --hh:mm mode / d1 increment
        b2: in std_logic;                             --mm:ss mode / d2 increment
        b3: in std_logic;                             --reset / d3 increment
        b4: in std_logic;                             --   / d4 increment
        b5: in std_logic;                             --State change
        
        Anode: out std_logic_vector(3 downto 0);     --Anode output to determine which LED to display

        Cathode: out std_logic_vector(7 downto 0)  --Display digit(out of d1,d2,d3,d4) at every (refresh period)/4 seconds
        --Last bit for decimal point(as a separator)

        );
end digital_clock;


--Main Design starts here
architecture design of digital_clock is

    --Define states aand modes 
    type state_type is (disp_state,set_state);          --disp_state means time display state and set_state means time setting state
    type mode_type is (hm_mode,ms_mode);                --hm_mode means hh:mm format and ms_mode means mm:ss format
    signal state:state_type := disp_state;
    signal mode:mode_type := hm_mode;

    --Clock digits
    signal d1:std_logic_vector(3 downto 0) := (others => '0');         --Display 1
    signal d2:std_logic_vector(3 downto 0) := (others => '0');         --Display 2
    signal d3:std_logic_vector(3 downto 0) := (others => '0');         --Display 3
    signal d4:std_logic_vector(3 downto 0) := (others => '0');         --Display 4

    --Clock conversion
    component clk_conv
    port(clk_input: in std_logic;
        clk_1s: out std_logic);
    end component;

    signal clk_1s:std_logic;  --converted clock signal, this signal is of 1 Hz

    --Digit conversion
    component digit_conv
        port(clk: in std_logic;
            inp_dig1: in std_logic_vector(3 downto 0);
            inp_dig2: in std_logic_vector(3 downto 0);
            inp_dig3: in std_logic_vector(3 downto 0);
            inp_dig4: in std_logic_vector(3 downto 0);
            decimal_point: in std_logic;
            anode_output: out std_logic_vector(3 downto 0);
            output_digit: out std_logic_vector(7 downto 0));
    end component;

    --Define internal counters(hours, minutes, seconds), these counters keep track of time synchronised with 1 Hz(1 sec) clock
    --1 determines 1st digit, and 2 determines second digit, both of which are 4 bit vectors
    signal hour1:std_logic_vector(3 downto 0) := (others => '0');
    signal hour2:std_logic_vector(3 downto 0) := (others => '0');
    signal min1:std_logic_vector(3 downto 0) := (others => '0');
    signal min2:std_logic_vector(3 downto 0) := (others => '0');
    signal sec1:std_logic_vector(3 downto 0) := (others => '0');
    signal sec2:std_logic_vector(3 downto 0) := (others => '0');

    --Decimal point needed or not
    signal decimal_point: std_logic:= '0';

    --Main design
    begin

        clk_conversion: clk_conv port map (clk_input => clk,clk_1s => clk_1s);

        --Updating time display
        main: process(clk_1s)
        begin
            
            --Time display 
            if(state=disp_state) then
                if(rising_edge(clk)) then
                    sec2 <= sec2 + 1;
                    if(sec2="1001") then
                        sec2 <= (others => '0');
                        sec1 <= sec1 + 1;
                        if(sec1="0101") then 
                            sec1 <= (others => '0');
                            min2 <= min2+1;
                            if(min2="1001") then
                                min2 <= (others => '0');
                                min1 <= min1 + 1;
                                if(min1="0101") then 
                                    min1 <= (others => '0');
                                    hour2 <= hour2+1;
                                    if(hour1<"0010") then 
                                        if(hour2="1001") then
                                            hour2 <= (others => '0');
                                            hour1 <= hour1 + 1;
                                        end if;
                                    else
                                        if(hour2="0100") then
                                            hour2 <= (others => '0');
                                            hour1 <= (others => '0');
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
                   
            --Updating display variables depending upon display mode
            if(mode=hm_mode) then
                d1 <= hour1;
                d2 <= hour2;
                d3 <= min1;
                d4 <= min2;
                decimal_point <= '1';
            else
                d1 <= min1;
                d2 <= min2;
                d3 <= sec1;
                d4 <= sec2;
                decimal_point <= '0';
            end if;

        end process;


        --Updating the clock in response to push buttons, which I have made asynchronous, so that button presses are detected 
        --regardless of clock edge

        --Also, all button presses are detected at their rising edge, so as to eliminate confusion between multiple quick
        --button presses and a single long button press. A button will be considered to be pressed only when its value changes
        --from 0 to 1, that is its rising edge, to avoid any ambiguity.
        Button_input: process(b1,b2,b3,b4,b5)
        begin

            --Changing the state of clock, whether is in display state or in setting state
            if(rising_edge(b5)) then
                if(state=disp_state) then
                    state <= set_state;
                else
                    state <= disp_state;
                end if;
            end if;


            --Time display
            --Button b1 and b2 are for switching between modes and b3 is for resetting the clock 
            if(state=disp_state) then

                --Changing display modes
                --hh:mm mode
                if(rising_edge(b1)) then 
                    mode <= hm_mode;
                end if;

                --mm:ss mode
                if(rising_edge(b2)) then
                    mode <= ms_mode;
                end if;

                --Resetting the clock
                if(rising_edge(b3)) then
                    hour1 <= (others => '0');
                    hour2 <= (others => '0');
                    min1 <= (others => '0');
                    min2 <= (others => '0');
                    sec1 <= (others => '0');
                    sec2 <= (others => '0');
                end if;

            --Time set
            --Buttons b1, b2, b3 and b4 act as up-counter buttons for individually setting the four display digits     
            else

                --Setting d4 i.e. display digit 4
                if(rising_edge(b4)) then 
                    if(mode=hm_mode) then 
                        min2 <= min2 + 1;
                        if(min2="1010") then
                            min2 <= (others => '0');
                        end if;
                    else
                        sec2 <= sec2 + 1;
                        if(sec2="1010") then
                            sec2 <= (others => '0');
                        end if;                 
                    end if;
                end if;

                --Setting d3 i.e. display digit 3
                if(rising_edge(b3)) then 
                    if(mode=hm_mode) then 
                        min1 <= min1 + 1;
                        if(min1="0110") then
                            min1 <= (others => '0');
                        end if;
                    else
                        sec1 <= sec1 + 1;
                        if(sec1="0110") then
                            sec1 <= (others => '0');
                        end if;                 
                    end if;
                end if;

                --Setting d2 i.e. display digit 2
                if(rising_edge(b2)) then 
                    if(mode=ms_mode) then 
                        min2 <= min2 + 1;
                        if(min2="1010") then
                            min2 <= (others => '0');
                        end if;
                    else
                        hour2 <= hour2 + 1;
                        if(hour1="0010") then
                            if(hour2="0101") then
                                hour2 <= (others => '0');
                            end if;
                        else
                            if(hour2="1010") then 
                                hour2 <= (others => '0');
                            end if;
                        end if;
                    end if;
                end if;


                --Setting d1 i.e. display digit 1
                if(rising_edge(b1)) then 
                    if(mode=ms_mode) then 
                        min1 <= min1 + 1;
                        if(min1="0110") then
                            min1 <= (others => '0');
                        end if;
                    else
                        hour1 <= hour1 + 1;
                        if(hour2 <= "0100") then
                            if(hour1="0011") then
                                hour1 <= (others => '0');
                            end if;
                        else
                            if(hour1="0010") then 
                                hour1 <= (others => '0');
                            end if;
                        end if;
                    end if;  
                end if;
            end if;

            --Updating display variables depending upon display mode
            if(mode=hm_mode) then
                d1 <= hour1;
                d2 <= hour2;
                d3 <= min1;
                d4 <= min2;
                decimal_point <= '1';
            else
                d1 <= min1;
                d2 <= min2;
                d3 <= sec1;
                d4 <= sec2;
                decimal_point <= '0';
            end if;

        end process;

        --Obtaining actual seven segment display from 4 bit vectors, one digit at a time, refreshing at every 4 ms for a total
        --refresh period of 16 ms. Both anode and cathode have been provided as output along with the information on decimal 
        --point so that the user can idenity the mode of the display. The 16ms refresh period is well below the persistence of
        --vision of a normal human being. So even when the digits are displayed one at a time, the user will see all the four
        --digits at once for a period of 1 second after which the time changes.
        display: digit_conv port map(clk => clk,inp_dig1 => d1,inp_dig2 => d2,inp_dig3 => d3,inp_dig4 => d4,decimal_point => decimal_point, anode_output => Anode,output_digit => Cathode);

    end design;




--Separate module for binary(particularly 4 bit vector) to seven segment conversion
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;    
entity digit_conv is
    port(clk: in std_logic;
        
        --Inputs for the four digits which are to be displayed in sequence
        inp_dig1: in std_logic_vector(3 downto 0);
        inp_dig2: in std_logic_vector(3 downto 0);
        inp_dig3: in std_logic_vector(3 downto 0);
        inp_dig4: in std_logic_vector(3 downto 0);

        --Decimal point needed ot not
        decimal_point: in std_logic;
        
        --Output at anode
        anode_output: out std_logic_vector(3 downto 0);

        --Output at cathode
        output_digit: out std_logic_vector(7 downto 0));
end digit_conv;

architecture digit_convertor of digit_conv is


    signal refresh_counter: std_logic_vector(1 downto 0) := "00"; 
    
    --Current digit to be displayed in 4 bit vector form
    signal input_digit: std_logic_vector(3 downto 0);

    --Current active display, this signal keeps track of the LED which is currently displaying a digit, all others LEDs are 
    --meanwhile off
    signal active_display: std_logic_vector(1 downto 0);
    
    --Clock conversion
    component clk_conv_2
    port(clk_input: in std_logic;
        clk_1ms: out std_logic);
    end component;
    signal clk_1ms: std_logic;     --converted clock signal, this signal is of 1kHz
 
    begin

        --Digit to seven-segment conversion
        process(input_digit)
        begin

            --Here the seven-segment display is based on a common high anode(1) and varying cathode for each segment, so a segment lits up if cathode is low or 0
            --The segments are in order of ABCDEFG  
            case input_digit is
                when "0000" => output_digit(7 downto 1) <= "0000001";
                when "0001" => output_digit(7 downto 1) <= "1001111";
                when "0010" => output_digit(7 downto 1) <= "0010010";
                when "0011" => output_digit(7 downto 1) <= "0000110";
                when "0100" => output_digit(7 downto 1) <= "1001100";
                when "0101" => output_digit(7 downto 1) <= "0100100";
                when "0110" => output_digit(7 downto 1) <= "0100000";
                when "0111" => output_digit(7 downto 1) <= "0001111";
                when "1000" => output_digit(7 downto 1) <= "0000000";
                when "1001" => output_digit(7 downto 1) <= "0000100";
                when others => output_digit(7 downto 1) <= "1111110";
            end case;

        end process;

        clk_conversion_2: clk_conv_2 port map (clk_input => clk,clk_1ms => clk_1ms);

        --Updating the refresh_counter as well as the current active display with 1 kHz clock
        process(clk_1ms)
        begin
            if(rising_edge(clk_1ms)) then
                if(refresh_counter="11") then
                    refresh_counter <= "00";
                    if(active_display="11") then
                        active_display <= "00";
                    else
                        active_display <= active_display + 1;
                    end if;
                else
                    refresh_counter <= refresh_counter + 1;
                end if;
            end if;
        end process;

        --Determining anode and cathode output depending upon the currently active LED and the current number on that LED to 
        --be displayed, here decimal point is also decided depending on the mode of display
        process(active_display)
        begin
            case active_display is 

            when "00" => 
                anode_output <= "1000";
                input_digit <= inp_dig1;
                output_digit(0) <= '1';
            when "01" =>
                anode_output <= "0100";
                input_digit <= inp_dig2;
                if(decimal_point='1') then 
                    output_digit(0) <= '0';
                else
                    output_digit(0) <= '1';
                end if;
            when "10" => 
                anode_output <= "0010";
                input_digit <= inp_dig3;
                output_digit(0) <= '1';
            when others =>
                anode_output <= "0001";
                input_digit <= inp_dig4;
                output_digit(0) <= '1';
            end case;

        end process;

    end digit_convertor;




--Separate module for clock conversion to 1kHz
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;    
entity clk_conv_2 is
    port(clk_input: in std_logic;
         clk_1ms: out std_logic);
end clk_conv_2;

architecture clock_convertor_2 of clk_conv_2 is

    --A counter is maintained to determine how many cycles of master clock will be needed to generate one cycle of 1kHz clock
    signal counter: std_logic_vector(27 downto 0) := (others => '0');
    begin

        --Updating counter with master clock, the counter is reset after every 10^4 cycles of mater clock(hexadecimal=2710),
        --as 10^4 cycles of 10 MHz signal would form one cycle of 1 kHz signal.
        process(clk_input)
            begin
                if(rising_edge(clk_input)) then
                    counter <= counter + 1;
                    if(counter>=x"2710") then 
                        counter <= (others => '0');
                    end if;
                end if;
        end process;

        --The converted clock is 0 for first half(i.e. 5 * 10^3 cycles, hexadecimal=1388) of master clock and 1 for the rest.

        clk_1ms <= '0' when counter < x"1388" else '1';
    end clock_convertor_2;


--Separate module for clock conversion to 1 Hz
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;    
entity clk_conv is
    port(clk_input: in std_logic;
         clk_1s: out std_logic);
end clk_conv;

architecture clock_convertor of clk_conv is

    --A counter is maintained to determine how many cycles of master clock will be needed to generate one cycle of 1 Hz clock
    signal counter: std_logic_vector(27 downto 0) := (others => '0');

    begin

        --Updating counter with master clock, the counter is reset after every 10^7 cycles of mater clock(hexadecimal=989680),
        --as 10^7 cycles of 10 MHz signal would form one cycle of 1 Hz signal.
        process(clk_input)
            begin
                if(rising_edge(clk_input)) then
                    counter <= counter + 1;
                    if(counter>=x"989680") then 
                        counter <= (others => '0');
                    end if;
                end if;
        end process;
        
        --The converted clock is 0 for first half(i.e. 5 * 10^6 cycles, hexadecimal=4C4B40) of master clock and 1 for the rest.
        clk_1s <= '0' when counter < x"4C4B40" else '1';

    end clock_convertor;