library ieee;
use ieee.std_logic_1164.all;

package onfi is

    type master_states is (IDLE, RESET, READID, READPARAM, PAGEPROGRAM, READSTATUS, READ, ERASE, SETFEATURES, GETFEATURES ,SUBWAIT);
    type substates is ( subIDLE, LATCHCMD, LATCHADDR, WRITEDATA, READDATA);
    type delay_type is (CMDWAIT, ADDRWAIT, WRITEWAIT, READWAIT, WRITEDONE, WAITRB);   

end onfi;