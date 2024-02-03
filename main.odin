package main

import "core:log"
import "core:fmt"
import "core:strings"
import "core:slice"
import "core:os"

logln :: fmt.println
logf  :: fmt.printf
log   :: fmt.print

error_count, warning_count := 0, 0

errf :: proc(format: string, args: ..any, flush := true){
    fmt.eprintf(format, args, flush)
    error_count += 1
    os.exit(1)
}

warn :: proc(format: string, args: ..any, flush := true){
    fmt.eprintf(format, args, flush)
    warning_count += 1
}

longest_alias_len, longest_path_len := 0, 0

main :: proc(){
    paths = make_map(map[string] string)
    io_init()

    args_parse()

    io_save(strings.concatenate({ appdata, "paths.txt" }))
}

_max :: proc(nums: [dynamic] int) -> int {
    maximum := ~int(0x7fffffff) // INT_MIN
    index := -1 
    for num, i in nums {
        if num > maximum {
            maximum, index = num, i
        }
    }
    return index
}

 // higher distance is worse
get_closest_aliasses :: proc(original: string) -> [dynamic] string {
    top: [dynamic] string
    scores: [dynamic] int
    
    for k, v in paths {
        
        distance := strings.levenshtein_distance(original, k)
        if len(top) < 3 {
            append(&top, k)
            append(&scores, distance)
        } else if maximum_i := _max(scores); distance < scores[maximum_i] {
            top   [maximum_i] = k
            scores[maximum_i] = distance
        }
    }
    return top
}
