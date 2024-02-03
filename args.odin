package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:sort"
import fp "core:path/filepath"
import "core:c/libc"

arg_length: int

ArgType :: enum {
    NONE,
    FLAG,
    VALUE
}

arg_type :: proc(str: string) -> (string, ArgType) {
    if str == "" do return str, ArgType.NONE
    if str[0] == '-' do return str, ArgType.FLAG
    return str, ArgType.VALUE
}

get_arg :: proc(index: int, default: string = "") -> (string, ArgType) {
    if index > arg_length - 1 do    return arg_type(default)
    else do                         return arg_type(os.args[index])
    
}

AliasPathPair :: struct { name, path: string }
list_paths_sorted :: proc(silent := false) -> [dynamic] AliasPathPair {
    paths_arr := make_dynamic_array_len_cap([dynamic] AliasPathPair, 0, len(paths))

    for k, v in paths {
        append_elem(&paths_arr, AliasPathPair { k, v })
    }
    for i := 0; i < len(paths_arr); i += 1 {
        for j := i + 1; j < len(paths_arr); j += 1 {
            // if !os.is_dir(paths_arr[i].path) && os.is_dir(paths_arr[j].path) { // This doesn't work and, probably, is not useful/needed
                if sort.compare_strings(paths_arr[i].name, paths_arr[j].name) > 0 {
                    temp := paths_arr[i]
                    paths_arr[i] = paths_arr[j]
                    paths_arr[j] = temp
                }
            // }
        }
    }

    if silent do return paths_arr

    for p in paths_arr {

        if !os.is_dir(p.path) {
            logf("\033[0;90m - %*s -> %s\033[00m\n", -longest_alias_len, p.name, p.path)
        } else {
            logf(" - %*s -> %s\n", -longest_alias_len, p.name, p.path)
        }

    }

    return paths_arr

}


args_parse :: proc(){
    arg_length = len(os.args)

    if arg_length == 1 {
        print_help()
    }


    for i := 1; i < arg_length; i += 1 {
        arg, type := get_arg(i, "")
        switch (os.args[i]) {
            case "-a", "--add": // paths -a <alias> <path> 
                defer i += 2
                name, type1 := get_arg(i + 1)
                path, type2 := get_arg(i + 2)

                path, _ = fp.abs(path)
                if type1 == ArgType.VALUE && type2 == ArgType.VALUE {
                    if !(name in paths) {
                        if !dir_exists(strings.clone_to_cstring(path)) do logf("[WARNING] directory: \"%s\" does not currently exist!\n", path)
                        
                        io_backup()
                        paths[name] = path
                    } else do logf("[ERROR] alias by name \"%s\"(\"%s\") already exists! Please use -e, --edit\n", name, paths[name])
                } else do logln("[ERROR] -a, --add expected two values(name/alias and path), instead got:", type1, type2)
            
            case "-e", "--edit": // paths -e <alias> <new path>
                defer i += 2
                name, type1 := get_arg(i + 1)
                path, type2 := get_arg(i + 2)
                path, _ = fp.abs(path)
                if type1 == ArgType.VALUE && type2 == ArgType.VALUE {
                    if (name in paths) {
                        io_backup()
                        paths[name] = path
                    } else do logf("[ERROR] alias by name \"%s\" doesn't exists! Please use -a, --add\n", name)
                } else do logln("[ERROR] -e, --edit expected two values(name/alias and path), instead got:", type1, type2)

            case "-d", "--delete": // paths -d <alias>
                defer i += 1
                name, type1 := get_arg(i + 1)
                if type1 == ArgType.VALUE {
                    if (name in paths) {
                        io_backup()
                        delete_key(&paths, name)
                        // logln(paths)
                        logf("Path by name: \"%s\" was successfully deleted\n", name)
                    } else do logf("[ERROR] alias by name \"%s\" doesn't exists! Please use -a, --add\n", name)
                } else do logln("[ERROR] -d, -delete expected one value(name/alias), instead got:", type1)

            case "-g", "--goto": 
            defer i += 1
            name, type1 := get_arg(i + 1)
            if type1 == ArgType.VALUE {
                if name in paths {
                    if os.is_dir(paths[name]) {
                        // err := os.set_current_directory(paths[name])
                        paths["last"] = os.get_current_directory()
                        err := libc.system( strings.clone_to_cstring(strings.concatenate({"chdir \"", paths[name], "\""})) )
                        // logln(strings.concatenate({"chdir \"", paths[name], "\""}))
                        // err := os.change_directory(paths[name])
                        // os.set_env("pwd", paths[name])
                        // logln(err)
                    } else do logf("[ERROR] path at \"%s\"(\"%s\") IS NOT REAL!!!\n", name, paths[name])
                } else do logf("[ERROR] alias by name \"%s\"(\"%s\") doesn't exists! Please use -a, --add\n", name, paths[name])
            } else do logln("[ERROR] -g, --goto expected one value(name/alias), instead got:", type1)

            case "-l", "--list": list_paths_sorted()

            case "-c", "--config": errf("[ERROR] -c, --config is not yet implemented!\n")
            
            case "-h", "-?", "--help": print_help()

            case:
                if(type == ArgType.FLAG) {
                    logln("[ERROR] Unknown flag:", arg)
                    for j in i + 1..<arg_length {
                        if _, t := get_arg(j); t == ArgType.FLAG {
                            i = j - 1;
                            break;
                        }
                    }
                } else if arg in paths {

                    // logln('\'', paths[arg], '\'', sep = "")
                    logln(paths[arg])
                    if os.is_dir( paths[arg] ) do paths["last"] = os.get_current_directory() 

                } else {
                    logf ("[ERROR] orphaned parameter: \"%s\" is not an alias in paths. \n", arg)
                    logln("        Similar aliasses: ")
                    similar_aliasses := get_closest_aliasses(paths[arg])
                    for alias in similar_aliasses {
                        logf("         - %*s -> %s\n", -longest_alias_len, alias, paths[alias])
                    }
                }
        }
    }



}

HELP_TEXT :: 
`main usage: paths <alias> | cd 

paths -h, --help, -?            # prints this
paths -l, --list                # lists all paths & aliasses
paths -a, --add  <alias> <path> # adds a new path to list
paths -d, --delete <alias>      # deletes the specified alias & path
paths -e, --edit <alias> <path> # changes an existing path
paths -g, --goto <alias>        # does nothing most of the time...

list of the paths is at: %LocalAppData%\Ult1\Paths\paths.txt` 


print_help :: proc(){
    logln(HELP_TEXT)


}