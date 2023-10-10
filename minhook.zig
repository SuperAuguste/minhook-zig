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
        target: *const anyopaque,
        detour: *const anyopaque,
        original: ?**const anyopaque,
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
        detour: *const anyopaque,
        original: ?**const anyopaque,
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
        detour: *const anyopaque,
        original: ?**const anyopaque,
        target: ?**const anyopaque,
    ) callconv(std.os.windows.WINAPI) Status;

    /// Removes an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    pub extern fn MH_RemoveHook(target: *const anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Enables an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                enabled in one go.
    pub extern fn MH_EnableHook(target: ?*const anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Disables an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                disabled in one go.
    pub extern fn MH_DisableHook(target: ?*const anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Queues to enable an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                queued to be enabled.
    pub extern fn MH_QueueEnableHook(target: ?*const anyopaque) callconv(std.os.windows.WINAPI) Status;

    /// Queues to disable an already created hook.
    /// Parameters:
    ///   pTarget [in] A pointer to the target function.
    ///                If this parameter is MH_ALL_HOOKS, all created hooks are
    ///                queued to be disabled.
    pub extern fn MH_QueueDisableHook(target: ?*const anyopaque) callconv(std.os.windows.WINAPI) Status;

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

pub const CreateError = error{
    Unknown,
    NotInitialized,
    AlreadyCreated,
    NotExecutable,
    UnsupportedFunction,
    OutOfMemory,
    MemoryProtect,
};

pub const FindAndCreateError = CreateError || error{ ModuleNotFound, FunctionNotFound };

pub const DestroyError = error{
    Unknown,
    NotInitialized,
    NotCreated,
};

pub const EnableError = error{
    Unknown,
    NotInitialized,
    NotCreated,
    AlreadyEnabled,
};

pub const QueueEnableDisableError = error{
    Unknown,
    NotInitialized,
    NotCreated,
};

pub const DisableError = error{
    Unknown,
    NotInitialized,
    NotCreated,
    AlreadyDisabled,
};

pub fn Hook(comptime FuncType: type) type {
    return struct {
        target: FuncType,
        trampoline: FuncType,

        /// Do not invoke the target function after hooking
        /// Returns the trampoline, which should be called instead
        pub fn create(target: FuncType, detour: FuncType) CreateError!@This() {
            var trampoline: FuncType = undefined;
            switch (bindings.MH_CreateHook(@ptrCast(target), @ptrCast(@constCast(detour)), @ptrCast(&trampoline))) {
                .ok => {},
                .unknown => return error.Unknown,
                .error_not_initialized => return error.NotInitialized,
                .error_already_created => return error.AlreadyCreated,
                .error_not_executable => return error.NotExecutable,
                .error_unsupported_function => return error.UnsupportedFunction,
                .error_memory_alloc => return error.OutOfMemory,
                .error_memory_protect => return error.MemoryProtect,
                else => unreachable,
            }

            return .{
                .target = target,
                .trampoline = trampoline,
            };
        }

        pub fn findAndCreateHook(module_name: [:0]const u16, function_name: [:0]const u8, detour: FuncType) FindAndCreateError!@This() {
            var target: FuncType = undefined;
            var trampoline: FuncType = undefined;

            switch (bindings.MH_CreateHookApiEx(module_name, function_name, @ptrCast(detour), @ptrCast(&trampoline), @ptrCast(&target))) {
                .ok => {},
                .unknown => return error.Unknown,
                .error_not_initialized => return error.NotInitialized,
                .error_already_created => return error.AlreadyCreated,
                .error_not_executable => return error.NotExecutable,
                .error_unsupported_function => return error.UnsupportedFunction,
                .error_memory_alloc => return error.OutOfMemory,
                .error_memory_protect => return error.MemoryProtect,
                .error_module_not_found => return error.ModuleNotFound,
                .error_function_not_found => return error.FunctionNotFound,
                else => unreachable,
            }

            return .{
                .target = target,
                .trampoline = trampoline,
            };
        }

        pub fn destroy(hook: *@This()) DestroyError!void {
            return switch (bindings.MH_RemoveHook(@ptrCast(hook.target))) {
                .ok => {},
                .unknown => error.Unknown,
                .error_not_initialized => error.NotInitialized,
                .error_not_created => error.NotCreated,
                else => unreachable,
            };
        }

        pub fn enable(hook: *@This()) EnableError!void {
            return switch (bindings.MH_EnableHook(@ptrCast(hook.target))) {
                .ok => {},
                .unknown => error.Unknown,
                .error_not_initialized => error.NotInitialized,
                .error_not_created => error.NotCreated,
                .error_enabled => error.AlreadyEnabled,
                else => unreachable,
            };
        }

        pub fn queueEnable(hook: *@This()) QueueEnableDisableError!void {
            return switch (bindings.MH_QueueEnableHook(@ptrCast(hook.target))) {
                .ok => {},
                .unknown => error.Unknown,
                .error_not_initialized => error.NotInitialized,
                .error_not_created => error.NotCreated,
                else => unreachable,
            };
        }

        pub fn disable(hook: *@This()) DisableError!void {
            return switch (bindings.MH_DisableHook(@ptrCast(hook.target))) {
                .ok => {},
                .unknown => error.Unknown,
                .error_not_initialized => error.NotInitialized,
                .error_not_created => error.NotCreated,
                .error_disabled => error.AlreadyDisabled,
                else => unreachable,
            };
        }

        pub fn queueDisable(hook: *@This()) QueueEnableDisableError!void {
            return switch (bindings.MH_QueueDisableHook(@ptrCast(hook.target))) {
                .ok => {},
                .unknown => error.Unknown,
                .error_not_initialized => error.NotInitialized,
                .error_not_created => error.NotCreated,
                else => unreachable,
            };
        }
    };
}

pub fn createHook(target: anytype, detour: @TypeOf(target)) CreateError!Hook(@TypeOf(target)) {
    return Hook(@TypeOf(target)).create(target, detour);
}

pub fn findAndCreateHook(module_name: [:0]const u16, function_name: [:0]const u8, detour: anytype) FindAndCreateError!Hook(@TypeOf(detour)) {
    return Hook(@TypeOf(detour)).findAndCreateHook(module_name, function_name, detour);
}

pub fn enableAll() QueueEnableDisableError!void {
    return switch (bindings.MH_EnableHook(null)) {
        .ok => {},
        .unknown => error.Unknown,
        .error_not_initialized => error.NotInitialized,
        .error_enabled => error.AlreadyEnabled,
        else => unreachable,
    };
}

pub fn disableAll() QueueEnableDisableError!void {
    return switch (bindings.MH_DisableHook(null)) {
        .ok => {},
        .unknown => error.Unknown,
        .error_not_initialized => error.NotInitialized,
        .error_disabled => error.AlreadyDisabled,
        else => unreachable,
    };
}

pub fn queueEnableAll() QueueEnableDisableError!void {
    return switch (bindings.MH_QueueEnableHook(null)) {
        .ok => {},
        .unknown => error.Unknown,
        .error_not_initialized => error.NotInitialized,
        .error_not_created => error.NotCreated,
        else => unreachable,
    };
}

pub fn queueDisableAll() QueueEnableDisableError!void {
    return switch (bindings.MH_QueueDisableHook(null)) {
        .ok => {},
        .unknown => error.Unknown,
        .error_not_initialized => error.NotInitialized,
        .error_not_created => error.NotCreated,
        else => unreachable,
    };
}

pub const ApplyQueuedError = error{
    Unknown,
    NotInitialized,
};

pub fn applyQueued() ApplyQueuedError!void {
    return switch (bindings.MH_ApplyQueued()) {
        .ok => {},
        .unknown => error.Unknown,
        .error_not_initialized => error.NotInitialized,
        else => unreachable,
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

        extern fn MessageBoxExA(
            hWnd: ?std.os.windows.HWND,
            lpText: std.os.windows.LPCSTR,
            lpCaption: std.os.windows.LPCSTR,
            uType: std.os.windows.UINT,
            wLanguageId: std.os.windows.WORD,
        ) callconv(.C) c_int;

        fn FakeMessageBoxExA(
            hWnd: ?std.os.windows.HWND,
            lpText: std.os.windows.LPCSTR,
            lpCaption: std.os.windows.LPCSTR,
            uType: std.os.windows.UINT,
            wLanguageId: std.os.windows.WORD,
        ) callconv(.C) c_int {
            _ = wLanguageId;
            _ = uType;
            _ = lpCaption;
            _ = lpText;
            _ = hWnd;
            return 420;
        }
    };

    var hook = try createHook(&funcs.add, &funcs.detouredAdd);
    defer hook.destroy() catch unreachable;

    funcs.trampoline = hook.trampoline;

    try std.testing.expectEqual(@as(i32, 15), funcs.add(7, 8));
    try hook.enable();
    try std.testing.expectError(error.AlreadyEnabled, hook.enable());

    try std.testing.expectEqual(@as(i32, 30), funcs.add(7, 8));
    try hook.disable();
    try std.testing.expectEqual(@as(i32, 15), funcs.add(7, 8));

    var hook2 = try findAndCreateHook(std.unicode.utf8ToUtf16LeStringLiteral("user32"), "MessageBoxExA", &funcs.FakeMessageBoxExA);
    defer hook2.destroy() catch unreachable;

    try hook2.enable();

    try std.testing.expectEqual(@as(c_int, 420), funcs.MessageBoxExA(null, "hi", "hello", 0, 0));
}

test "queued" {
    const funcs = struct {
        var trampoline: *const fn (i32, i32) callconv(.C) i32 = undefined;

        fn add(a: i32, b: i32) callconv(.C) i32 {
            return a + b;
        }

        fn detouredAdd(a: i32, b: i32) callconv(.C) i32 {
            return trampoline(a, b) * 2;
        }
    };

    try init();
    var hook = try createHook(&funcs.add, &funcs.detouredAdd);
    funcs.trampoline = hook.trampoline;

    try hook.queueEnable();

    try applyQueued();

    try std.testing.expectEqual(@as(i32, 30), funcs.add(7, 8));

    try queueDisableAll();
    try applyQueued();

    try std.testing.expectEqual(@as(i32, 15), funcs.add(7, 8));
}
