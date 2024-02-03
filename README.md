# paths

Another way to alias paths in a terminal. I don't know, meant for Windows only.

```shell
main usage: paths <alias> | cd
```

```python
paths -h, --help, -?            # prints this
paths -l, --list                # lists all paths & aliasses
paths -a, --add  <alias> <path> # adds a new path to list
paths -d, --delete <alias>      # deletes the specified alias & path
paths -e, --edit <alias> <path> # changes an existing path
paths -g, --goto <alias>        # does nothing most of the time...
```

*list of the paths is at: `%LocalAppData%\Ult1\Paths\paths.txt`*
