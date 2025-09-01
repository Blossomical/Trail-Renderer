package trailrenderer.shaders;

import flixel.math.FlxMath;
import lime.utils.Float32Array;

class CustomGeometry extends GeometryShader
{
	public var vertices(default, set):DrawData<Float>;
	public var uvtData(default, set):DrawData<Float>;
	public var autoUVT(default, set):Bool;
	
	@:glGeometrySource('
        #pragma header

        layout(triangles) in;
        layout(triangle_strip, max_vertices = GEOM_MAX_VERTICES) out;

        uniform float numVertices;

        uniform vec2 geometry_vertices[GEOM_MAX_VERTICES];
        uniform vec2 geometry_uvtData[GEOM_MAX_VERTICES];
        uniform bool geometry_autoUVT;
        uniform float geometry_totalLength;

        uniform mat2 geometry_rotationMatrix;
        uniform vec2 geometry_origin;

        out float segDist;
        void main() {
            float dist = 0.0;
            segDist = 0.0;

            for (int j = 0; j < numVertices; j++) {
                vec2 vertex = geometry_vertices[j] - geometry_origin;
                vertex = geometry_rotationMatrix * vertex;
                vertex += geometry_origin;

                gl_Position = gl_in[0].gl_Position + geom_Matrix[0] * vec4(vertex, 0.0, 0.0);
                if (geometry_autoUVT) {
                    if (j > 0)
                        dist += length(geometry_vertices[j] - geometry_vertices[j - 1]);
                    else
                        dist = 0.0;

                    if (j > 1)
                        segDist += length(geometry_vertices[j] - geometry_vertices[j - 2]);
                    else
                        segDist = 0.0;

                    float u = dist / geometry_totalLength;
                    float v = (j % 2 == 0) ? 1.0 : 0.0;

                    geometryTextureCoord = vec2(u, v);
                } else
                    geometryTextureCoord = geometry_uvtData[j];

                EmitVertex();
            }
            EndPrimitive();
        }
    ')
	@:glFragmentSource('
        #pragma header
        void main() {
            gl_FragColor = flixel_texture2D(texture, geometryTextureCoord);
        }
    ')
	public function new(glVersion:String = '330')
	{
		super(glVersion);
		vertices = new DrawData<Float>([], 512);
		uvtData = new DrawData<Float>([], 512);
		
		vertices.changeCallback = (index, value) ->
		{
			var length:Int = Std.int(vertices.data.length / 2);
			numVertices.value = [length];
			
			if (autoUVT)
			{
				var totalLength:Float = 0;
				for (i in 1...length)
					totalLength += FlxMath.vectorLength(vertices.data[i * 2] - vertices.data[i * 2 - 2], vertices.data[i * 2 + 1] - vertices.data[i * 2 - 1]);
				geometry_totalLength.value = [totalLength];
			}
		}
		
		geometry_origin.value = [0, 0];
		geometry_rotationMatrix.value = [1, 0, 0, 1];
	}
	
	public function rotate(angle:Float = 0):Float
	{
		var c:Float = Math.cos(angle);
		var s:Float = Math.sin(angle);
		geometry_rotationMatrix.value = [c, -s, s, c];
		return angle;
	}
	
	private function set_vertices(value:DrawData<Float>)
	{
		if (vertices == null)
			vertices = value;
		vertices.data = value;
		// geometry_vertices.value = vertices.shaderArray;
		
		return value;
	}
	
	private function set_uvtData(value:DrawData<Float>)
	{
		if (uvtData == null)
			uvtData = value;
		uvtData.data = value;
		// geometry_uvtData.value = uvtData.shaderArray;
		return value;
	}
	
	private function set_autoUVT(value:Bool)
	{
		geometry_autoUVT.value = [value];
		return this.autoUVT = value;
	}
	
	// super quick way to handle uniform arrays
	@:noCompletion override private function __updateGL():Void
	{
		super.__updateGL();
		@:privateAccess {
			var gl = __context.gl;
			gl.uniform2fv(gl.getUniformLocation(program.__glProgram, "geometry_vertices"), new Float32Array(vertices.shaderArray));
			gl.uniform2fv(gl.getUniformLocation(program.__glProgram, "geometry_uvtData"), new Float32Array(uvtData.shaderArray));
		}
	}
	
	@:noCompletion override private function __updateGLFromBuffer(shaderBuffer:openfl.display._internal.ShaderBuffer, bufferOffset:Int):Void
	{
		super.__updateGLFromBuffer(shaderBuffer, bufferOffset);
		@:privateAccess {
			var gl = __context.gl;
			gl.uniform2fv(gl.getUniformLocation(program.__glProgram, "geometry_vertices"), new Float32Array(vertices.shaderArray));
			gl.uniform2fv(gl.getUniformLocation(program.__glProgram, "geometry_uvtData"), new Float32Array(uvtData.shaderArray));
		}
	}
}
