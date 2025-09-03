package trailrenderer.shaders;

import flixel.system.FlxAssets.FlxShader;
import lime.graphics.opengl.GLProgram;
import lime.utils.Log;

using StringTools;

#if !macro
@:autoBuild(trailrenderer.shaders.GeometryShaderMacro.build())
#end
class GeometryShader extends FlxShader
{
	public var geometrySource:String;
	public var version:String = null;
	
	@:glFragmentHeader('
        #pragma header

        vec4 flixel_tex2D(sampler2D texture, vec2 uv) {
            return texture2D(texture, uv);
        }

        #undef flixel_texture2D
        #define flixel_texture2D flixel_tex2D

        uniform sampler2D texture;
        varying vec2 geometryTextureCoord;
    ')
	@:glFragmentSource('
        #pragma header
        void main() {
            gl_FragColor = flixel_texture2D(texture, openfl_TextureCoordv);
        }
    ')
	@:glVertexHeader('
        #pragma header

        varying mat4 geom_Matrix;
        varying vec4 geom_Position;
    ')
	@:glVertexBody('
        #pragma body
        geom_Matrix = openfl_Matrix;
        geom_Position = openfl_Position;
    ')
	@:glVertexSource('
        #pragma header

        void main() {
            #pragma body
        }
    ')
	@:glGeometryHeader('
        #version 330 core
        #extension GL_EXT_geometry_shader : enable
        #extension GL_ARB_geometry_shader4 : enable

        #ifdef GL_ES
        #ifdef GL_FRAGMENT_PRECISION_HIGH
        precision highp float;
        #else
        precision mediump float;
        #endif
        #endif

        in mat4 geom_Matrix[3];
        in vec4 geom_Position[3];
        out vec2 geometryTextureCoord;
    ')
	@:glGeometryBody('
        gl_Position = gl_in[0].gl_Position;
        geometryTextureCoord = vec2(0.0, 0.0);
        EmitVertex();

        gl_Position = gl_in[1].gl_Position;
        geometryTextureCoord = vec2(0.0, 1.0);
        EmitVertex();

        gl_Position = gl_in[2].gl_Position;
        geometryTextureCoord = vec2(1.0, 0.0);
        EmitVertex();

        gl_Position = gl_in[3].gl_Position;
        geometryTextureCoord = vec2(1.0, 1.0);
        EmitVertex();

        EndPrimitive();
    ')
	@:glGeometrySource('
        #pragma header

        layout(triangles) in;
        layout(triangle_strip, max_vertices = 4) out;

        void main() {
            #pragma body
        }
    ')
	public function new(version:String = null)
	{
		this.version = version;
		super();
	}
	
	@:noCompletion override private function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram
	{
		@:privateAccess var gl = __context.gl;
		
		@:privateAccess var mvs:Float = Math.min(256, __context.__context.gl.getInteger(0x8DE0)); // bound to 256 for safety reasons
		
		var vertexShader = __createGLShader((version != null ? '#version $version\n' : '') + vertexSource, gl.VERTEX_SHADER);
		var fragmentShader = __createGLShader((version != null ? '#version $version\n' : '') + fragmentSource, gl.FRAGMENT_SHADER);
		var geometryShader = geometrySource != null ? __createGLShader(geometrySource.replace('GEOM_MAX_VERTICES', '$mvs'), 0x8DD9) : null;
		
		var program = gl.createProgram();
		
		// Fix support for drivers that don't draw if attribute 0 is disabled
		for (param in __paramFloat)
		{
			if (param.name.indexOf("Position") > -1 && StringTools.startsWith(param.name, "openfl_"))
			{
				gl.bindAttribLocation(program, 0, param.name);
				break;
			}
		}
		
		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		if (geometryShader != null)
			gl.attachShader(program, geometryShader);
		gl.linkProgram(program);
		
		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
		{
			var message = "Unable to initialize the shader program";
			message += "\n" + gl.getProgramInfoLog(program);
			Log.error(message);
		}
		
		return program;
	}
	
	@:noCompletion override private function __initGL():Void
	{
		if (__glSourceDirty || __paramBool == null)
		{
			__glSourceDirty = false;
			program = null;
			__inputBitmapData = new Array();
			__paramBool = new Array();
			__paramFloat = new Array();
			__paramInt = new Array();
			__processGLData(glVertexSource, "attribute");
			__processGLData(glVertexSource, "uniform");
			__processGLData(glFragmentSource, "uniform");
			if (geometrySource != null)
			{
				// __processGLData(geometrySource, "attribute");
				__processGLData(geometrySource, "uniform");
			}
		}
		super.__initGL();
	}
}
