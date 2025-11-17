library IEEE;
use IEEE.std_logic_1164.all;

entity EX_MEM is
generic ( N : integer := 32 );
  port(
    -- Clock / Reset / Write-enable (stall)
    i_CLK : in  std_logic;
    i_RST : in  std_logic;     -- active-high async reset (from dffg)
    i_WE  : in  std_logic;     -- '1' = latch; '0' = hold (stall)

    -- Inputs from EX stage 
    i_ALUResult   : in  std_logic_vector(31 downto 0);
    --i_PCbrOrJmp   : in  std_logic_vector(31 downto 0);
    --i_Zero        : in  std_logic;
    --i_LT          : in  std_logic;
    --i_LTU         : in  std_logic;
    i_RS2         : in  std_logic_vector(31 downto 0);
    i_rd          : in  std_logic_vector(4 downto 0);
    i_PCplus4   : in  std_logic_vector(N-1 downto 0);
    i_Imm       : in  std_logic_vector(31 downto 0);

    -- Control to carry forward
    i_MemWrite    : in  std_logic;
    i_MemRead     : in  std_logic;
    i_ResultSrc   : in  std_logic_vector(1 downto 0);
    i_RegWrite    : in  std_logic;
    i_LoadType    : in  std_logic_vector(2 downto 0);
    --i_Jump        : in  std_logic;
    --i_Branch      : in  std_logic;
    i_Halt        : in  std_logic;

    -- Latched outputs to MEM stage
    exmem_ALUResult : out std_logic_vector(31 downto 0);
    exmem_oRS2      : out std_logic_vector(31 downto 0);
    exmem_rd        : out std_logic_vector(4 downto 0);
    exmem_PCplus4   : out std_logic_vector(N-1 downto 0);
    exmem_Imm       : out std_logic_vector(31 downto 0);
    exmem_MemWrite  : out std_logic;
    exmem_MemRead   : out std_logic;
    exmem_RegWrite  : out std_logic;
    exmem_ResultSrc : out std_logic_vector(1 downto 0);
    exmem_LoadType  : out std_logic_vector(2 downto 0);
    exmem_Halt      : out std_logic
  );
end EX_MEM;

architecture structural of EX_MEM is

  -- Components
  component RegN is
    generic(N : integer := 32);
    port(
      i_CLK : in std_logic;
      i_RST : in std_logic;
      i_WE  : in std_logic;
      i_D   : in std_logic_vector(N-1 downto 0);
      o_Q   : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component dffg is
    port(
      i_CLK : in std_logic;
      i_RST : in std_logic;
      i_WE  : in std_logic;
      i_D   : in std_logic;
      o_Q   : out std_logic
    );
  end component;
begin
  -- 32-bit datapath registers
   r_ALU    : RegN generic map(N=>32) port map(i_CLK=>i_CLK,i_RST=>i_RST,i_WE=>i_WE, i_D=>i_ALUResult,     o_Q=>exmem_ALUResult);

  r_PC4    : RegN generic map(N=>N ) port map(i_CLK=>i_CLK,i_RST=>i_RST,i_WE=>i_WE, i_D=>i_PCplus4, o_Q=>exmem_PCplus4);

  r_RS2 : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_RS2,         o_Q => exmem_oRS2);

  -- 5-bit destination register (rd)
  r_rd : RegN
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_rd,          o_Q => exmem_rd);

  r_Imm    : RegN generic map(N=>32) port map(i_CLK=>i_CLK,i_RST=>i_RST,i_WE=>i_WE, i_D=>i_Imm,     o_Q=>exmem_Imm);

  -- Multi-bit control bundles
  r_ResultSrc : RegN
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_ResultSrc,    o_Q => exmem_ResultSrc);

  r_LoadType : RegN
    generic map(N => 3)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_LoadType,     o_Q => exmem_LoadType);

  -- Single-bit control signals
  r_MemWrite : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE, i_D => i_MemWrite, o_Q => exmem_MemWrite);
  r_MemRead  : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE, i_D => i_MemRead,  o_Q => exmem_MemRead);
  r_RegWrite : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE, i_D => i_RegWrite, o_Q => exmem_RegWrite);
  -- r_Jump     : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE, i_D => i_Jump,     o_Q => exmem_Jump);
  -- r_Branch   : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE, i_D => i_Branch,   o_Q => exmem_Branch);
  r_Halt     : dffg port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE, i_D => i_Halt,     o_Q => exmem_Halt);

end structural;
