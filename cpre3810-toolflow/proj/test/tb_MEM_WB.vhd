library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_MEM_WB is
end entity;

architecture tb of tb_MEM_WB is
  -- Clock/reset/WE
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';   -- active-high async (from dffg)
  signal we  : std_logic := '1';   -- '1' latch, '0' hold

  -- Inputs from MEM stage
  signal i_ReadData  : std_logic_vector(31 downto 0) := (others => '0');
  signal i_LoadExt   : std_logic_vector(31 downto 0) := (others => '0');
  signal i_ALUResult : std_logic_vector(31 downto 0) := (others => '0');
  signal i_PCplus4   : std_logic_vector(31 downto 0) := (others => '0');
  signal i_ImmU      : std_logic_vector(31 downto 0) := (others => '0');
  signal i_rd        : std_logic_vector(4 downto 0)  := (others => '0');

  -- Control for WB
  signal i_ResultSrc : std_logic_vector(1 downto 0) := (others => '0');
  signal i_RegWrite  : std_logic := '0';
  signal i_Halt      : std_logic := '0';

  -- Outputs to WB
  signal memwb_ReadData  : std_logic_vector(31 downto 0);
  signal memwb_LoadExt   : std_logic_vector(31 downto 0);
  signal memwb_ALUResult : std_logic_vector(31 downto 0);
  signal memwb_PCplus4   : std_logic_vector(31 downto 0);
  signal memwb_ImmU      : std_logic_vector(31 downto 0);
  signal memwb_rd        : std_logic_vector(4 downto 0);

  signal memwb_ResultSrc : std_logic_vector(1 downto 0);
  signal memwb_RegWrite  : std_logic;
  signal memwb_Halt      : std_logic;

  constant Tclk : time := 10 ns;
begin
  -- clock
  clk_proc : process
  begin
    clk <= '0'; wait for Tclk/2;
    clk <= '1'; wait for Tclk/2;
  end process;

  -- DUT
  dut : entity work.MEM_WB
    port map(
      i_CLK => clk,
      i_RST => rst,
      i_WE  => we,

      i_ReadData  => i_ReadData,
      i_LoadExt   => i_LoadExt,
      i_ALUResult => i_ALUResult,
      i_PCplus4   => i_PCplus4,
      i_ImmU      => i_ImmU,
      i_rd        => i_rd,

      i_ResultSrc => i_ResultSrc,
      i_RegWrite  => i_RegWrite,
      i_Halt      => i_Halt,

      memwb_ReadData  => memwb_ReadData,
      memwb_LoadExt   => memwb_LoadExt,
      memwb_ALUResult => memwb_ALUResult,
      memwb_PCplus4   => memwb_PCplus4,
      memwb_ImmU      => memwb_ImmU,
      memwb_rd        => memwb_rd,

      memwb_ResultSrc => memwb_ResultSrc,
      memwb_RegWrite  => memwb_RegWrite,
      memwb_Halt      => memwb_Halt
    );

  -- start test
  stim : process
  begin
    -- Phase 0: async reset asserted with nonzero inputs (observe outputs are 0)
    rst <= '1'; we <= '1';
    i_ReadData  <= x"DEADBEEF";
    i_LoadExt   <= x"CAFEBABE";
    i_ALUResult <= x"01020304";
    i_PCplus4   <= x"11111111";
    i_ImmU      <= x"22222222";
    i_rd        <= "10101";
    i_ResultSrc <= "10";
    i_RegWrite  <= '1';
    i_Halt      <= '1';
    wait for 25 ns;

    -- Phase 1: deassert reset, apply Vector A and latch on rising edge
    rst <= '0';
    i_ReadData  <= x"0000AAAA";
    i_LoadExt   <= x"0000BBBB";
    i_ALUResult <= x"0000CCCC";
    i_PCplus4   <= x"0000DDDD";
    i_ImmU      <= x"0000EEEE";
    i_rd        <= "00010";
    i_ResultSrc <= "00";
    i_RegWrite  <= '1';
    i_Halt      <= '0';
    wait until rising_edge(clk);
    wait for 20 ns;

    -- Phase 2: stall (WE=0), apply Vector B; outputs should hold previous values
    we <= '0';
    i_ReadData  <= x"A5A5A5A5";
    i_LoadExt   <= x"5A5A5A5A";
    i_ALUResult <= x"ABCDEF12";
    i_PCplus4   <= x"2468ACE0";
    i_ImmU      <= x"13579BDF";
    i_rd        <= "11111";
    i_ResultSrc <= "01";
    i_RegWrite  <= '0';
    i_Halt      <= '1';
    wait for 30 ns;

    -- Phase 3: release stall (WE=1), latch Vector B on rising edge
    we <= '1';
    wait until rising_edge(clk);
    wait for 40 ns;

    wait;
  end process;
end architecture;
