module deserializer;

struct Register
{
	string name;
}

private alias Id(alias T) = T;

private enum functionToName(alias func) = (&func).stringof[2..$];

void registerFunction(alias func)()
{
	import std.traits;
	alias UDAs = getUDAs!(func, Register);

	static if(UDAs.length == 1){
		string name = UDAs[0].name;
		pragma(msg, functionToName!func ~ ` as ` ~ UDAs[0].name);
	}else{
		string name = functionToName!func;
		pragma(msg, functionToName!func);
	}


	// registering stuff

}

public string registerFunctionsImpl(alias Module)() {
	import std.stdio;
	//pragma(msg, Module);
	//mixin("import " ~ Module ~ ";");
	string res = "shared static this () {\n"
		"import std.stdio;\n"
		"import std.traits;\n";
	foreach (immutable m; __traits(derivedMembers, Module)) {
		static if (is(typeof(__traits(getMember, Module, m)))) {
			alias mem = Id!(__traits(getMember, Module, m));
			static if (__traits(isStaticFunction, mem)) {
				res ~= "static if(hasUDA!(" ~ m ~ ", Register)) registerFunction!(" ~ m ~ ")();\n";
			}
		}
	}
	res ~= "}\n";
	return res;
}

enum registerFunctions = "static import deserializer; mixin(deserializer.registerFunctionsImpl!(mixin(__MODULE__)));";
