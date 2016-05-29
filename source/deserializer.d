module deserializer;

struct Register
{
	string name;
}

public struct Result
{
	string Result;
}

public string call(immutable string name, immutable string json){
	return registry.call(name, json);
}

private struct Registry
{
	alias func = string function(const string);
	
	func[string] map;

	void register(string name, func f){
		if(name in map){
			import std.stdio;
			stderr.writefln("Function '%s' already registered.", name);
		}
		map[name] = f;
	}

	shared string call(string name, string json) const {
		if(auto ptr = name in map){
			return (*ptr)(json);
		}else{
			import std.format;
			throw new Exception(`Function '%s' not found!`.format(name));
		}
	}
}

shared Registry registry;

private alias Id(alias T) = T;

private enum functionToName(alias func) = (&func).stringof[2..$];

private string makeParamsStruct(alias func)()
{
	import std.traits;
	alias ParamNames = ParameterIdentifierTuple!func;
	alias ParamTypes = Parameters!func;

	static assert(ParamNames.length == ParamTypes.length);

	string structDef = "struct ParamStruct{ \n";
	foreach(i, m; ParamNames){
		structDef ~= `	` ~ ParamTypes[i].stringof ~ ` ` ~ m ~ ";\n";
	}

	structDef ~= "}\n";
	return structDef;
}

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

	pragma(msg, makeParamsStruct!func);
	mixin(makeParamsStruct!func);

	auto wrapper = function string(string json){
		import painlessjson : fromJSON;
		import std.json;
		ParamStruct params = fromJSON!ParamStruct(parseJSON(json));
		return "";
	};

	//pragma(msg, ParamStruct.codeof);

}

public string registerFunctionsImpl(alias Module)()
{
	import std.stdio;
	//pragma(msg, Module);
	//mixin("import " ~ Module ~ ";");
	string res = "shared static this () {\n" ~
		"import std.stdio;\n" ~
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
