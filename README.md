# Farhang

Farhang is a dictionary app written in Ruby with Sinatra and Sequel.

It is not a dictionary itself but a nice and simple interface to a dictionary
stored in a database.

See it in action with the original German-Persian dictionary at
[farhang.im](https://www.farhang.im)

Download the current database with all its entries via
[farhang.im/app/download/db](https://www.farhang.im/app/download/db)

## icu
ICU support for sqlite is necessary in order to get proper search
results (utf-8 support through icu)

Depending on the local system where farhang app runs the library has to
be recompiled and the name of the file changed.

Make sure you have sqlite and the header files installed. Then run

```
gcc -shared icu.c `icu-config --ldflags` -o libSqliteIcu.so

# or

 gcc -shared -fIPC icu.c `icu-config --ldflags` -o libSqliteIcu.so
```

If there is an error because farhang can't find another library you may
have to rename the library.

See this post for more information: [http://sqlite.1065341.n5.nabble.com/Error-dlsym-0x7fa073e02c60-sqlite3-sqliteicu-init-symbol-not-found-td104236.html#a104241](http://sqlite.1065341.n5.nabble.com/Error-dlsym-0x7fa073e02c60-sqlite3-sqliteicu-init-symbol-not-found-td104236.html#a104241)

## Notes
Feel free to fork this repository or the dictionary, MIT and CC licensed.
