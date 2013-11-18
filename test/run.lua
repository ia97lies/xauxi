-----------------------------------------------------------------------------
-- Test runner took from LuaNode Project which is under the MIT License
-----------------------------------------------------------------------------
--
-- The MIT License
-- 
-- Copyright (c) 2010 inConcert
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
-----------------------------------------------------------------------------

package.path = package.path..";/home/cli/workspace/xauxi/lib/?.lua;/home/cli/workspace/lualogging/src/?.lua;./?.lua"
require "lunit"

local console = require "lunit-console"

-- eventos posibles:
-- begin, done, fail, err, run, pass

local num_tests = select("#", ...)
if num_tests == 0 then
	print("No tests tu run...")
	return
end

if num_tests == 1 and select(1, ...) == "all" then
	print("TODO: Run all tests")
	return
end

for i=1, num_tests do
	local test_case = select(i, ...)
	test_case = test_case:gsub("%.lua$", "")
	require(test_case)
end

lunit.setrunner({
	begin = console.begin,
	--fail = function(...)
		--LogError("Error in test case %s\r\nat %s\r\n%s\r\n%s", ...)
	--end,
	fail = console.fail,
	err = console.err,
	--err = function(...)
--		LogError(...)
--	end,
	done = function(...)
		process:emit("exit")
		process:removeAllListeners("exit")
		console.done()
	end
})

-- patch process:loop
local old_loop = process.loop
process.loop = function()
	assert(old_loop(process))
end

--console.begin()
local stats = lunit.run()
if stats.failed > 0 or stats.errors > 0 then
	return 1
end
--console.done()
