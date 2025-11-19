library ieee;
use ieee.std_logic_1164.all;

entity hazard_unit is
  port(
    -- Younger instruction in ID
    ifid_Inst       : in  std_logic_vector(31 downto 0);

    -- Potential producers ahead in the pipe
    idex_rd         : in  std_logic_vector(4 downto 0);
    idex_RegWrite   : in  std_logic;
    exmem_rd        : in  std_logic_vector(4 downto 0);
    exmem_RegWrite  : in  std_logic;

    -- Control resolution in EX (1 when branch taken or jump)
    s_PCsrc_taken   : in  std_logic;

    -- Outputs to pipeline controls
    stallF          : out std_logic;
    stallD          : out std_logic;
    flushD          : out std_logic;  -- squash IF/ID
    flushE          : out std_logic   -- bubble ID/EX
  );
end hazard_unit;

architecture structural of hazard_unit is
  -- Decode consumer tags from IF/ID instruction
  signal rs1, rs2        : std_logic_vector(4 downto 0);
  -- RAW hazard flags (no forwarding)
  signal hazard_idex     : std_logic;
  signal hazard_exmem    : std_logic;
  signal data_hazard_any : std_logic;
begin
  -- Extract RS fields (RISC-V encoding)
  rs1 <= ifid_Inst(19 downto 15);
  rs2 <= ifid_Inst(24 downto 20);

  -- RAW if ID consumes a value still in ID/EX
  hazard_idex  <= '1' when (idex_RegWrite = '1' and idex_rd /= "00000" and
                            (idex_rd = rs1 or idex_rd = rs2))
                  else '0';

  -- RAW if ID consumes a value still in EX/MEM
  hazard_exmem <= '1' when (exmem_RegWrite = '1' and exmem_rd /= "00000" and
                            (exmem_rd = rs1 or exmem_rd = rs2))
                  else '0';

  data_hazard_any <= hazard_idex or hazard_exmem;

  -- Stalls for data hazards (no forwarding): hold IF/ID; bubble ID/EX
  stallF <= data_hazard_any;
  stallD <= data_hazard_any;
  flushE <= s_PCsrc_taken or data_hazard_any;

  -- Control hazard: taken in EX => squash the younger IF/ID instruction
  flushD <= s_PCsrc_taken;
end structural;
