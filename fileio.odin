package main

import "core:c"
import "core:io"
import "core:os"
import "core:strings"
import "core:bytes"
import "core:fmt"
import "core:bufio"
import "core:time"

foreign import fun "fun.a"
foreign fun {
    dir_exists :: proc(path: cstring) -> bool ---
} // there are "os.exists()" & "os.is_dir()", but whatever. This works too...


paths : map[string] string
appdata : string

io_init :: proc(){
    appdata = strings.concatenate( { os.get_env("localappdata"), "\\Ult1\\Paths\\" } )
    os.make_directory(appdata)

    pathsf, _ := os.open( strings.concatenate({ appdata, "paths.txt" }), os.O_RDONLY | os.O_CREATE )

    buffer, ok := os.read_entire_file_from_handle(pathsf)
    assert(ok)
    os.close(pathsf)

    line_list := bytes.split(buffer, { '\n' })

    if len(line_list[len(line_list) - 1]) == 0 do line_list = line_list[:len(line_list) - 1] // "removes"/hides last element, if it is just a newline
    for &path, i in line_list do path, _ = bytes.remove(path, { 13 }, len(path)) // what the fuck?  removes all carriage returns... I think...
    
    for i := 0; i + 1 < len(line_list); i += 2 {
        if len(line_list[i]) > longest_alias_len do longest_alias_len = len(line_list[i])
        if len(line_list[i + 1]) > longest_path_len do longest_path_len = len(line_list[i + 1])

        paths[string(line_list[i])] = string(line_list[i + 1])
    }
}

// data gets corrupted when scope exists, I have no idea why...
io_parse_file :: proc(){

    // stream := os.stream_from_handle(pathsf)
    // s: bufio.Scanner

    // bufio.scanner_init(&s, stream)
    // defer bufio.scanner_destroy(&s)

    // for {
    //     if !bufio.scanner_scan(&s) do break
    //     name, _ := bytes.remove(transmute([] u8) bufio.scanner_text(&s), { 13 }, 1)
        
    //     if !bufio.scanner_scan(&s) do break
    //     path, _ := bytes.remove(transmute([] u8) bufio.scanner_text(&s), { 13 }, 1)

    //     paths[string(name)] = string(path)
    // }

}

io_save :: proc (fpath: string){
    arr := list_paths_sorted(true)

    builder : strings.Builder
    strings.builder_init(&builder)

    for p in arr {
        fmt.sbprintln(&builder, p.name, p.path, sep = "\r\n")
    }

    os.write_entire_file(fpath, transmute([] byte) strings.to_string(builder))
}

io_backup :: proc(){
    os.make_directory(strings.concatenate({appdata, "backups"}), 0)

    {
        backup_folder, _ := os.open(strings.concatenate({appdata, "backups"}))
        my_god_dude, _ := os.read_dir(backup_folder, 0)
        if len(my_god_dude) > 1000 {
            os.remove(my_god_dude[0].fullpath)
        }
    }

    t := time.now()
    year, month, day := time.date(t)
    sec := t._nsec / 1e9
    min := sec / 60
    hour := min / 60

    formatted_path := fmt.aprintf("%sbackups\\%d-%02d-%02d--%02d-%02d-%02d.txt", appdata, year, int(month), day, hour % 24, min % 60, sec % 60)
    i := 0
    for os.exists(formatted_path) {
        formatted_path = fmt.aprintf("%sbackups\\%d-%02d-%02d--%02d-%02d-%02d--#%d.txt", appdata, year, int(month), day, hour % 24, min % 60, sec % 60, i)
        if i > 15 {
            errf("What the f*ck? Why have 15 backup files been created within the same second!?")
            os.exit(1)
        }
        i += 1
    }

    io_save(formatted_path)
    // there is no os.copy() and I cba to do (win32.)CopyFile()

}