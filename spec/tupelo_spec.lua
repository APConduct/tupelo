-- Test specification for Tupelo
describe("Tupelo", function()
    local F = require("tupelo")

    describe("Type checking", function()
        it("should identify nil values", function()
            assert.is_true(F.is_nil(nil))
            assert.is_false(F.is_nil(0))
            assert.is_false(F.is_nil(""))
        end)

        it("should identify numbers", function()
            assert.is_true(F.is_number(42))
            assert.is_true(F.is_number(3.14))
            assert.is_false(F.is_number("42"))
        end)

        it("should identify strings", function()
            assert.is_true(F.is_string("hello"))
            assert.is_true(F.is_string(""))
            assert.is_false(F.is_string(42))
        end)

        it("should identify booleans", function()
            assert.is_true(F.is_boolean(true))
            assert.is_true(F.is_boolean(false))
            assert.is_false(F.is_boolean(1))
        end)

        it("should identify functions", function()
            assert.is_true(F.is_function(function() end))
            assert.is_true(F.is_function(print))
            assert.is_false(F.is_function("function"))
        end)

        it("should identify tables", function()
            assert.is_true(F.is_table({}))
            assert.is_true(F.is_table({ 1, 2, 3 }))
            assert.is_false(F.is_table("table"))
        end)
    end)

    describe("Custom types", function()
        it("should create and validate custom types", function()
            local PositiveNumber = F.type(
                function(x) return F.is_number(x) and x > 0 end,
                "PositiveNumber"
            )

            local result = F.validate(5, PositiveNumber)
            assert.equals(5, result)

            assert.has_error(function()
                F.validate(-1, PositiveNumber)
            end)
        end)
    end)

    describe("Function composition", function()
        it("should compose functions correctly", function()
            local add_one = function(x) return x + 1 end
            local double = function(x) return x * 2 end
            local composed = F.compose(double, add_one)

            assert.equals(8, composed(3)) -- (3 + 1) * 2 = 8
        end)

        it("should curry functions", function()
            local add = function(a, b) return a + b end
            local curried_add = F.curry(add)

            assert.equals(5, curried_add(2)(3))

            local add_five = curried_add(5)
            assert.equals(8, add_five(3))
        end)
    end)

    describe("Collection operations", function()
        it("should map over tables", function()
            local double = function(x) return x * 2 end
            local mapped = F.map(double)({ 1, 2, 3 })

            assert.same({ 2, 4, 6 }, mapped)
        end)

        it("should filter tables", function()
            local is_even = function(x) return x % 2 == 0 end
            local filtered = F.filter(is_even)({ 1, 2, 3, 4, 5, 6 })

            assert.same({ 2, 4, 6 }, filtered)
        end)

        it("should reduce tables", function()
            local sum = function(acc, x) return acc + x end
            local result = F.reduce(sum, 0)({ 1, 2, 3, 4 })

            assert.equals(10, result)
        end)
    end)

    describe("Option type", function()
        it("should create Some and None options", function()
            local some = F.Option.some(42)
            local none = F.Option.none()

            assert.is_true(some:is_some())
            assert.is_false(some:is_none())
            assert.is_false(none:is_some())
            assert.is_true(none:is_none())
        end)

        it("should unwrap values correctly", function()
            local some = F.Option.some(42)
            local none = F.Option.none()

            assert.equals(42, some:unwrap())
            assert.equals(0, none:unwrap_or(0))

            assert.has_error(function()
                none:unwrap()
            end)
        end)

        it("should map over Option values", function()
            local some = F.Option.some(5)
            local none = F.Option.none()

            local double = function(x) return x * 2 end

            assert.equals(10, some:map(double):unwrap())
            assert.is_true(none:map(double):is_none())
        end)
    end)

    describe("Result type", function()
        it("should create Ok and Err results", function()
            local ok = F.Result.ok(42)
            local err = F.Result.err("error")

            assert.is_true(ok:is_ok())
            assert.is_false(ok:is_err())
            assert.is_false(err:is_ok())
            assert.is_true(err:is_err())
        end)

        it("should unwrap values correctly", function()
            local ok = F.Result.ok(42)
            local err = F.Result.err("error")

            assert.equals(42, ok:unwrap())
            assert.equals("error", err:unwrap_err())

            assert.has_error(function()
                err:unwrap()
            end)
        end)
    end)
end)
