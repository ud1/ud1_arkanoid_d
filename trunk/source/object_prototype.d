module ud1_arkanoid_d.object_prototype;

struct ObjectPrototype {
	import ud1_arkanoid_d.polygon_collision_object;
    import ud1_arkanoid_d.render_object;

	void loadFromFile(string filename) {
		import std.stdio;
		import std.format;

		auto f = File(filename, "r");

		foreach(line; f.byLine()) {
            if (line.length < 3)
				continue;

			if (line[0] == '/' && line[1] == '/')
				continue;

			string cmd;
			if (formattedRead(line, "%s ", &cmd) != 1)
				throw new Exception("Parse error: " ~ line.idup);

			if (cmd == "seg") {
				SegmentProto seg;

				if (formattedRead(line, "%s %s %s %s", &seg.p1.x(), &seg.p1.y(), &seg.p2.x(), &seg.p2.y()) != 4) {
					throw new Exception("Parse error, seg: " ~ line.idup);
				}

				col_obj_proto.segs ~= seg;
			} else if (cmd == "tri") {
				RenderTriangle tri;

				if (formattedRead(line, "%s %s %s %s %s %s %s %s %s %s %s %s"
					, &tri.vertexes[0].coord.x(), &tri.vertexes[0].coord.y()
					, &tri.vertexes[0].tex_coord.x(), &tri.vertexes[0].tex_coord.y()
					, &tri.vertexes[1].coord.x(), &tri.vertexes[1].coord.y()
					, &tri.vertexes[1].tex_coord.x(), &tri.vertexes[1].tex_coord.y()
					, &tri.vertexes[2].coord.x(), &tri.vertexes[2].coord.y()
					, &tri.vertexes[2].tex_coord.x(), &tri.vertexes[2].tex_coord.y()) != 12) {
					throw new Exception("Parse error, tri: " ~ line.idup);
				}

				render_obj_proto.render_triangles ~= tri;
			} else {
				throw new Exception("Parse error: " ~ cmd);
			}
		}
	}

	PolygonColObjPrototype col_obj_proto;
	RenderObjectPrototype render_obj_proto;
};

struct ObjectPrototypeManager {
	const(ObjectPrototype) *get(string type) {
		if (ObjectPrototype *prototype = type in prototypes)
			return prototype;

		ObjectPrototype proto;
		proto.loadFromFile("conf/" ~ type ~ ".txt");

		prototypes[type] = proto;
		return &(prototypes[type] = proto);
	}

protected:
	ObjectPrototype[string] prototypes;
}
