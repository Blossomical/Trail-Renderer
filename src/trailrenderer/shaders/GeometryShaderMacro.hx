package trailrenderer.shaders;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.Tools;
using haxe.macro.TypeTools;

class GeometryShaderMacro {
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();

		var glGeometryHeader:String = '';
		var glGeometryBody:String = '';
		var glGeometrySource:String = null;

		for (field in fields) {
			for (meta in field.meta) {
				switch (meta.name) {
					case 'glGeometrySource', ':glGeometrySource':
						glGeometrySource = meta.params[0].getValue();
					case 'glGeometryHeader', ':glGeometryHeader':
						glGeometryHeader = meta.params[0].getValue();
					case 'glGeometryBody', ':glGeometryBody':
						glGeometryBody = meta.params[0].getValue();
					default:
				}
			}
		}

		var pos = Context.currentPos();
		var localClass = Context.getLocalClass().get();
		var superClass = localClass.superClass != null ? localClass.superClass.t.get() : null;
		var parent = superClass;
		var parentFields:Array<ClassField>;

		while (parent != null) {
			parentFields = [parent.constructor.get()].concat(parent.fields.get());

			for (field in parentFields) {
				for (meta in field.meta.get()) {
					switch (meta.name) {
						case "glGeometrySource", ":glGeometrySource":
							if (glGeometrySource == null)
								glGeometrySource = meta.params[0].getValue();

						case "glGeometryHeader", ":glGeometryHeader":
							glGeometryHeader = meta.params[0].getValue() + "\n" + glGeometryHeader;

						case "glGeometryBody", ":glGeometryBody":
							glGeometryBody = meta.params[0].getValue() + "\n" + glGeometryBody;

						default:
					}
				}
			}

			parent = parent.superClass != null ? parent.superClass.t.get() : null;
		}

		if (glGeometrySource != null) {
			if (glGeometryHeader != null && glGeometryBody != null) {
				glGeometrySource = StringTools.replace(glGeometrySource, "#pragma header", glGeometryHeader);
				glGeometrySource = StringTools.replace(glGeometrySource, "#pragma body", glGeometryBody);
			}

			var shaderDataFields:Array<Field> = [];
			var uniqueFields:Array<Field> = [];
			@:privateAccess openfl.utils._internal.ShaderMacro.processFields(glGeometrySource, "uniform", shaderDataFields, pos);

			if (shaderDataFields.length > 0) {
				var fieldNames = new Map<String, Bool>();

				for (field in shaderDataFields) {
					parent = superClass;

					while (parent != null) {
						for (parentField in parent.fields.get()) {
							if (parentField.name == field.name) {
								fieldNames.set(field.name, true);
							}
						}

						parent = parent.superClass != null ? parent.superClass.t.get() : null;
					}

					if (!fieldNames.exists(field.name)) {
						uniqueFields.push(field);
					}

					fieldNames[field.name] = true;
				}
			}

			// #if !display
			for (field in fields) {
				switch (field.name) {
					case "new":
						var block = switch (field.kind) {
							case FFun(f):
								if (f.expr == null)
									null;

								switch (f.expr.expr) {
									case EBlock(e): e;
									default: null;
								}

							default: null;
						}

						if (glGeometrySource != null) {
							block.unshift(macro if (geometrySource == null) {
								geometrySource = $v{glGeometrySource};
							});
						}

						block.push(Context.parse("__isGenerated = true", pos));
						block.push(Context.parse("__initGL ()", pos));

					default:
				}
			}
			// #end

			fields = fields.concat(uniqueFields);
		}

		return fields;
	}
}
#end
