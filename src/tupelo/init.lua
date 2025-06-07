local F = {}

--- Checks if the value is nil
---@param x any
---@return boolean
F.is_nil = function(x) return x == nil end

--- Checks if the value is a number, string, boolean, function, or table
---@param x any
---@return boolean
F.is_number = function(x) return type(x) == "number" end

--- Checks if the value is a string
---@param x any
---@return boolean
F.is_string = function(x) return type(x) == "string" end

--- Checks if the value is a boolean
---@param x any
---@return boolean
F.is_boolean = function(x) return type(x) == "boolean" end

--- Checks if the value is a function
---@param x any
---@return boolean
F.is_function = function(x) return type(x) == "function" end

--- Checks if the value is a table
---@param x any
---@return boolean
F.is_table = function(x) return type(x) == "table" end
-- F.is_userdata = function(x) return type(x) == "userdata" end
-- F.is_thread = function(x) return type(x) == "thread" end

---Type constructor and validator
---@param validator function
---@param name string|nil
---@return table
F.type = function(validator, name)
    return {
        check = validator,
        name = name or "unnamed_type"
    }
end

--- Validates the value against the type definition
---@param value any
---@param type_def table
F.validate = function(value, type_def)
    if not type_def.check(value) then
        error("Expected " .. type_def.name .. ", got " .. type(value))
    end
    return value
end

--- Composes two functions
---@param f function
---@param g function
---@return function
F.compose = function(f, g)
    return function(...)
        return f(g(...))
    end
end

--- Creates a curried version of a function
---@param fn function
---@return any
F.curry = function(fn)
    local arity = debug.getinfo(fn).nparams
    local function curry_impl(args)
        return function(...)
            local new_args = {}
            for i, v in ipairs(args) do
                new_args[i] = v
            end
            local arg_len = #args
            for i, v in ipairs({ ... }) do
                new_args[arg_len + i] = v
            end

            if #new_args >= arity then
                return fn(table.unpack(new_args, 1, arity))
            else
                return curry_impl(new_args)
            end
        end
    end
    return curry_impl({})
end

--- Maps a function over a table
---@param fn function
---@return function
F.map = function(fn)
    ---@type function
    ---@param tbl table
    ---@return table
    return function(tbl)
        local result = {}
        for i, v in ipairs(tbl) do
            result[i] = fn(v)
        end
        return result
    end
end

--- Filters a table based on a predicate function
---@param predicate function
---@return function
F.filter = function(predicate)
    ---@type function
    ---@param tbl table
    ---@return table
    return function(tbl)
        local result = {}
        for _, v in ipairs(tbl) do
            if predicate(v) then
                table.insert(result, v)
            end
        end
        return result
    end
end

--- Reduces a table to a single value using a reducer function
---@param fn function
---@param initial any
---@return function
F.reduce = function(fn, initial)
    ---@type function
    ---@param tbl table
    ---@return any
    return function(tbl)
        local result = initial
        for _, v in ipairs(tbl) do
            result = fn(result, v)
        end
        return result
    end
end

--- Creates a functor that can be used to maintain state
---@param fn function
---@param initial_state table|nil
---@return function, table
function F.make_functor(fn, initial_state)
    local state = initial_state or {}
    --- This function returns a new function that captures the state
    ---@type function
    ---@param ... any
    ---@return function
    return function(...)
        return fn(state, ...)
    end, state -- Return the function and the state
end

--- Represents an optional value that can be either Some or None
---@class Option
---@field is_some boolean
---@field is_none boolean
---@field value any
local Option = F.type(
    function(x)
        return x == nil or (type(x) == "table" and x.is_some or x.is_none)
    end,
    "Option"
)
Option.__index = Option
--- Creates a new Option with a value
---@param value any
---@return Option
Option.some = function(value)
    return setmetatable({ value = value, is_some = true, is_none = false }, Option)
end
--- Creates a new Option with no value
---@return Option
Option.none = function()
    return setmetatable({ is_none = true, is_some = false, value = nil }, Option)
end

---@type boolean|function
--- Checks if the Option is Some or None
---@return boolean
Option.is_some = function(self)
    return self.is_some == true
end
---@type boolean|function
--- Checks if the Option is None
---@return boolean
Option.is_none = function(self)
    return self.is_none == true
end
--- Unwraps the value from the Option, raises an error if None
---@return any
---@raise error if None
Option.unwrap = function(self)
    if self.is_some then
        return self.value
    else
        error("Attempted to unwrap a None Option")
    end
end
--- Unwraps the value from the Option, returns a default value if None
---@param default any
---@return any
Option.unwrap_or = function(self, default)
    if self.is_some then
        return self.value
    else
        return default
    end
end

--- Maps a function over the Option value, returning a new Option
---@param fn function
---@return Option
Option.map = function(self, fn)
    if self.is_some then
        return Option.some(fn(self.value))
    else
        return self -- Propagate the None
    end
end

--- Maps a function over the Option value, returning a default value if None
---@param fn function
---@param default any
---@return any
Option.map_or = function(self, fn, default)
    if self.is_some then
        return fn(self.value)
    else
        return default
    end
end

--- Chains operations on the Option, expecting the function to return another Option
---@param fn function
---@return Option
Option.and_then = function(self, fn)
    if self.is_some then
        return fn(self.value) -- Expecting fn to return an Option
    else
        return self           -- Propagate the None
    end
end

--- Chains operations on the Option, expecting the function to return another Option
---@param fn function
---@return Option
Option.or_else = function(self, fn)
    if self.is_none then
        return fn() -- Expecting fn to return an Option
    else
        return self -- Propagate the Some
    end
end

--- Converts the Option to a string representation
---@return string
Option.__tostring = function(self)
    if self.is_some then
        return "Some(" .. tostring(self.value) .. ")"
    elseif self.is_none then
        return "None"
    else
        return "Option(None)"
    end
end

--- Checks if two Options are equal
---@param a Option
---@param b Option
---@return boolean
Option.__eq = function(a, b)
    if a.is_some and b.is_some then
        return a.value == b.value
    elseif a.is_none and b.is_none then
        return true
    else
        return false
    end
end
F.Option = Option

--- Represents a Result type that can be either Ok or Err
---@class Result
---@field is_ok boolean|function
---@field is_err boolean|function
---@field value any
local Result = F.type(
    function(x)
        return x == nil or (type(x) == "table" and x.is_ok or x.is_err)
    end,
    "Result"
)
Result.__index = Result

--- Creates a new Result with an Ok value
---@param value any
---@return Result
Result.ok = function(value)
    return setmetatable({ value = value, is_ok = true }, Result)
end

--- Creates a new Result with an Err value
---@param value any
---@return Result
Result.err = function(value)
    return setmetatable({ value = value, is_err = true }, Result)
end

---@type boolean|function
--- Checks if the Result is Ok
---@return boolean
Result.is_ok = function(self)
    return self.is_ok == true
end

---@type boolean|function
--- Checks if the Result is Err
---@return boolean
Result.is_err = function(self)
    return self.is_err == true
end

--- Checks if the Result is None (neither Ok nor Err)
---@param self Result
---@return any
---@raise error if neither Ok nor Err
Result.unwrap = function(self)
    if self.is_ok then
        return self.value
    else
        error("Attempted to unwrap an error Result")
    end
end

--- Unwraps the value from the Result, raises an error if Err
---@param self Result
---@return any
---@raise error if Err
Result.unwrap_err = function(self)
    if self.is_err then
        return self.value
    else
        error("Attempted to unwrap an ok Result")
    end
end

--- Unwraps the value from the Result, returns a default value if Err
---@param self Result
---@param fn function
---@return Result
Result.map = function(self, fn)
    if self.is_ok then
        return Result.ok(fn(self.value))
    else
        return self -- Propagate the error
    end
end

--- Unwraps the value from the Result, returns a default value if Err
---@param self Result
---@param fn function
---@return Result
Result.map_err = function(self, fn)
    if self.is_err then
        return Result.err(fn(self.value))
    else
        return self -- Propagate the ok value
    end
end

--- Maps a function over the Result value, returning a new Result
---@param self Result
---@param fn function
---@return Result|any
Result.and_then = function(self, fn)
    if self.is_ok then
        return fn(self.value) -- Expecting fn to return a Result
    else
        return self           -- Propagate the error
    end
end

--- Maps a function over the Result value, returning a default value if Err
---@param self Result
---@param fn function
---@return Result|any
Result.or_else = function(self, fn)
    if self.is_err then
        return fn(self.value) -- Expecting fn to return a Result
    else
        return self           -- Propagate the ok value
    end
end

--- Converts the Result to a string representation
---@param self Result
---@return string
Result.__tostring = function(self)
    if self.is_ok then
        return "Ok(" .. tostring(self.value) .. ")"
    elseif self.is_err then
        return "Err(" .. tostring(self.value) .. ")"
    else
        return "Result(None)"
    end
end

--- Checks if two Results are equal
---@param a Result
---@param b Result
---@return boolean
Result.__eq = function(a, b)
    if a.is_ok and b.is_ok then
        return a.value == b.value
    elseif a.is_err and b.is_err then
        return a.value == b.value
    else
        return false
    end
end

F.Result = Result


F.IsNil = F.type(F.is_nil, "nil")
F.IsNumber = F.type(F.is_number, "number")
F.IsString = F.type(F.is_string, "string")
F.IsBoolean = F.type(F.is_boolean, "boolean")
F.IsFunction = F.type(F.is_function, "function")
F.IsTable = F.type(F.is_table, "table")
F.IsOption = F.type(function(x) return x.is_some or x.is_none end, "Option")
F.IsResult = F.type(function(x) return x.is_ok or x.is_err end, "Result")
F.IsFunctor = F.type(function(x) return type(x) == "function" end, "Functor")



-- Test cases to demonstrate usage

local opt = Option.some(5)
print(opt.is_some)         -- Output: true
print(Option.is_some(opt)) -- Output: true

---@type function
local compose_result = F.compose(F.is_string, F.is_number)
---@type boolean
local cr_result = compose_result(123) -- Example usage, should print false since 123 is a number, not a string
print(cr_result)                      -- Output: false

local curried_add = F.curry(function(a, b) return a + b end)
print(curried_add(2)(3)) -- Output: 5


local mapped = F.map(function(x) return x * 2 end)({ 1, 2, 3 })
print(mapped[1], mapped[2], mapped[3]) -- Output: 2 4 6

local filtered = F.filter(function(x) return x > 1 end)({ 1, 2, 3, 4 })
print(filtered[1], filtered[2]) -- Output: 2 3

local reduced = F.reduce(function(acc, x) return acc + x end, 0)({ 1, 2, 3 })
print(reduced) -- Output: 6


local option = Option.some(42)
print(option:unwrap())          -- Output: 42
local none_option = Option.none()
print(none_option:unwrap_or(0)) -- Output: 0
