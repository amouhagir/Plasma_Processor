---------------------------------------------------------------------
-- TITLE: Arithmetic Logic Unit
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/8/01
-- FILENAME: alu.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Implements the ALU.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;

entity i2c_clock is
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		enable         : in  std_logic;
		i2c_scl        : inout std_logic;
		i2c_mid        : out std_logic
	);
end; --i2c_clock

architecture logic of i2c_clock is
	signal count : NATURAL range 0 to 499;
begin

	process (clock)
	begin
		if clock'event and clock = '1' then
			if reset = '1' then
				count <= 0;
			elsif count = 499 then
				count <= 0;
			elsif enable = '1' then
				count <= count + 1;
			end if;

			if count = 0 then
				i2c_scl <= '1';
			elsif count = 250 then
				i2c_scl <= '0';
			end if;

			if count = 125 or count = 375 then
				i2c_mid <= '1';
			else
				i2c_mid <= '0';
			end if;
		end if;
	end process;
end; --architecture logic

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mlite_pack.all;

entity i2c_controller is
   port(
		clock          : in  std_logic;
		reset          : in  std_logic;
		i2c_access     : in  std_logic;
		i2c_sda        : inout std_logic;
		i2c_scl        : in std_logic;
		i2c_mid        : in std_logic;
		i2c_clock_enable : out std_logic;

		addr : in std_logic_vector(31 downto 0);
		control_in : in std_logic_vector(31 downto 0);
		control_out : out std_logic_vector(31 downto 0);
		control_update : out std_logic;
		status : out std_logic_vector(31 downto 0);
		data_in : in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0);
		data_update : out std_logic
	);
end; --i2c_controller

architecture logic of i2c_controller is
	signal status_busy : std_logic;
	signal status_ack : std_logic;
	signal control_start : std_logic;
	signal control_stop : std_logic;
	signal control_data_read : std_logic;
	signal control_data_write : std_logic;
	signal control_nack : std_logic;
	signal control_update_clean : std_logic;
	signal data_update_clean : std_logic;
	signal count : natural range 0 to 255;
	signal index : natural range 0 to 255;
	signal i2c_scl_buf : std_logic;
	signal i2c_sda_signal : std_logic;
	signal i2c_scl_signal : std_logic;
begin
	status(0) <= status_busy;
	status(1) <= status_ack;
	status(31 downto 2) <= (others => '0');
	control_start <= control_in(0);
	control_stop <= control_in(1);
	control_data_read <= control_in(2);
	control_data_write <= control_in(3);
	control_nack <= control_in(4);

	i2c_sda <= '0' when i2c_sda_signal = '0' else 'Z';

	process (clock, reset)
	begin
		if reset = '1' or i2c_access = '0' then
			status_busy <= '0';
			status_ack <= '0';
			control_out <= (others => '0');
			control_update <= '0';
			control_update_clean <= '0';
			data_out <= (others => '0');
			data_update <= '0';
			data_update_clean <= '0';
			count <= 0;
			i2c_sda_signal <= '1';
			i2c_clock_enable <= '0';
			i2c_scl_buf <= '0';
			index <= 0;
		elsif clock'event and clock = '1' then
			-- control is one cycle late when control_update_clean = '1'
			if control_start = '1' and control_update_clean = '0' then
				if count = 0 then
					status_busy <= '1';
					i2c_clock_enable <= '1';
					if i2c_scl = '1' and i2c_mid = '1' then
						i2c_sda_signal <= '0';
						count <= 1;
						index <= 7;
					end if;
				elsif i2c_scl_buf = '1' and i2c_scl = '0' then
					if count < 9 then
						index <= index - 1;
						i2c_sda_signal <= addr(index);
						count <= count + 1;
					elsif count = 9 then
						i2c_sda_signal <= '1'; -- Z
						count <= count + 1;
					end if;
				elsif i2c_scl_buf = '1' and i2c_mid = '1' then
					if count = 10 then
						control_out(31 downto 1) <= control_in(31 downto 1);
						control_out(0) <= '0';
						control_update <= '1';
						control_update_clean <= '1';

						status_busy <= '0';
						i2c_clock_enable <= '0';
						status_ack <= not(i2c_sda);
						count <= 0;
					end if;
				end if;
			elsif control_stop = '1' and control_update_clean = '0' then
				if count = 0 then
					status_busy <= '1';
					i2c_clock_enable <= '1';
					count <= 1;
				elsif i2c_scl_buf = '1' and i2c_scl = '0' then
					i2c_sda_signal <= '0';
					count <= 2;
				elsif i2c_scl_buf = '1' and i2c_mid = '1' and count = 2 then
					i2c_sda_signal <= '1';
					control_out(31 downto 2) <= control_in(31 downto 2);
					control_out(1) <= '0';
					control_out(0) <= control_in(0);
					control_update <= '1';
					control_update_clean <= '1';

					status_busy <= '0';
					i2c_clock_enable <= '0';
					count <= 0;
				end if;
			elsif control_data_read = '1' and control_update_clean = '0' then
				if count = 0 then
					status_busy <= '1';
					i2c_clock_enable <= '1';
					i2c_sda_signal <= '1'; -- Z
					count <= 1;
					index <= 7;
				elsif i2c_scl_buf = '1' and i2c_scl = '0' then
					if count = 9 then
						i2c_sda_signal <= control_nack;
						count <= count + 1;
					elsif count = 10 then
						i2c_sda_signal <= '1';
						control_out(31 downto 3) <= control_in(31 downto 3);
						control_out(2) <= '0';
						control_out(1 downto 0) <= control_in(1 downto 0);
						control_update <= '1';
						control_update_clean <= '1';

						status_busy <= '0';
						i2c_clock_enable <= '0';
						count <= 0;
					end if;
				elsif i2c_scl_buf = '1' and i2c_mid = '1' then
					if count < 9 then
						index <= index - 1;
						data_out(index) <= i2c_sda;
						data_update <= '1';
						data_update_clean <= '1';
						count <= count + 1;
					end if;
				end if;
			elsif control_data_write = '1' and control_update_clean = '0' then
				if count = 0 then
					status_busy <= '1';
					i2c_clock_enable <= '1';
					count <= 1;
					index <= 7;
				elsif  i2c_scl_buf = '1' and i2c_scl = '0' then
					if count < 9 then
						index <= index - 1;
						i2c_sda_signal <= data_in(index);
						count <= count + 1;
					elsif count = 9 then
						i2c_sda_signal <= '1'; -- Z
						count <= count + 1;
					end if;
				elsif i2c_scl_buf = '1' and i2c_mid = '1' then
					if count = 10 then
						status_ack <= not(i2c_sda);

						control_out(31 downto 4) <= control_in(31 downto 4);
						control_out(3) <= '0';
						control_out(2 downto 0) <= control_in(2 downto 0);
						control_update <= '1';
						control_update_clean <= '1';

						status_busy <= '0';
						i2c_clock_enable <= '0';
						count <= 0;
					end if;
				end if;
			end if;

			if i2c_scl = '1' then
				i2c_scl_buf <= '1';
			else
				i2c_scl_buf <= '0';
			end if;

			if control_update_clean = '1' then
				control_update_clean <= '0';
				control_update <= '0';
			end if;

			if data_update_clean = '1' then
				data_update_clean <= '0';
				data_update <= '0';
			end if;
		end if;
	end process;
end; --architecture logic
