local _LICENSE = -- zlib / libpng
[[
Copyright (c) 2011-2016 Bart van Strien

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
  claim that you wrote the original software. If you use this software
  in a product, an acknowledgment in the product documentation would be
  appreciated but is not required.

  2. Altered source versions must be plainly marked as such, and must not be
  misrepresented as being the original software.

  3. This notice may not be removed or altered from any source
  distribution.
]]

class =
{
	_VERSION = "Slither 20170421",
	-- I have no better versioning scheme, deal with it
	_DESCRIPTION = "Slither is a pythonic class library for lua",
	_URL = "http://bitbucket.org/bartbes/slither",
	_LICENSE = _LICENSE,
}

local function mro_get(mro, key, starti)
	for i = starti or 1, #mro do
		if mro[i][key] ~= nil then
			return mro[i][key]
		end
	end
end

local function mro_find(mro, entry)
	local prototype = rawget(entry, "__prototype__")
	for i = 1, #mro do
		if mro[i] == entry or mro[i] == prototype then
			return i
		end
	end
end

-- Derives an MRO from a list of (direct) parents
local function buildmro(parents)
	local mro = {}
	local inmro = {}
	for i, v in ipairs(parents) do
		for j, w in ipairs(v.__mro__) do
			-- If it's already in the mro, we move it backwards by removing
			-- it and then reinserting
			if inmro[w] then
				local oldpos = inmro[w]
				table.remove(mro, oldpos)
				for i, v in pairs(inmro) do
					if v > oldpos then
						inmro[i] = inmro[i]-1
					end
				end
			end

			table.insert(mro, w)
			inmro[w] = #mro
		end
	end

	mro.get = mro_get
	mro.find = mro_find

	return mro
end

-- defined later as classes
local AnnotationWrapper, ClassAnnotationWrapper

-- This is where the actual class generation happens
local function class_generator(name, parentlist, prototype)
	-- Store a reference to the library table here
	local classlib = class

	-- Add our root object, for classes that derive from nothing
	-- NOTE: This means that *all* classes will derive from Object,
	-- unless it was explicitly removed at some point
	if #parentlist == 0 then
		parentlist[1] = class.Object
	end

	-- Compose a list of parents
	local parents = {}
	for _, v in ipairs(parentlist) do
		parents[v] = true
		for i, _ in pairs(v.__parents__) do
			parents[i] = true
		end
	end

	-- Create our 'class' table, which ends up being the class object
	local class = { __parents__ = parents, __subclasses__ = {} }

	-- __subclasses__ is a weak table
	setmetatable(class.__subclasses__, {__mode = "k"})

	-- Now we'll add it to the subclass list of all parents
	for parent, _ in pairs(parents) do
		parent.__subclasses__[class] = true
	end

	-- Add class access to the original prototype
	class.__prototype__ = prototype
	class.__prototype__.__name__ = name

	-- Build the MRO (Member Resolution Order)
	class.__mro__ = buildmro(parentlist)
	table.insert(class.__mro__, 1, class.__prototype__)

	local instance_mt

	-- Create our class by attaching a metatable to our object
	setmetatable(class, {
		-- We first catch __class__ and __name__, then check the MRO, in order.
		-- If we still don't have a match, make sure we're not matching a
		-- special method, then call __getattr__ if defined.
		__index = function(self, key)
			if key == "__class__" then return class end
			if key == "__name__" then return name end
			local v = class.__mro__:get(key)
			if v ~= nil then return v end
			if tostring(key):match("^__.+__$") then return end
			if self.__getattr__ then
				return self:__getattr__(key)
			end
		end,

		-- Attaching things to our class later on can simply be modeled
		-- as assigning to the prototype.
		__newindex = prototype,

		-- Storage for annotations
		__annotations__ = {},

		-- Here we 'allocate' an object
		allocate = function(instance)
			-- Join our (possibly given) instance with the metatable
			return setmetatable(instance or {}, instance_mt)
		end,

		-- Our 'new' call, first allocate an object of this class, then call
		-- the constructor.
		__call = function(self, ...)
			local instance = self:__new__()
			if instance.__init__ then instance:__init__(...) end
			return instance
		end
	})

	-- Create our object's metatable
	do
		local smt = getmetatable(class)
		local mt = {__index = smt.__index}
		instance_mt = mt

		-- Assigning to the object either calls __setattr__ or sets it on
		-- the object directly.
		function mt:__newindex(key, value)
			if self.__setattr__ then
				return self:__setattr__(key, value)
			else
				return rawset(self, key, value)
			end
		end

		-- If __cmp__ is defined, we want to emit both the eq and lt
		-- operations.
		if class.__cmp__ then
			function mt.__eq(a, b)
				return a.__cmp__(a, b) == 0
			end
			function mt.__lt(a, b)
				return a.__cmp__(a, b) < 0
			end
		end

		-- Now map the rest of our special functions to metamethods
		for i, v in pairs{
				__call__ = "__call", __len__ = "__len",
				__add__ = "__add", __sub__ = "__sub",
				__mul__ = "__mul", __div__ = "__div",
				__mod__ = "__mod", __pow__ = "__pow",
				__neg__ = "__unm", __concat__ = "__concat",
				__str__ = "__tostring",
				} do
			if class[i] then mt[v] = class[i] end
		end
	end

	-- Do our pre-application of class Annotations
	-- This is in "reverse reverse" order, so the top-most annotation gets
	-- to pre-apply first, then post-apply last. This makes it the "most
	-- powerful", which matches the behaviour for members.
	for i = 1, #prototype, 1 do
		if classlib.isinstance(prototype[i], ClassAnnotationWrapper) then
			prototype[i]:resolvePre(name, prototype)
		end
	end

	-- Inherit annotations for any member we don't overwrite
	local ourAnns = getmetatable(class).__annotations__
	for i, v in ipairs(parentlist) do
		local anns = getmetatable(v).__annotations__

		-- For every annotation on our (direct) parents...
		for ann, storage in pairs(anns) do
			local newstorage = {}

			-- ... for every annotated member ...
			for member, value in pairs(storage) do
				-- ... if we don't override it, copy the annotation
				if prototype[member] == nil then
					newstorage[member] = value
				end
			end

			-- If we've stored anything at all, assign it to our annotation
			-- storage
			if next(newstorage) then
				ourAnns[ann] = newstorage
			end
		end
	end

	-- If annotations are used, we are left with a bunch of AnnotationWrapper
	-- objects, here we resolve them and replace them with the resulting value.
	for i, v in pairs(prototype) do
		if classlib.isinstance(v, AnnotationWrapper) then
			prototype[i] = v:resolve(i, class)
		end
	end

	-- Now we deal with class attributes
	for i, v in ipairs(prototype.__attributes__ or {}) do
		class = v(class) or class
	end

	-- And our post-application of class Annotations
	-- In "reverse" order, as explained in the pre-application.
	for i = #prototype, 1, -1 do
		if classlib.isinstance(prototype[i], ClassAnnotationWrapper) then
			prototype[i]:resolvePost(name, class)

			-- Now remove this ClassAnnotationWrapper
			prototype[i] = nil
		end
	end

	return class
end

-- Here we determine if we've been passed a list of parents, and if so, convert
-- them from strings if necessary. Then we produce a new function that results
-- in the final call to class_generator. If we've not been passed parents, call
-- class_generator now, we already have our prototype.
local function inheritance_handler(name, ...)
	local args = {...}

	for i = 1, select("#", ...) do
		if args[i] == nil then
			error("nil passed to class, check if the parents are in scope and spelled correctly")
		end
	end

	local t = nil
	if #args == 1 and not args[1].__class__ then
		t = args[1]
		args = {}
	end

	local func = function(t)
		local class = class_generator(name, args, t)
		return class
	end

	if t then
		return func(t)
	else
		return func
	end
end

local gen_name
do
	local counter = 0

	function gen_name()
		counter = counter + 1
		return ("<anonymous class#%d>"):format(counter)
	end
end

class = setmetatable(class, {
	__call = function(self, name, ...)
		if type(name) == "string" then
			return function(...)
				return inheritance_handler(name, ...)
			end
		else
			return inheritance_handler(gen_name(), name, ...)
		end
	end,
})

-- issubclass is a simple search
function class.issubclass(class, parents)
	if parents.__class__ then parents = {parents} end
	for i, v in ipairs(parents) do
		if class == v or class.__parents__[v] then
			return true
		end
	end
	return false
end

-- And isinstance defers to issubclass.
function class.isinstance(obj, parents)
	return type(obj) == "table" and obj.__class__ and
			class.issubclass(obj.__class__, parents)
end

-- super simply finds the current class in the mro, and continues searching
-- from there
function class.super(current_class, instance, key)
	local class = instance.__class__ or instance
	local mro = class.__mro__
	local pos = mro:find(current_class)
	assert(pos, ("Class '%s' is not a superclass of '%s'!"):format(current_class.__name__, instance.__name__))
	return mro:get(key, pos+1)
end

-- Our root Object class
class.Object = class "Object"
{
	__new__ = function(self)
		return getmetatable(self).allocate()
	end,
}

-- Our AnnotationWrapper is a purely file local class, it's used to store
-- deferred application of Annotations. That is, when the class gets built,
-- then Annotations are applied, so the class name, and the class prototype
-- are available to the annotation.
AnnotationWrapper = class "AnnotationWrapper"
{
	__init__ = function(self, lhs, rhs)
		self.lhs, self.rhs = lhs, rhs
	end,

	-- We're just building a left-to-right linked list here
	__add__ = function(self, other)
		self.rhs = self.__class__(self.rhs, other)
		return self
	end,

	-- Since we have a left-to-right linked list, we can just
	-- apply them recursively outwards.
	resolve = function(self, name, cls)
		if class.isinstance(self.rhs, self.__class__) then
			self.rhs = self.rhs:resolve(name, cls)
		end

		-- Get any data previous invocations of this annotation on this member
		-- returned
		local anTable = getmetatable(cls).__annotations__
		local prev = anTable[self.lhs.__class__]
		if prev then prev = prev[name] end

		local val, extra = self.lhs:apply(self.rhs, name, cls, prev)

		-- If new data was returned, replace the old data
		if extra then prev = extra end

		-- If data is available, store it in the class metatable
		if prev then
			anTable[self.lhs.__class__] = anTable[self.lhs.__class__] or {}
			anTable[self.lhs.__class__][name] = prev
		end

		return val
	end,
}

-- Similarly our ClassAnnotationWrapper wraps.. well, class annoations
ClassAnnotationWrapper = class "ClassAnnotationWrapper"
{
	__init__ = function(self, ann)
		self.ann = ann
	end,

	-- Our 'pre-application'
	resolvePre = function(self, name, prototype)
		return self.ann:applyClassPre(name, prototype)
	end,

	-- Our 'post-application'
	resolvePost = function(self, name, class)
		return self.ann:applyClassPost(name, class)
	end,
}

-- Our annotation baseclass, nothing fancy, but it just defines the + operator,
-- and, perhaps more importantly, has access to AnnotationWrapper.
class.Annotation = class "class.Annotation"
{
	-- We're being applied to 'other', so return an AnnotationWrapper, so we
	-- can be resolved later
	__add__ = function(self, other)
		return AnnotationWrapper(self, other)
	end,

	-- We're being applied to a class, so return a ClassAnnotationWrapper, to be
	-- resolved later
	__neg__ = function(self)
		return ClassAnnotationWrapper(self)
	end,

	-- A default implementation of apply which does, predictably, nothing
	-- Note: The value returned by the annotation replaces the previous value,
	-- so if nothing (nil) is returned, it will become nil, this is intentional
	apply = function(self, f, name, class)
		return f
	end,

	-- And a default implementation of applyClassPre, which runs on the class'
	-- prototype. This is used for instance when applying Annotations to members
	-- or adding new members that could have annotations.
	applyClassPre = function(self, name, prototype)
	end,

	-- And applyClassPost, which runs on the final class. This can be used to do
	-- things with the final members, like modifying the constructor based on
	-- which annotations have been applied.
	applyClassPost = function(self, name, class)
	end,

	-- Obtain annotation information from a class member, if it exists
	get = function(self, class, name)
		local anTable = getmetatable(class).__annotations__[self]
		if not anTable then return nil end
		return anTable[name]
	end,

	-- Get all occurences of this annotation's data on a class
	iterate = function(self, class)
		local anTable = getmetatable(class).__annotations__[self]
		if not anTable then return function() return nil end end
		return pairs(anTable)
	end,

	-- Get all occurences of this annotation's and its subclasses' data on a
	-- class
	iterateFull = function(self, cls)
		local anTable = getmetatable(cls).__annotations__

		return coroutine.wrap(function()
			for ann, data in pairs(anTable) do
				-- If this annotation data was left by this class, or one of its
				-- subclasses, iterate over the data
				if class.issubclass(ann, self) then
					for member, value in pairs(data) do
						coroutine.yield(ann, member, value)
					end
				end
			end
		end)
	end,
}

class.Override = class "class.Override" (class.Annotation)
{
	apply = function(self, f, name, class)
		for i, v in ipairs(class.__parents__) do
			if v[name] then
				return f
			end
		end

		error(name .. " is marked override, but does not override a field or" ..
				" method from a baseclass")
	end,
}

-- Export a Class Commons interface
-- to allow interoperability between
-- class libraries.
-- See https://github.com/bartbes/Class-Commons
--
-- NOTE: Implicitly global, as per specification, unfortunately there's no nice
-- way to both provide this extra interface, and use locals.
if common_class ~= false then
	common = {}
	function common.class(name, prototype, superclass)
		prototype.__init__ = prototype.init
		return class_generator(name, {superclass}, prototype)
	end

	function common.instance(class, ...)
		return class(...)
	end
end

return class