# minhook-zig

Add minhook to your `build.zig.zon`:

```zig
.dependencies = .{
    .@"minhook-zig" = .{
        .url = "https://github.com/SuperAuguste/minhook-zig/archive/[commit_hash].tar.gz",
        // zig compiler will give you the hash you should insert here
    },
},
```

then use it in your `build.zig`

- `builder.dependency("minhook-zig").artifact("minhook")` to access the compiled library
- `builder.dependency("minhook-zig").module("minhook")` to access the Zig bindings
