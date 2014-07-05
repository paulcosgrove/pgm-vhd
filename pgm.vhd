-- 
-- VHDL-PGM - A VHDL library for reading and writing PGM (P5) files.
--
-- For an example of how to use the library, see pgm_tb.vhd
--
-- Copyright 2014, Paul Cosgrove
--
package pgm is

    subtype pixel is integer range 0 to 65535;
    type image is array (natural range <>, natural range <>) of pixel;
    type image_ptr is access image;

    procedure create_image(width, height : in integer; image: inout image_ptr);
    procedure load_image(filename : in string; image : inout image_ptr);
    procedure save_image(filename : in string; image : inout image_ptr);

end package pgm;

use std.textio.all;

package body pgm is

    constant BYTE_MAX  : integer := 256;
    constant SHORT_MAX : integer := 65535;

    type pgm_file is file of character;

    subtype byte is integer range 0 to BYTE_MAX;
    subtype short is integer range 0 to SHORT_MAX;

    procedure create_image(width, height : in integer; image: inout image_ptr) is
    begin
        if image /= null then
            deallocate(image);
        end if;
        image := new pgm.image(0 to width-1, 0 to height-1);
    end procedure;
    
    function max(a, b : integer) return integer is
    begin
        if a > b then 
            return a;
        else 
            return b;
        end if;
    end max;

    procedure print(s : in string) is
        variable l : line;
    begin
        write(l, s);
        writeline(output, l);
    end procedure;
    
    procedure skip_whitespace(l : inout line) is
        variable c : character;
    begin
        for h in l'low to l'high loop
            exit when l(h) /= ' ' and l(h) /= lf;
            read(l, c);
        end loop;
    end procedure;

    procedure load_image(filename : in string; image : inout image_ptr) is
        file f : pgm_file;
        variable l : line;
        variable c, c2 : character;
        variable pgm_type : string(1 to 2);
        variable width, height, maxval : integer;
    begin

        -- Read entire file into memory
        file_open(f, filename, read_mode);
        while not endfile(f) loop
            read(f, c);
            write(l, c);
        end loop;
        file_close(f);

        read(l, pgm_type);
        assert pgm_type = "P5" 
            report ("Unknown PGM header file type '" & pgm_type & "'") 
            severity failure;

        skip_whitespace(l);
        read(l, width);

        skip_whitespace(l);
        read(l, height);

        skip_whitespace(l);
        read(l, maxval);

        read(l, c);

        create_image(width, height, image);

        -- Read the image pixels
        if maxval > BYTE_MAX then
            -- Read 16-bit pixels
            for y in image'range(2) loop
                for x in image'range(1) loop
                    read(l, c);
                    read(l, c2);
                    image(x, y) := character'pos(c) * 256 + character'pos(c2);
                end loop;
            end loop;
        else
            -- Read 8-bit pixels
            for y in image'range(2) loop
                for x in image'range(1) loop
                    read(l, c);
                    image(x, y) := character'pos(c);
                end loop;
            end loop;
        end if;

    end load_image;

    procedure save_image(filename : in string; image : inout image_ptr) is
        file     f : pgm_file;
        variable l : line;
        variable maxval : integer;
    begin

        file_open(f, filename, write_mode);
        
        -- Find the maximum pixel value 
        for y in image'range(2) loop
            for x in image'range(1) loop
                maxval := max(maxval, image(x, y));
            end loop;
        end loop;
       
        -- Write PGM file header
        write(l, string'("P5") & lf);
        write(l, integer'image(image'length(1)) & " ");
        write(l, integer'image(image'length(2)) & lf);
        write(l, integer'image(maxval) & lf);

        -- Write the pixels
        if maxval > BYTE_MAX then
            -- Write 16-bit pixels
            for y in image'range(2) loop
                for x in image'range(1) loop
                    write(l, character'val(image(x, y) mod 256));
                    write(l, character'val(image(x, y) / 256));
                end loop;
            end loop;
        else
            -- Write 8-bit pixels
            for y in image'range(2) loop
                for x in image'range(1) loop
                    write(l, character'val(image(x, y)));
                end loop;
            end loop;
        end if;
        
        for x in l'range(1) loop
            write(f, l(x));
        end loop;
        deallocate(l);

        file_close(f);

    end save_image;

end;

