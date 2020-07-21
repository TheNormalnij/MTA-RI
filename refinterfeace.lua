
local RI_VERSION = 1

local _G = _G
local type = type
local rawget = rawget
local setmetatable = setmetatable
local call = call
local ref = ref
local deref = deref
local getResourceFromName = getResourceFromName
local getResourceName = getResourceName
local getResourceRootElement = getResourceRootElement

local refMT
refMT = {

	__index = function( self, key )
		local resource = rawget( self, '__resource' )
		local value, isRef = call( resource, '__RIG', rawget( self, '__ref' ), key )
		if isRef then
			return setmetatable( { __ref = value, __resource = resource }, refMT )
		else
			return value
		end
	end;

	__newindex = function( self, key, value )
		local valueType = type( value )
		if valueType == 'table' or valueType == 'function' or valueType == 'thread' then
			call( rawget( self, '__resource' ), '__RIS', rawget( self, '__ref' ), key, ref( value ) )
		else
			call( rawget( self, '__resource' ), '__RISR', rawget( self, '__ref' ), key, value )
		end
	end;

	__call = function( self, ... )
		local args = { ... }
		local value, valueType
		for i = 1, #args do
			value = args[i]
			valueType = type( value )
			if ( valueType == 'table' and not rawget( value.__ref ) ) or valueType == 'function' or valueType == 'thread' then
				args[i] = { __ref = ref( value ),  __resource = resource }
			end
		end
		local output = call( rawget( self, '__resource' ), '__RIC', rawget( self, '__ref' ), args )

		for i = 1, #output do
			if type( output[i] ) == 'table' then
				if output[i].__resource == resource then
					output[i] = deref( output[i].__ref )
				else
					output[i] = setmetatable( output[i], refMT )
				end
			end
		end

		return unpack( output )
	end;
}
--

function RIGetRaw( refPointer, key )
	return call( rawget( refPointer, '__resource' ), '__RIGR', rawget( refPointer, '__ref' ), key )
end;

function RISetRaw( refPointer, key, value )
	call( rawget( refPointer, '__resource' ), '__RISR', rawget( refPointer, '__ref' ), key, value )
end;

function RICallRaw( refPointer, ... )
	return call( rawget( refPointer, '__resource' ), '__RICR', rawget( refPointer, '__ref' ), ... )
end;

function RIDump( refPointer )
	return call( rawget( refPointer, '__resource' ), '__RID', rawget( refPointer, '__ref' ) )
end;

function RIIsRef( refPointer )
	return type( refPointer ) == 'table' and type( rawget( '__ref' ) ) == 'number'
end;

RI = setmetatable( {}, 
	{
		__index = function( self, resource )
			local resourceName
			if type( resource ) ~= 'userdata' then
				resourceName = resource
				resource = getResourceFromName( resourceName )
			else
				resourceName = getResourceName( resource )
			end

			if resource and getResourceRootElement( resource ) then
				local version, globalRef = call( resource, '__RI' )
				if version == RI_VERSION then
					return setmetatable( { __ref = globalRef, __resource = resource }, refMT )
				else
					outputDebugString('ri: RI version missmath (' .. resourceName .. ')', 1)
				end
			else
				outputDebugString('ri: Call to non-running server resource (' .. resourceName .. ')', 1)
				return setmetatable({}, rescallMT)
			end
		end
	}
)

-- Exports, internal use only

-- Create ref interfeace
function __RI( )
	return RI_VERSION, ref( _G )
end

--- Set any raw value
function __RISR( refPointer, key, value )
	deref( refPointer )[key] = value
end

-- Get any raw value
function __RIGR( refPointer, key )
	return deref( refPointer )[key]
end

-- Set ref value
function __RIS( refPointer, key, toRefID )
	deref( refPointer )[key] = setmetatable( { __ref = toRefID, __resource = sourceResource }, refMT )
end

-- Get ref value
function __RIG( refPointer, key )
	local value = deref( refPointer )[key]
	local valueType = type( value )
	if valueType == 'table' or valueType == 'function' or valueType == 'thread' then
		return ref( value ), true
	else
		return value, false
	end
end

-- Call ref value
function __RIC( refPointer, args )

	local value 
	for i = 1, #args do
		value = args[i]
		if type( value ) == 'table' then
			if args[i].__resource == resource then
				args[i] = deref( value.__ref )
			else
				args[i] = setmetatable( value, refMT )
			end
		end
	end

	local output = { deref( refPointer )( unpack( args ) ) }
	local valueType
	for i = 1, #output do
		valueType = type( output[i] ) 
		if valueType == 'table' or valueType == 'function' or valueType == 'thread' then
			output[i] = setmetatable( { __ref = ref( output[i] ),  __resource = resource }, refMT )
		end
	end
	return output
end

-- Call raw value
function __RICR( refPointer, ... )
	return deref( refPointer )( ... )
end

-- Dump
function __RID( refPointer )
	return refPointer and deref( refPointer ) or _G
end
