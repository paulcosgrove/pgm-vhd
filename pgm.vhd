--
--
--
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

    type pgm_file is file of character;

    subtype byte  is integer range 0 to 255;
    subtype short is integer range 0 to 65535;

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
    
    procedure read_byte(l : inout line; b : out byte) is
        variable c : character;
    begin
        read(l, c);
        b := character'pos(c);
    end procedure;

    procedure read_short(l : inout line; s : out short) is
        variable b1, b2 : byte;
    begin
        read_byte(l, b1);
        read_byte(l, b2);
        s := b1 * 256 + b2;
    end procedure;

    procedure get_file_size(file_name : in string; file_size : inout integer) is
        file f : pgm_file;
        variable c : character;
    begin
        file_open(f, file_name, read_mode);
        file_size := 0;
        while not endfile(f) loop
            read(f, c);
            file_size := file_size + 1;
        end loop;
        file_close(f);
    end procedure;

    procedure read_file(filename : in string; l : inout line) is
        file f : pgm_file;
        variable file_size : integer;
        variable c : character;
    begin

        if l /= null then
            deallocate(l);
        end if;

        get_file_size(filename, file_size);
        l := new string(1 to file_size);

        file_open(f, filename, read_mode);
        for i in 1 to file_size loop
            read(f, c);
            l(i) := c;
        end loop;
        file_close(f);
        
    end procedure;
    
    procedure skip_whitespace(l : inout line) is
        variable c : character;
    begin
        for h in l'low to l'high loop
            exit when l(h) /= ' ' and l(h) /= lf;
            read(l, c);
        end loop;
    end procedure;

    procedure create_image(width, height : in integer; image: inout image_ptr) is
    begin
        if image /= null then
            deallocate(image);
        end if;
        image := new pgm.image(0 to width-1, 0 to height-1);
    end procedure;

    procedure load_image(filename : in string; image : inout image_ptr) is
        variable l : line;
        variable c : character;
        variable pgm_type : string(1 to 2);
        variable i : integer;
        variable width, height, depth : integer;
    begin
        read_file(filename, l);

        -- 
        -- Read the PGM file type 'P5'
        --
        read(l, pgm_type);

        assert pgm_type = "P5" 
            report ("Unknown PGM header file type '" & pgm_type & "'")
            severity failure;

        -- 
        -- Read the width of the image in pixels
        --
        skip_whitespace(l);
        read(l, width);

        --
        -- Read the height of the image in pixels
        --
        skip_whitespace(l);
        read(l, height);
       
        --
        -- Read the number of values used to represent each pixel
        --
        skip_whitespace(l);
        read(l, depth);

        --
        -- Read a single whitespace char
        --
        read(l, c);

        --
        -- Create a new image and copy the pixel values from the file in to it
        --
        create_image(width, height, image);

        if depth < 256 then
            for y in 0 to height-1 loop
                for x in 0 to width-1 loop
                    read_byte(l, image(x, y));
                end loop;
            end loop;
        else
            for y in 0 to height-1 loop
                for x in 0 to width-1 loop
                    read_short(l, image(x, y));
                end loop;
            end loop;
        end if;

    end procedure;
    
    procedure save_image(filename : in string; image : inout image_ptr) is
        file f : pgm_file;
        variable l : line;
        variable c : character; 
        variable i : integer;

        procedure writeline(file f : pgm_file; l : inout line) is
        begin
            if l /= null then
                for x in l'left to l'right loop
                    write(f, l(x));
                end loop;
                write(f, lf);
                deallocate(l);
            else
                write(f, lf);
            end if;
        end procedure;
        variable width, height, maxval : integer;
    begin

        width  := image'high(1) - image'low(1) + 1;
        height := image'high(2) - image'low(2) + 1;

        for y in image'range(2) loop
            for x in image'range(1) loop
                maxval := max(maxval, image(x, y));
            end loop;
        end loop;

        file_open(f, filename, write_mode);

        -- 
        -- Write PGM file header
        --
        write(l, string'("P5") & lf);
        write(l, integer'image(width) & lf);
        write(l, integer'image(height) & lf);
        write(l, integer'image(maxval));
        writeline(f, l);

        if maxval < 256 then
            for y in 0 to image'right(2) loop
                for x in 0 to image'right(1) loop
                    i := image(x, y);
                    write(f, character'val(i));
                end loop;
            end loop;
        else
            for y in 0 to image'right(2) loop
                for x in 0 to image'right(1) loop
                    i := image(x, y);
                    write(f, character'val(i mod 256));
                    write(f, character'val(i / 256));
                end loop;
            end loop;
        end if;

        file_close(f);

    end procedure;

end;

