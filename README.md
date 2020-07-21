# MTA-RI
Fun interface between resources in MTA:SA

# Install
Copy refinterface.lua in your resources and add exports function from meta.xml

# How to use examples:

Resource "ref_test1"
```
RI.ref_test2.new_value = 100
RI.ref_test2.HERE_TABLE.value = 150

local t = { 200 }
RI.ref_test2.ANOTHER_TABLE = t

RI.ref_test2.test_function( 'new' )

RI.ref_test2.getVehicleNameFromModel = function( id )
   return "Vehicle ID:" .. id
end
```

Resource "ref_test2"

```
HERE_TABLE = {}

Timer( function()
	iprint( "new_value", new_value )
	iprint( "HERE_TABLE.value", HERE_TABLE.value )
	if ANOTHER_TABLE then 
		iprint( "ANOTHER_TABLE[1]", ANOTHER_TABLE[1] )
	end
end, 5000, 0 )

function test_function( str )
	iprint( 'WORKS', str )
end
```

# Warnings
- It's slow
- 
