const std = @import("std");

pub const bindings = struct {
    /// MinHook Error Codes.
    pub const Status = enum(i32) {
        /// Unknown error. Should not be returned.
        unknown = -1,
        /// Successful.
        ok = 0,
        /// MinHook is already initialized.
        error_already_initialized,
        /// MinHook is not initialized yet, or already uninitialized.
        error_not_initialized,
        /// The hook for the specified target function is already created.
        error_already_created,
        /// The hook for the specified target function is not created yet.
        error_not_created,
        /// The hook for the specified target function is already enabled.
        error_enabled,
        /// The hook for the specified target function is not enabled yet, or already
        /// disabled.
        error_disabled,
        /// The specified pointer is invalid. It points the address of non-allocated
        /// and/or non-executable region.
        error_not_executable,
        /// The specified target function cannot be hooked.
        error_unsupported_function,
        /// Failed to allocate memory.
        error_memory_alloc,
        /// Failed to change the memory protection.
        error_memory_protect,
        /// The specified module is not loaded.
        error_module_not_found,
        /// The specified function is not found.
        error_function_not_found,
    };

    /// Initialize the MinHook library. You must call this function EXACTLY ONCE
    /// at the beginning of your program.
    pub extern fn MH_Initialize() callconv(std.os.windows.WINAPI) Status;

    /// Uninitialize the MinHook library. You must call this function EXACTLY
    /// ONCE at the end of your program.
    pub extern fn MH_Uninitialize() callconv(std.os.windows.WINAPI) Status;

    /// Creates a hook for the specified target function, in disabled state.
    /// Parameters:
    ///   pTarget     [in]  A pointer to the target function, which will be
    ///                     overridden by the detour function.
    ///   pDetour     [in]  A pointer to the detour function, which will override
    ///                     the target function.
    ///   ppOriginal  [out] A pointer to the trampoline function, which will be
    ///                     used to call the original target function.
    ///                     This parameter can be NULL.
    pub extern fn MH_CreateHook(
        target: *anyopaque,
        detour: *anyopaque,
        original: ?**anyopaque,
    ) callconv(std.os.windows.WINAPI) Status;

    /// Creates a hook for the specified API function, in disabled state.
    /// Parameters:
    ///   pszModule   [in]  A pointer to the loaded module name which contains the
    ///                     target function.
    ///   pszProcName [in]  A pointer to the target function name, which will be
    ///                     overridden by the detour function.
    ///   pDetour     [in]  A pointer to the detour function, which will override
    ///                     the target function.
    ///   ppOriginal  [out] A pointer to the trampoline function, which will be
    ///                     used to call the original target function.
    ///                     This parameter can be NULL.
    pub extern fn MH_CreateHookApi(
        module_name: [*:0]const u16,
        proc_name: [*:0]const u8,
        detour: *anyopaque,
        original: ?**anyopaque,
    ) callconv(std.os.windows.WINAPI) Status;

    /// Creates a hook for the specified API function, in disabled state.
    /// Parameters:
    ///   pszModule   [in]  A pointer to the loaded module name which contains the
    ///                     target function.
    ///   pszProcName [in]  A pointer to the target function name, which will be
    ///                     overridden by the detour function.
    ///   pDetour     [in]  A pointer to the detour function, which will override
    ///                     the target function.
    ///   ppOriginal  [out] A pointer to the trampoline function, which will be
    ///                     used to call the original target function.
    ///                     This parameter can be NULL.
    ///   ppTarget    [out] A pointer to the target function, which will be used
    ///                     with other functions.
    ///                     This parameter can be NULL.
    pub extern fn MH_CreateHookApiEx(
        module_name: [*:0]const u16,
        proc_name: [*:0]const u8,
        detour: *anyopaque,
        original: ?**anyopaque,
    ) callconv(std.os.windows.WINAPI) Status;

    /// Removes an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    pub extern fn MH_RemoveHook(target: *anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Enables an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                enabled in one go.
    pub extern fn MH_EnableHook(target: *anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Disables an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                disabled in one go.
    pub extern fn MH_DisableHook(target: *anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Queues to enable an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                queued to be enabled.
    pub extern fn MH_QueueEnableHook(target: *anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Queues to disable an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                queued to be disabled.
    pub extern fn MH_QueueDisableHook(target: *anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Applies all queued changes in one go.
    pub extern fn MH_ApplyQueued() callconv(std.os.windows.WINAPI) Status;
};

pub const InitError = error{
    Unknown,
    AlreadyInitialized,
};

pub fn init() InitError!void {
    return switch (bindings.MH_Initialize()) {
        .ok => {},
        .unknown => error.Unknown,
        .error_already_initialized => error.AlreadyInitialized,
        else => unreachable,
    };
}

pub const DeinitError = error{
    Unknown,
    NotInitialized,
};

pub fn deinit() DeinitError!void {
    return switch (bindings.MH_Uninitialize()) {
        .ok => {},
        .unknown => error.Unknown,
        .error_not_initialized => error.NotInitialized,
        else => unreachable,
    };
}

pub const HookState = enum { enabled, disabled };

pub fn Hook(comptime FuncType: type) type {
    return struct {
        target: FuncType,
        trampoline: FuncType,

        /// Do not invoke the target function after hooking
        /// Returns the trampoline, which should be called instead
        pub fn create(target: FuncType, detour: FuncType) @This() {
            var trampoline: FuncType = undefined;
            _ = bindings.MH_CreateHook(@ptrCast(@constCast(target)), @ptrCast(@constCast(detour)), @ptrCast(&trampoline));
            return .{
                .target = target,
                .trampoline = trampoline,
            };
        }

        pub fn enable(hook: *@This()) void {
            _ = bindings.MH_EnableHook(@ptrCast(@constCast(hook.target)));
        }

        pub fn disable(hook: *@This()) void {
            _ = bindings.MH_DisableHook(@ptrCast(@constCast(hook.target)));
        }
    };
}

test {
    try init();
    defer deinit() catch unreachable;

    const funcs = struct {
        var trampoline: *const fn (i32, i32) callconv(.C) i32 = undefined;

        fn add(a: i32, b: i32) callconv(.C) i32 {
            return a + b;
        }

        fn detouredAdd(a: i32, b: i32) callconv(.C) i32 {
            return trampoline(a, b) * 2;
        }
    };

    var hook = Hook(*const fn (i32, i32) callconv(.C) i32).create(&funcs.add, &funcs.detouredAdd);
    funcs.trampoline = hook.trampoline;
    hook.enable();

    try std.testing.expectEqual(@as(i32, 30), funcs.add(7, 8));
}
