import std.stdio;

import deserializer;

@Register(`pow`)
double myPow(double b, double e)
{
	import std.math;
	return b.pow(e);
}

@Register
int makeItDouble(int value)
{
	return 2*value;
}

void main()
{
	auto powInput = q{{
		"b": 2,
		"e": 10
	}};

	auto midInput = q{{
		"value": 21
	}};

	auto powResult = "pow".call(powInput);
	auto midResult = deserializer.call("makeItDouble", midInput);

	powResult.writeln;
	midResult.writeln;

	assert(powResult == `{"Result":1024}`);
	assert(midResult == `{"Result":42}`);
}



mixin(registerFunctions);
