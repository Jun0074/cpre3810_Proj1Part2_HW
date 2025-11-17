library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_EX_MEM is
end entity;

architecture tb of tb_EX_MEM is
  -- Clock/reset/WE
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';  -- active-high async (dffg)
  signal we  : std_logic := '1';

  -- Inputs to EX_MEM
  signal i_ALUResult : std_logic_vector(31 downto 0) := (others => '0');
  signal i_PCbrOrJmp : std_logic_vector(31 downto 0) := (others => '0');
  signal i_Zero      : std_logic := '0';
  signal i_LT        : std_logic := '0';
  signal i_LTU       : std_logic := '0';
  signal i_RS2       : std_logic_vector(31 downto 0) := (others => '0');
  signal i_rd        : std_logic_vector(4 downto 0)  := (others => '0');

  signal i_MemWrite  : std_logic := '0';
  signal i_MemRead   : std_logic := '0';
  signal i_ResultSrc : std_logic_vector(1 downto 0) := (others => '0');
  signal i_RegWrite  : std_logic := '0';
  signal i_LoadType  : std_logic_vector(2 downto 0) := (others => '0');
  signal i_Jump      : std_logic := '0';
  signal i_Branch    : std_logic := '0';
  signal i_Halt      : std_logic := '0';

  -- Outputs from EX_MEM
  signal exmem_ALUResult : std_logic_vector(31 downto 0);
  signal exmem_PCbrOrJmp : std_logic_vector(31 downto 0);
  signal exmem_Zero      : std_logic;
  signal exmem_LT        : std_logic;
  signal exmem_LTU       : std_logic;
  signal exmem_RS2       : std_logic_vector(31 downto 0);
  signal exmem_rd        : std_logic_vector(4 downto 0);

  signal exmem_MemWrite  : std_logic;
  signal exmem_MemRead   : std_logic;
  signal exmem_ResultSrc : std_logic_vector(1 downto 0);
  signal exmem_RegWrite  : std_logic;
  signal exmem_LoadType  : std_logic_vector(2 downto 0);
  signal exmem_Jump      : std_logic;
  signal exmem_Branch    : std_logic;
  signal exmem_Halt      : std_logic;

  constant Tclk : time := 10 ns;
begin
  -- clock
  clk_proc : process
  begin
    clk <= '0'; wait for Tclk/2;
    clk <= '1'; wait for Tclk/2;
  end process;

  -- DUT
  dut : entity work.EX_MEM
    port map(
      i_CLK => clk,
      i_RST => rst,
      i_WE  => we,

      i_ALUResult => i_ALUResult,
      i_PCbrOrJmp => i_PCbrOrJmp,
      i_Zero      => i_Zero,
      i_LT        => i_LT,
      i_LTU       => i_LTU,
      i_RS2       => i_RS2,
      i_rd        => i_rd,

      i_MemWrite  => i_MemWrite,
      i_MemRead   => i_MemRead,
      i_ResultSrc => i_ResultSrc,
      i_RegWrite  => i_RegWrite,
      i_LoadType  => i_LoadType,
      i_Jump      => i_Jump,
      i_Branch    => i_Branch,
      i_Halt      => i_Halt,

      exmem_ALUResult => exmem_ALUResult,
      exmem_PCbrOrJmp => exmem_PCbrOrJmp,
      exmem_Zero      => exmem_Zero,
      exmem_LT        => exmem_LT,
      exmem_LTU       => exmem_LTU,
      exmem_RS2       => exmem_RS2,
      exmem_rd        => exmem_rd,

      exmem_MemWrite  => exmem_MemWrite,
      exmem_MemRead   => exmem_MemRead,
      exmem_ResultSrc => exmem_ResultSrc,
      exmem_RegWrite  => exmem_RegWrite,
      exmem_LoadType  => exmem_LoadType,
      exmem_Jump      => exmem_Jump,
      exmem_Branch    => exmem_Branch,
      exmem_Halt      => exmem_Halt
    );

    -- test begin
  stim : process
  begin
    -- Phase 0: async reset asserted with nonzero inputs (observe outputs go 0)
    rst <= '1'; we <= '1';
    i_ALUResult <= x"DEADBEEF"; i_PCbrOrJmp <= x"12345678";
    i_Zero <= '1'; i_LT <= '1'; i_LTU <= '1';
    i_RS2 <= x"CAFEBABE"; i_rd <= "10101";
    i_MemWrite <= '1'; i_MemRead <= '1'; i_ResultSrc <= "10";
    i_RegWrite <= '1'; i_LoadType <= "011"; i_Jump <= '1'; i_Branch <= '1'; i_Halt <= '1';
    wait for 25 ns;

    -- Phase 1: deassert reset, latch vector A on next rising edge
    rst <= '0';
    i_ALUResult <= x"0000ABCD"; i_PCbrOrJmp <= x"00001234";
    i_Zero <= '0'; i_LT <= '1'; i_LTU <= '0';
    i_RS2 <= x"11111111"; i_rd <= "00010";
    i_MemWrite <= '1'; i_MemRead <= '0'; i_ResultSrc <= "00";
    i_RegWrite <= '1'; i_LoadType <= "000"; i_Jump <= '0'; i_Branch <= '1'; i_Halt <= '0';
    wait until rising_edge(clk);
    wait for 20 ns;

    -- Phase 2: stall (WE=0), drive vector B, outputs should hold previous
    we <= '0';
    i_ALUResult <= x"AAAA5555"; i_PCbrOrJmp <= x"22222222";
    i_Zero <= '1'; i_LT <= '0'; i_LTU <= '1';
    i_RS2 <= x"33333333"; i_rd <= "11111";
    i_MemWrite <= '0'; i_MemRead <= '1'; i_ResultSrc <= "01";
    i_RegWrite <= '0'; i_LoadType <= "100"; i_Jump <= '1'; i_Branch <= '0'; i_Halt <= '1';
    wait for 30 ns;

    -- Phase 3: release stall (WE=1), latch vector B
    we <= '1';
    wait until rising_edge(clk);
    wait for 30 ns;
    
    wait;
  end process;
end architecture;
