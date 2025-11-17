library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity IFID_Register is
  generic (
    N : integer := 32  -- width of PC and instruction
  );
  port (
    i_CLK     : in  std_logic;
    i_RST     : in  std_logic;                 -- synchronous reset (active high)
    i_WE      : in  std_logic;                 -- '1' = latch; '0' = hold (stall) added
    i_FLUSH   : in  std_logic;                 -- insert bubble/NOP this cycle (active high)

    -- inputs from IF stage
    i_PC      : in  std_logic_vector(N-1 downto 0);
    i_PCplus4  : in  std_logic_vector(N-1 downto 0); -- added for branch/jump calculation
    i_Instr   : in  std_logic_vector(31 downto 0);

    -- outputs to ID stage
    -- o_PC      : out std_logic_vector(N-1 downto 0);
    -- o_Instr   : out std_logic_vector(31 downto 0)
    -- changed to match naming convention
    ifid_PC       : out std_logic_vector(N-1 downto 0);
    ifid_PCplus4  : out std_logic_vector(N-1 downto 0); --added for input i_PCplus4
    ifid_Inst     : out std_logic_vector(31 downto 0)
  );
end IFID_Register;

architecture structure of IFID_Register is

  -- For RISC-V, NOP = ADDI x0, x0, 0 = 0x00000013
  constant NOP_32 : std_logic_vector(31 downto 0) := x"00000013";

  component RegN is
    generic(N : integer := 32);
      port(i_CLK: in std_logic; i_RST: in std_logic; i_WE: in std_logic;
          i_D  : in std_logic_vector(N-1 downto 0);
          o_Q  : out std_logic_vector(N-1 downto 0));
  end component;

  --signal s_holding_PC : std_logic_vector(N-1 downto 0);
  --signal s_holding_Instr        : std_logic_vector(31 downto 0);
  -- signals renamed to match output names
  signal s_Instr_D : std_logic_vector(31 downto 0);

begin
  -- Changed to dataflow/structural, do not use procedure as TA suggested
  s_Instr_D <= NOP_32 when i_FLUSH='1' else i_Instr;

  r_PC : RegN
    generic map(N => N)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_PC, o_Q => ifid_PC);

  r_PC4 : RegN
    generic map(N => N)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_PCplus4, o_Q => ifid_PCplus4);

  r_Inst : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => s_Instr_D, o_Q => ifid_Inst);

end structure;
