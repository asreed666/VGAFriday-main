-- adc driver to read channel 1 and 3 of arduino header and return
-- 8 bit values for paddle position 
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity paddles is
    port (
        -- Clocks
        MAX10_CLK1_50   : in std_logic;
        -- KEY
        reset           : in std_logic;
        -- paddle postioins from adc
        channel1			: out std_logic_vector(11 downto 0);
        channel2			: out std_logic_vector(11 downto 0);
        channel3			: out std_logic_vector(11 downto 0);
        channel4			: out std_logic_vector(11 downto 0)
    );
end entity;


architecture A of paddles is
    component hello_adc is
        port (
            --  adc_control_core_command.valid
            adc_control_core_command_valid          : in  std_logic;
            -- .channel
            adc_control_core_command_channel        : in  std_logic_vector(4 downto 0) := (others => '0');
            -- .startofpacket
            adc_control_core_command_startofpacket  : in  std_logic := '0';
            -- .endofpacket
            adc_control_core_command_endofpacket    : in  std_logic := '0';
            -- .ready
            adc_control_core_command_ready          : out std_logic;
            -- adc_control_core_response.valid
            adc_control_core_response_valid         : out std_logic;
            -- .channel
            adc_control_core_response_channel       : out std_logic_vector(4 downto 0);
            -- .data
            adc_control_core_response_data          : out std_logic_vector(11 downto 0);
            -- .startofpacket
            adc_control_core_response_startofpacket : out std_logic;
            -- .endofpacket
            adc_control_core_response_endofpacket   : out std_logic;
            -- clk.clk
            clk_clk                                 : in  std_logic := '0';
            -- clock_bridge_out_clk.clk
            clock_bridge_out_clk_clk                : out std_logic;
            -- reset.reset_n
            reset_reset_n                           : in  std_logic := '0'
        );
    end component hello_adc;

    -- ADC signals
    signal req_channel, cur_channel : std_logic_vector(4 downto 0);
    signal sample_data1              : std_logic_vector(11 downto 0);
    signal sample_data2              : std_logic_vector(11 downto 0);
    signal sample_data3              : std_logic_vector(11 downto 0);
    signal adc_cc_command_ready     : std_logic;
    signal adc_cc_response_valid    : std_logic;
    signal adc_cc_response_channel  : std_logic_vector(4 downto 0);
    signal adc_cc_response_data     : std_logic_vector(11 downto 0);
	 
	 -- paddle channel selection (Channel 1 (001) to 4 (100))
	 signal channel : std_logic_vector(4 downto 0);

    -- system clock and reset
    signal sys_clk, nreset : std_logic;
begin
    -- system reset
    nreset <= not reset;

    -- calculate channel used for sampling
    -- Available channels on DE10-Lite are 1-6
    -- use paddle vector to select the channel
    -- channel = '0' map to arduino ADC_IN0
    -- channel = '1' map to arduino ADC_IN1
    -- channel = '2' map to arduino ADC_IN2
    -- channel = '3' map to arduino ADC_IN3
    adc_command : process(sys_clk, channel, adc_cc_command_ready)
        variable temp : std_logic_vector(4 downto 0) := "00001";
   begin -- wait for adc ready
        if rising_edge(sys_clk) then
            if (adc_cc_command_ready = '1') then
							req_channel <= channel;
            end if;
        end if;
    end process;

    -- read the sampled value from the ADC
    adc_read : process(sys_clk, adc_cc_response_valid)
        variable reading : std_logic_vector(11 downto 0) := (others => '0');
        variable ch      : std_logic_vector(4 downto 0) := (others => '0');
   begin
        if rising_edge(sys_clk) then
            if (adc_cc_response_valid = '1') then
                reading := adc_cc_response_data;
                ch := adc_cc_response_channel; -- read channels in turn
							if (ch = "00001") then
								channel1 <= reading(11 downto 0);
								channel <= "00010" ; -- flip to channel 2
							elsif (ch = "00010") then
								channel2 <= reading(11 downto 0);
								channel <= "00011"; -- flip to channel 3
							elsif (ch = "00011") then
								channel3 <= reading(11 downto 0);
								channel <= "00100"; -- flip to channel 4
							else
								channel4 <= reading(11 downto 0);
								channel <= "00001"; -- flip to channel 1
							end if;
						end if;
        end if;
        cur_channel <= ch;

    end process;
	 

    -- instantiate QSYS subsystem with ADC and PLL
    qsys_u0 : component hello_adc
    port map (
        -- command always valid
        adc_control_core_command_valid => '1',
        adc_control_core_command_channel => req_channel,
        -- startofpacket and endofpacket are ignored in adc_control_core
        adc_control_core_command_startofpacket => '1',
        adc_control_core_command_endofpacket => '1',
        adc_control_core_command_ready => adc_cc_command_ready,
        adc_control_core_response_valid => adc_cc_response_valid,
        adc_control_core_response_channel => adc_cc_response_channel,
        adc_control_core_response_data => adc_cc_response_data,
        adc_control_core_response_startofpacket => open,
        adc_control_core_response_endofpacket => open,
        clk_clk => MAX10_CLK1_50,
        clock_bridge_out_clk_clk => sys_clk,
        reset_reset_n => nreset
    );
end architecture A;
