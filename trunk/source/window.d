module ud1_arkanoid_d.window;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;

struct Window {
	int width, height;
	SDL_Window *window;
	SDL_GLContext glContext;
	bool disable_effects;

	~this() {
		if (glContext)
			SDL_GL_DeleteContext(glContext);

		if (window)
			SDL_DestroyWindow(window);
	}
}

Window *createWindow(int w, int h, bool disable_effects) {
	if (SDL_Init(SDL_INIT_VIDEO) < 0)
        return null;

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 1);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, disable_effects ? 0 : 1);

	SDL_Window *window = SDL_CreateWindow("ud1 arkanoid",
                                          SDL_WINDOWPOS_UNDEFINED,
                                          SDL_WINDOWPOS_UNDEFINED,
                                          w, h,
                                          SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);

    SDL_GLContext glContext = SDL_GL_CreateContext(window);
    if (glContext == null)
    {
        throw new Exception("There was an error creating the OpenGL context!");
    }

	const(char*) ver = glGetString(GL_VERSION);
    if (ver == null)
    {
        throw new Exception("There was an error creating the OpenGL context!");
    }

    SDL_GL_MakeCurrent(window, glContext);

	Window *result = new Window;
	result.width = w;
	result.height = h;
	result.disable_effects = disable_effects;
	result.window = window;
	result.glContext = glContext;
	return result;
}

import ud1_arkanoid_d.app;

void processMessages() {
	SDL_Event e;
	while (SDL_PollEvent(&e))
	{
		if (e.type == SDL_QUIT) {
			close_main_window();
		} else if (e.type == SDL_MOUSEMOTION) {
			mmove(e.motion.xrel, e.motion.yrel);
		} else if (e.type == SDL_MOUSEBUTTONDOWN && e.button.button == SDL_BUTTON_LEFT) {
			lbdown(e.button.x, e.button.y);
		} else if (e.type == SDL_MOUSEBUTTONUP && e.button.button == SDL_BUTTON_LEFT) {
			lbup(e.button.x, e.button.y);
		} else if (e.type == SDL_KEYDOWN) {
			key_down(e.key.keysym.sym);
		} else if (e.type == SDL_KEYUP) {
			key_up(e.key.keysym.sym);
		} else if (e.type == SDL_WINDOWEVENT && (e.window.event == SDL_WINDOWEVENT_FOCUS_LOST ||
			e.window.event== SDL_WINDOWEVENT_HIDDEN || e.window.event== SDL_WINDOWEVENT_MINIMIZED)) {
			on_deactivate();
		}
	}
}
