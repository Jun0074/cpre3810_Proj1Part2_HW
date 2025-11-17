library IEEE;
use IEEE.std_logic_1164.all;

entity MEM_WB is
  port(
    -- Clock / Reset / Write-enable (stall)
    i_CLK : in  std_logic;
    i_RST : in  std_logic;     -- active-high async reset (from dffg)
    i_WE  : in  std_logic;     -- '1' = latch on rising edge; '0' = hold

    -- Inputs from MEM stage
    i_ReadData   : in  std_logic_vector(31 downto 0);  -- raw DMem.q
    i_LoadExt    : in  std_logic_vector(31 downto 0);  -- loadType-extended data
    i_ALUResult  : in  std_logic_vector(31 downto 0);  -- passthrough for WB mux
    i_PCplus4    : in  std_logic_vector(31 downto 0);  -- for JAL/JALR WB
    i_ImmU       : in  std_logic_vector(31 downto 0);  -- optional LUI WB path
    i_rd         : in  std_logic_vector(4 downto 0);   -- destination reg

    -- Control for WB
    i_ResultSrc  : in  std_logic_vector(1 downto 0);   -- 00 ALU, 01 MEM, 10 PC+4, 11 ImmU
    i_RegWrite   : in  std_logic;   -- RegFile WE
    i_Halt       : in  std_logic;   -- pipeline'd halt

    -- Latched outputs to WB
    memwb_ReadData  : out std_logic_vector(31 downto 0);
    memwb_LoadExt   : out std_logic_vector(31 downto 0);
    memwb_ALUResult : out std_logic_vector(31 downto 0);
    memwb_PCplus4   : out std_logic_vector(31 downto 0);
    memwb_ImmU      : out std_logic_vector(31 downto 0);
    memwb_rd        : out std_logic_vector(4 downto 0);

    memwb_ResultSrc : out std_logic_vector(1 downto 0);
    memwb_RegWrite  : out std_logic;
    memwb_Halt      : out std_logic
  );
end MEM_WB;

architecture structural of MEM_WB is

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
  -- 32-bit datapath values
  r_ReadData  : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_ReadData,   o_Q => memwb_ReadData);

  r_LoadExt   : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_LoadExt,    o_Q => memwb_LoadExt);

  r_ALUResult : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_ALUResult,  o_Q => memwb_ALUResult);

  r_PCplus4   : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_PCplus4,    o_Q => memwb_PCplus4);

  r_ImmU      : RegN
    generic map(N => 32)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_ImmU,       o_Q => memwb_ImmU);

  -- rd (5-bit)
  r_rd : RegN
    generic map(N => 5)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_rd,          o_Q => memwb_rd);

  -- Control
  r_ResultSrc : RegN
    generic map(N => 2)
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_ResultSrc,   o_Q => memwb_ResultSrc);

  r_RegWrite  : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_RegWrite,    o_Q => memwb_RegWrite);

  r_Halt      : dffg
    port map(i_CLK => i_CLK, i_RST => i_RST, i_WE => i_WE,
             i_D => i_Halt,        o_Q => memwb_Halt);

end structural;