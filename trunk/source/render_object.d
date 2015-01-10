module ud1_arkanoid_d.render_object;

struct RenderVertex {
	import ud1_arkanoid_d.vector2d;

	Vector coord;
	Vector tex_coord;
};

struct RenderTriangle {
	RenderVertex[3] vertexes;
};

struct RenderObjectPrototype {
	RenderTriangle[] render_triangles;
};

struct RenderObject {
	import ud1_arkanoid_d.vector2d;

	// must be the first function called
	void setPrototype(in RenderObjectPrototype proto, in Vector scale) {
		size_t render_triangles_size = proto.render_triangles.length;
		render_triangles.length = render_triangles_size;
		proto_render_triangles.length = render_triangles_size;

		for (size_t i = 0; i < render_triangles_size; ++i) {
			RenderTriangle *tri = &proto_render_triangles[i];
			const RenderTriangle *prot_tri = &proto.render_triangles[i];
			for (size_t j = 0; j < 3; ++j) {
				tri.vertexes[j].coord = prot_tri.vertexes[j].coord * scale;
				tri.vertexes[j].tex_coord = prot_tri.vertexes[j].tex_coord;
			}
		}
	}

	void setPosition(in Vector pos, float angle) {
		import std.math;

		size_t render_triangles_size = proto_render_triangles.length;
		if (render_triangles_size) {
			float sina = sin(angle);
			float cosa = cos(angle);
			for (size_t i = 0; i < render_triangles_size; ++i) {
				RenderTriangle *tri = &render_triangles[i];
				const RenderTriangle *prot_tri = &proto_render_triangles[i];
				for (size_t j = 0; j < 3; ++j) {
					tri.vertexes[j].coord = pos + prot_tri.vertexes[j].coord.rotate(sina, cosa);
					tri.vertexes[j].tex_coord = prot_tri.vertexes[j].tex_coord;
				}
			}
		}
	}

	const(RenderTriangle[]) getTriangles() const {
		return render_triangles;
	}

protected:
	RenderTriangle[] render_triangles, proto_render_triangles;
};
