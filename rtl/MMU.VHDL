library IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

/*
grundsätzlich ist alles RAM
MEMORY MAP

0000 - 8FFF | RAM
9000 - B9FF | EHBasic       (deaktivierbar)
BA00 - CFFF | RAM
D010 - D011 | Keyboard IN   (UART like)
D012 - D013 | Char OUT      (UART like)
D014 - D015 | UART RX       (115200 boud)
D016 - D017 | UART TX
D018        | MMU
D020 - D023 | VGA Controller
D400 - D4FF | SID
E000 - EFFF | Apple1 ASM    (deaktivierbar)
E000 - EFFF | Apple1 Basic  (deaktivierbar)
F000 - FFFF | WOZ Mon       (nicht deaktivierbar)
*/
entity apple1_buslogic is
	port (
        LED             : out unsigned(3 downto 0);
		clk             : in std_logic;
		reset           : in std_logic;
        --CPU
		cpuHasBus       : in std_logic;
		cpuWe           : in std_logic;
		cpuAddr         : in unsigned(15 downto 0);
		cpuDataIn       : out unsigned(7 downto 0);
        cpuDataOut      : in unsigned(7 downto 0);

        systemWe        : out std_logic;
        systemAddr      : out unsigned(15 downto 0);

        cs_ram          : out std_logic;
		ram_data        : in unsigned(7 downto 0);
        
        cs_ehbasicrom   : out std_logic;
        ehbasicrom_data : in unsigned(7 downto 0);
        
        cs_ps2kb        : out std_logic;
        ps2kb_data      : in unsigned(7 downto 0);

        cs_vga          : out std_logic;
        vga_data        : in unsigned(7 downto 0);

        cs_uart         : out std_logic;
        uart_data       : in unsigned(7 downto 0);
        
        cs_vga_mode     : out std_logic;
        vga_mode_data   : in unsigned(7 downto 0);

        cs_a1asmrom     : out std_logic;
        a1asmrom_data   : in unsigned(7 downto 0);
        
        cs_basicrom     : out std_logic;
        basicrom_data   : in unsigned(7 downto 0);

        cs_biosrom      : out std_logic;
		biosrom_data    : in unsigned(7 downto 0)
	);
end apple1_buslogic;

-- -----------------------------------------------------------------------

architecture rtl of apple1_buslogic is
	signal cs_ramReg        : std_logic;
    signal cs_ehbasicromReg : std_logic;
    signal cs_KeyReg        : std_logic;
    signal cs_vgaReg        : std_logic;
    signal cs_uartRXReg     : std_logic;
    signal cs_uartTXReg     : std_logic;
    signal cs_mmuReg        : std_logic;
    signal cs_vga_modeReg   : std_logic;
    signal cs_a1asmromReg   : std_logic;
    signal cs_basicromReg   : std_logic;
    signal cs_biosromReg    : std_logic;

	signal currentAddr      : unsigned(15 downto 0);
    signal mmuBanks         : unsigned(7 downto 0) := "00000000";
	
begin
    process(cs_ramReg,          ram_data,
            cs_ehbasicromReg,   ehbasicrom_data,
            cs_KeyReg,          ps2kb_data,
            cs_vgaReg,          vga_data,
            cs_uartRXReg,       uart_data,
            cs_mmuReg,
            cs_vga_modeReg,     vga_mode_data,
            cs_a1asmromReg,     a1asmrom_data,
            cs_basicromReg,     basicrom_data,
            cs_biosromReg,      biosrom_data
            )
    begin
	    --need to keep in sync with the cpu
	    --else the databus will screwed up
	   if rising_edge(clk) then
		--LED:
		--1000 = Keyboard
		--0100 = VGA
		--0010 = RAM
		--0001 = ROM
        LED             <= "1111";
		-- If no hardware is addressed the bus is floating.
        -- 0000 = F000 Wozmon
        -- 0001 = E000 Apple1 Basic
        -- 0002 = E000 Apple1 Asm
        -- 0004 = 9000 EHBasic
        if cs_mmuReg = '1' then
            if cpuWe = '1' then
                case cpuDataOut(7 downto 0) is
					     when "00000100" =>
                        mmuBanks(2) <= NOT(mmuBanks(2));
						  when "00000010" =>
                        mmuBanks(1) <= NOT(mmuBanks(1));
						  when "00000001" =>
                        mmuBanks(0) <= NOT(mmuBanks(0));
                    when "00000000" =>
                        mmuBanks <= "00000000";
                    when others =>
                        null;
                end case;
			   else
					 cpuDataIn <= mmuBanks;
            end if;
        elsif cs_ramReg = '1' then
            LED <= "1101";
			cpuDataIn <= ram_data;
        elsif cs_ehbasicromReg = '1' then
            LED <= "1110"; 
			cpuDataIn <= ehbasicrom_data;  
        elsif cs_KeyReg = '1' then	
            LED <= "0111";
            cpuDataIn <= ps2kb_data;
        elsif cs_vgaReg = '1' then	
            LED <= "1011";
            cpuDataIn <= X"00"; --fake clear bit or wozmon keep stuck
        elsif cs_uartRXReg = '1' then
            cpuDataIn <= uart_data;
        elsif cs_vga_modeReg = '1' then
            cpuDataIn <= vga_mode_data;   
        elsif cs_a1asmromReg = '1' then
            LED <= "1110"; 
			cpuDataIn <= a1asmrom_data;    
        elsif cs_basicromReg = '1' then
            LED <= "1110"; 
			cpuDataIn <= basicrom_data; 
        elsif cs_biosromReg = '1' then
            LED <= "1110"; 
			cpuDataIn <= biosrom_data;
        end if;
      end if;
    end process;
    
   process(clk)
	begin
            currentAddr <= (others => '1');
			systemWe        <= '0';
			cs_ramReg       <= '0';
            cs_ehbasicromReg<= '0';
            cs_KeyReg       <= '0';
            cs_vgaReg       <= '0';
            cs_mmuReg       <= '0';
            cs_uartRXReg    <= '0';
            cs_uartTXReg    <= '0';
            cs_vga_modeReg  <= '0';
            cs_a1asmromReg  <= '0';
            cs_basicromReg  <= '0';
            cs_biosromReg   <= '0';

            if (cpuHasBus = '1') then
				-- The 6502 CPU has the bus.					
				currentAddr <= cpuAddr;
				case cpuAddr(15 downto 12) is
                    when X"F" =>
                        cs_biosromReg <= '1';
                    when X"E" =>
                        if (mmuBanks(0) = '1') then
                            cs_basicromReg <= '1';
                        elsif (mmuBanks(1) = '1') then
                            cs_a1asmromReg <= '1';
                        else
                            cs_ramReg <= '1';
                        end if;
                    when X"B" | X"A" | X"9" =>
                        if (mmuBanks(2) = '1') then
                            cs_ehbasicromReg <= '1';
                        else
                            cs_ramReg <= '1';
                        end if;
                    when X"D" =>
                        case cpuAddr(11 downto 8) is
                            when X"0" =>
                                case cpuAddr(7 downto 0) is
                                    --Keyboard IN
                                    when X"10" | X"11" =>
                                        cs_KeyReg <= '1';
                                    --VGA - UART like
                                    when X"12" | X"13"=>
                                        cs_vgaReg <= '1';
                                    --UART rx
                                    when X"14" | X"15" =>
                                        cs_uartRXReg <= '1';
                                    --UART tx
                                    when X"16" | X"17" =>
                                        cs_uartTXReg <= '1';
                                    --MMU / Glue
                                    when X"18" =>
                                        cs_mmuReg <= '1';
                                    --VGA extended
                                    when X"20" | X"21" | X"22" | X"23"=>
                                        cs_vga_modeReg <= '1';
                                    when others =>
                                        cs_KeyReg <= '1';
                                end case;
                            when others =>
                                null;
                        end case;
                    when X"0" =>
                        cs_ramReg <= '1';
                    when others =>
                        cs_ramReg <= '1';
				end case;
                
				systemWe <= cpuWe;
			end if;
	end process;

	cs_ram          <= cs_ramReg;
    cs_ehbasicrom   <= cs_ehbasicromReg;
    cs_ps2kb        <= cs_KeyReg;
	cs_vga          <= cs_vgaReg;
    cs_vga_mode     <= cs_vga_modeReg;
    cs_uart         <= cs_uartRXReg or cs_uartTXReg;
    cs_a1asmrom     <= cs_a1asmromReg;
    cs_basicrom     <= cs_basicromReg;
    cs_biosrom      <= cs_biosromReg;

	systemAddr      <= currentAddr;

end architecture;
 
