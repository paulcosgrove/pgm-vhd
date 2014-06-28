use std.textio.all;

library work;
use work.pgm.all;

entity pgm_example is
end entity pgm_example;

architecture behavioral of pgm_example is

    procedure print(s : in string) is
        variable l : line;
    begin
        write(l, s);
        writeline(output, l);
    end procedure;

begin

    process
        variable image : image_ptr;
        variable width : integer;
    begin

        -- Load a PGM image from file
        load_image("brake.pgm", image);
        
        -- Display the pixel values in the image
        for y in image'range(2) loop
            for x in image'range(1) loop
                image(x, y):= image(x, y) / 254;
            end loop;
        end loop;

        image(0, 0) := 0;

        save_image("test2.pgm", image);

        -- Wait forever
        wait;
    end process;

end behavioral;

