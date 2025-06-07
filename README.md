# Tupelo

A functional programming library for Lua that brings modern type safety and functional programming concepts to your Lua projects.

## Features

- **Type Checking**: Built-in type predicates and validation
- **Function Composition**: Compose and curry functions
- **Functional Collections**: Map, filter, and reduce operations
- **Option Type**: Handle nullable values safely
- **Result Type**: Elegant error handling
- **Custom Types**: Create your own type validators
- **Functors**: Stateful function management

## Installation

Simply require the module in your Lua project:

```lua
local F = require('tupelo')
```
# Quick Start

```lua
local F = require('tupelo')

-- Type checking
print(F.is_string("hello"))  -- true
print(F.is_number(42))       -- true

-- Function composition
local add_one = function(x) return x + 1 end
local double = function(x) return x * 2 end
local add_one_then_double = F.compose(double, add_one)
print(add_one_then_double(5))  -- 12

-- Working with collections
local numbers = {1, 2, 3, 4, 5}
local doubled = F.map(function(x) return x * 2 end)(numbers)
-- doubled = {2, 4, 6, 8, 10}

-- Safe value handling with Option
local safe_divide = function(a, b)
    if b == 0 then
        return F.Option.none()
    else
        return F.Option.some(a / b)
    end
end

local result = safe_divide(10, 2)
print(result:unwrap())  -- 5
```

# API Reference

## Type Checking

Basic type predicates for run-time type checking:

```lua
F.is_nil(nil)           -- true
F.is_number(42)         -- true
F.is_string("hello")    -- true
F.is_boolean(true)      -- true
F.is_function(print)    -- true
F.is_table({})          -- true
```

## Custom Types

Create your own type validators:

```lua
local PositiveNumber = F.type(
    function(x) return F.is_number(x) and x > 0 end,
    "PositiveNumber"
)

-- Validate values
F.validate(5, PositiveNumber)   -- OK, returns 5
F.validate(-1, PositiveNumber)  -- Error: Expected PositiveNumber, got number
```

## Function Composition

### Compose

Combine functions to create new ones:

```lua
local add_one = function(x) return x + 1 end
local square = function(x) return x * x end

local add_one_then_square = F.compose(square, add_one)
print(add_one_then_square(3))  -- 16 (3 + 1 = 4, 4² = 16)
```

### Curry

Transform functions to accept arguments one at a time:

```lua
local add = function(a, b) return a + b end
local curried_add = F.curry(add)

local add_five = curried_add(5)
print(add_five(3))  -- 8
print(curried_add(2)(3))  -- 5
```

## Collection Operations

### Map

Transform every element in a table:

```lua
local numbers = {1, 2, 3, 4}
local squared = F.map(function(x) return x * x end)(numbers)
-- squared = {1, 4, 9, 16}
```

### Filter

Keep only elements that match a predicate:

```lua
local numbers = {1, 2, 3, 4, 5, 6}
local evens = F.filter(function(x) return x % 2 == 0 end)(numbers)
-- evens = {2, 4, 6}
```

### Reduce

Combine elements into a single value:

```lua
local numbers = {1, 2, 3, 4}
local sum = F.reduce(function(acc, x) return acc + x end, 0)(numbers)
-- sum = 10
```

## Option Type

Handle missing or nullable values safely:

```lua
-- Creating Options
local some_value = F.Option.some(42)
local no_value = F.Option.none()

-- Checking Option state
print(some_value:is_some())  -- true
print(no_value:is_none())    -- true

-- Extracting values
print(some_value:unwrap())        -- 42
print(no_value:unwrap_or(0))      -- 0 (default value)

-- Chaining operations
local result = F.Option.some(10)
    :map(function(x) return x * 2 end)
    :map(function(x) return x + 1 end)
print(result:unwrap())  -- 21

-- Safe chaining
local safe_result = F.Option.some("hello")
    :and_then(function(s)
        if #s > 3 then
            return F.Option.some(string.upper(s))
        else
            return F.Option.none()
        end
    end)
print(safe_result:unwrap())  -- "HELLO"
```

## Result Type

Handle operations that can succeed fail:

```lua
-- Creating Results
local success = F.Result.ok(42)
local failure = F.Result.err("Something went wrong")

-- Checking Result state
print(success:is_ok())   -- true
print(failure:is_err())  -- true

-- Extracting values
print(success:unwrap())     -- 42
print(failure:unwrap_err()) -- "Something went wrong"

-- Chaining operations
local result = F.Result.ok(10)
    :map(function(x) return x * 2 end)
    :map(function(x) return x + 1 end)
print(result:unwrap())  -- 21

-- Error handling
local safe_divide = function(a, b)
    if b == 0 then
        return F.Result.err("Division by zero")
    else
        return F.Result.ok(a / b)
    end
end

local result = safe_divide(10, 2)
    :and_then(function(x) return F.Result.ok(x * 2) end)
print(result:unwrap())  -- 10
```

## Functors

Create stateful functions:

```lua
local counter, state = F.make_functor(function(state, increment)
    state.count = (state.count or 0) + (increment or 1)
    return state.count
end, {count = 0})

print(counter(1))  -- 1
print(counter(5))  -- 6
print(counter())   -- 7
```

## Pre-defined Type validators

Tupelo includes several pre-defined type validators:
```lua
F.IsNil      -- validates nil values
F.IsNumber   -- validates numbers
F.IsString   -- validates strings
F.IsBoolean  -- validates booleans
F.IsFunction -- validates functions
F.IsTable    -- validates tables
F.IsOption   -- validates Option types
F.IsResult   -- validates Result types
F.IsFunctor  -- validates functors
```
# Examples

## Error-Safe JSON Parsing

```lua
local parse_json = function(json_string)
    local success, result = pcall(json.decode, json_string)
    if success then
        return F.Result.ok(result)
    else
        return F.Result.err("Invalid JSON: " .. result)
    end
end

local process_user = function(json_str)
    return parse_json(json_str)
        :and_then(function(data)
            if data.name and data.age then
                return F.Result.ok({
                    name = data.name,
                    age = data.age,
                    is_adult = data.age >= 18
                })
            else
                return F.Result.err("Missing required fields")
            end
        end)
end
```

## Safe list operations

```lua
local safe_head = function(list)
    if #list > 0 then
        return F.Option.some(list[1])
    else
        return F.Option.none()
    end
end

local safe_tail = function(list)
    if #list > 1 then
        local tail = {}
        for i = 2, #list do
            table.insert(tail, list[i])
        end
        return F.Option.some(tail)
    else
        return F.Option.none()
    end
end

local numbers = {1, 2, 3, 4, 5}
local first = safe_head(numbers):unwrap_or(0)  -- 1
local rest = safe_tail(numbers):unwrap_or({})  -- {2, 3, 4, 5}
```

# Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.
