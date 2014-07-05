-- 
-- VHDL-PGM Example - An example demonstrating the use of the VHDL-PGM library
--                    for reading and writing PGM files.
--
-- Copyright 2014, Paul Cosgrove
--

use std.textio.all;

library work;
use work.pgm.all;

entity pgm_tb is
end entity pgm_tb;

architecture behavioral of pgm_tb is
begin

    pgm_test : process
        variable image : image_ptr;
        variable width : integer;
    begin

        -- Load a PGM image from file
        load_image("test_in.pgm", image);
        
        -- Modify some pixels in the image
        image(0, 0) := 0;
        image(1, 1) := 128;

        -- Save the modified image
        save_image("test_out.pgm", image);

        -- Wait forever
        wait;
    end process pgm_test;

end behavioral;

