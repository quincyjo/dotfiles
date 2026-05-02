-- spec/frames_buffer_spec.lua
require("spec.support.awesome_mocks")

describe("frames.buffer", function()
	local buffer

	before_each(function()
		package.loaded["frames.buffer"] = nil
		buffer = require("frames.buffer")
	end)

	describe("initial state", function()
		it("starts at top with zero offset", function()
			local buf = buffer({ height = 200 })
			assert.is_true(buf.state.at_top)
			assert.equals(0, buf.state.offset)
		end)

		it("reports at_bottom when no content is set (max_offset = 0)", function()
			local buf = buffer({ height = 200 })
			assert.is_true(buf.state.at_bottom)
		end)

		it("uses provided height as initial viewport_height", function()
			local buf = buffer({ height = 300 })
			assert.equals(300, buf.viewport_height)
		end)
	end)

	describe("set_scroll", function()
		it("sets offset exactly when within bounds", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(100)
			assert.equals(100, buf.state.offset)
		end)

		it("clamps offset to 0 for negative values", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(-50)
			assert.equals(0, buf.state.offset)
		end)

		it("clamps offset to max_offset for over-scroll", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500 -- max_offset = 300
			buf:set_scroll(1000)
			assert.equals(300, buf.state.offset)
		end)

		it("computes max_offset as content_height - viewport_height", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(0)
			assert.equals(300, buf.state.max_offset)
		end)
	end)

	describe("pct", function()
		it("is 0 at top", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(0)
			assert.equals(0, buf.state.pct)
		end)

		it("is 100 at bottom", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(1000) -- clamped to 300
			assert.equals(100, buf.state.pct)
		end)

		it("is 50 at midpoint", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500 -- max_offset = 300
			buf:set_scroll(150)
			assert.equals(50, buf.state.pct)
		end)

		it("is 0 when content fits in viewport", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 100 -- fits; max_offset = 0
			buf:set_scroll(0)
			assert.equals(0, buf.state.pct)
		end)
	end)

	describe("at_top / at_bottom", function()
		it("at_top is true at offset 0", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(0)
			assert.is_true(buf.state.at_top)
		end)

		it("at_top is false when scrolled", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(1)
			assert.is_false(buf.state.at_top)
		end)

		it("at_bottom is true at max_offset", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(300)
			assert.is_true(buf.state.at_bottom)
		end)

		it("at_bottom is false before max_offset", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(299)
			assert.is_false(buf.state.at_bottom)
		end)
	end)

	describe("scroll_by", function()
		it("adds delta to current offset", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(100)
			buf:scroll_by(50)
			assert.equals(150, buf.state.offset)
		end)

		it("clamps result at max_offset", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(250)
			buf:scroll_by(200)
			assert.equals(300, buf.state.offset)
		end)

		it("negative delta scrolls up", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(100)
			buf:scroll_by(-30)
			assert.equals(70, buf.state.offset)
		end)
	end)

	describe("go_to_top / go_to_bottom", function()
		it("go_to_top sets offset to 0", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(200)
			buf:go_to_top()
			assert.equals(0, buf.state.offset)
		end)

		it("go_to_bottom sets offset to max_offset", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:go_to_bottom()
			assert.equals(300, buf.state.offset)
		end)
	end)

	describe("set_contents", function()
		it("resets offset to 0", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_scroll(200)
			buf:set_contents({})
			assert.equals(0, buf.state.offset)
		end)

		it("resets _content_height to nil to force re-measurement", function()
			local buf = buffer({ height = 200 })
			buf._private.content_height = 500
			buf:set_contents({})
			assert.is_nil(buf._private.content_height)
		end)
	end)

	describe("on_scroll callback", function()
		it("fires on set_scroll with new state", function()
			local received
			local buf = buffer({
				height = 200,
				on_scroll = function(s)
					received = s
				end,
			})
			buf._private.content_height = 500
			buf:set_scroll(100)
			assert.is_not_nil(received)
			assert.equals(100, received.offset)
		end)

		it("fires on go_to_top", function()
			local calls = 0
			local buf = buffer({
				height = 200,
				on_scroll = function()
					calls = calls + 1
				end,
			})
			buf._private.content_height = 500
			buf:set_scroll(100)
			buf:go_to_top()
			assert.equals(2, calls)
		end)
	end)
end)
