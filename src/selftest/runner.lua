-- src/selftest/runner.lua
--
-- PURPOSE: Common test runner infrastructure.
--          Each test module calls Runner.run(name, fn) with its test function.
--
-- USAGE:
--   local Runner = require("src.selftest.runner")
--   Runner.run("test_name", function()
--       local checks = Runner.checks()
--       checks:eq("description", actual, expected)
--       ...
--       return checks:summary()
--   end)
--
-- OUTPUT:
--   Writes to selftest_<name>.txt in project root
--   Returns 0 (all pass) or 1 (any fail)
--   Prints summary to stdout

local Runner = {}
Runner._VERSION = "0.1"


-- ─── RESULT DIRECTORY ────────────────────────────────────────────────────────
-- Fixed path so PowerShell can find it without env vars.

local RESULT_DIR = "C:\\Users\\Admin\\Desktop\\AI and Programing\\Proyects\\LOVE2D\\PROYECTO DE JUEGO SMB"


-- ─── CHECKS BUILDER ──────────────────────────────────────────────────────────

local Checks = {}
Checks.__index = Checks

function Checks.new()
    return setmetatable({ items = {} }, Checks)
end

function Checks:check(name, ok, detail)
    local tag = ok and "[PASS]" or "[FAIL]"
    table.insert(self.items, { tag = tag, name = name, detail = detail or "" })
    return ok
end

function Checks:eq(name, actual, expected)
    local ok = actual == expected
    local detail = ("expected %s, got %s"):format(tostring(expected), tostring(actual))
    return self:check(name, ok, detail)
end

function Checks:neq(name, actual, expected)
    local ok = actual ~= expected
    local detail = ("expected not %s, got %s"):format(tostring(expected), tostring(actual))
    return self:check(name, ok, detail)
end

function Checks:truthy(name, value, detail)
    local ok = not not value
    return self:check(name, ok, detail or ("got " .. tostring(value)))
end

function Checks:falsy(name, value, detail)
    local ok = value == false or value == nil
    return self:check(name, ok, detail or ("got " .. tostring(value)))
end

function Checks:close(name, actual, expected, epsilon)
    epsilon = epsilon or 0.01
    local ok = math.abs(actual - expected) < epsilon
    local detail = ("expected %.4f ± %.4f, got %.4f"):format(expected, epsilon, actual)
    return self:check(name, ok, detail)
end

function Checks:summary()
    local passes = 0
    for _, item in ipairs(self.items) do
        if item.tag == "[PASS]" then passes = passes + 1 end
    end
    local total = #self.items
    local lines = {}
    table.insert(lines, ("[TEST] %s"):format(self._name or "unnamed"))
    for _, item in ipairs(self.items) do
        table.insert(lines, ("%s %-30s %s"):format(item.tag, item.name, item.detail))
    end
    table.insert(lines, ("[SUMMARY] %d/%d PASS"):format(passes, total))
    return { lines = lines, passes = passes, total = total, ok = (passes == total) }
end


-- ─── REPORTING ───────────────────────────────────────────────────────────────

local function writeReport(name, lines)
    local path = RESULT_DIR .. "\\selftest_" .. name .. ".txt"
    local f = io.open(path, "w")
    if f then
        for _, l in ipairs(lines) do f:write(l .. "\n") end
        f:close()
    end
    return path
end


-- ─── PUBLIC API ──────────────────────────────────────────────────────────────

-- Run a test by name. fn() must return the result of Checks:summary()
-- (or a table with { lines=..., ok=..., passes=..., total=... })
function Runner.run(name, fn)
    print("[RUNNER] Starting test: " .. name)

    local ok, result = pcall(fn)
    if not ok then
        local err = result
        local lines = {
            "[TEST] " .. name,
            "[FAIL] test crashed",
            tostring(err),
            "[SUMMARY] 0/0 PASS"
        }
        writeReport(name, lines)
        print(table.concat(lines, "\n"))
        return 1
    end

    -- Normalize result
    if type(result) ~= "table" or not result.lines then
        print("[RUNNER] Test " .. name .. " returned invalid result")
        return 1
    end

    writeReport(name, result.lines)
    print(table.concat(result.lines, "\n"))

    return result.ok and 0 or 1
end


-- Factory for checks
function Runner.checks(name)
    local c = Checks.new()
    c._name = name
    return c
end


return Runner