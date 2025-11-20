library ieee;
use ieee.std_logic_1164.all;
-- reduced hazard unit after data forwarding implementation
entity hazard_unit is
  port(
      ifid_Inst      : in  std_logic_vector(31 downto 0);
      idex_rd        : in  std_logic_vector(4 downto 0);
      idex_MemRead   : in  std_logic;
      s_PCsrc_taken  : in  std_logic;

      stallF         : out std_logic;
      stallD         : out std_logic;
      flushD         : out std_logic;
      flushE         : out std_logic
  );
end hazard_unit;

architecture structure of hazard_unit is
  signal rs1, rs2 : std_logic_vector(4 downto 0);
  signal load_use_hazard : std_logic;
begin

  rs1 <= ifid_Inst(19 downto 15);
  rs2 <= ifid_Inst(24 downto 20);

  -- load-use hazard
  load_use_hazard <= '1' when
      (idex_MemRead = '1' and idex_rd /= "00000" and
       (idex_rd = rs1 or idex_rd = rs2))
     else '0';

  -- control hazards
  -- always flush IF/ID on taken branch or jump
  flushD <= s_PCsrc_taken;

  -- flush ID/EX on:
  -- taken branch / jump
  -- load-use hazard
  flushE <= s_PCsrc_taken or load_use_hazard;

  -- stall on load-use only
  stallF <= load_use_hazard;
  stallD <= load_use_hazard;

end structure;
