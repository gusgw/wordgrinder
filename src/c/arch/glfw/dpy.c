/* © 2021 David Given.
 * WordGrinder is licensed under the MIT open source license. See the COPYING
 * file in this distribution for the full text.
 */

#include "globals.h"
#include <string.h>
#include <GLES/gl.h>
#include <GLFW/glfw3.h>

static GLFWwindow* window;

static int screenwidth;
static int screenheight;
static int cursorx;
static int cursory;
static bool cursor_shown;
static int defaultattr;

#define VK_RESIZE     0x80000
#define VK_TIMEOUT    0x80001

static void fatal(const char* s, ...)
{
    va_list ap;
    va_start(ap, s);
    fprintf(stderr, "error: ");
    vfprintf(stderr, s, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    exit(1);
}

void dpy_init(const char* argv[])
{
}

static void handle_resize(void)
{
	int width, height;
	glfwGetFramebufferSize(window, &width, &height);
	glViewport(0, 0, width, height);
	glOrthof(0, width, 0, height, -1, 1);
	printf("width=%d height=%d\n", width, height);
}

void dpy_start(void)
{
	if (!glfwInit())
		fatal("couldn't start GLFW");

	window = glfwCreateWindow(640, 480, "WordGrinder", NULL, NULL);
	if (!window)
		fatal("couldn't create window");
	glfwMakeContextCurrent(window);
	handle_resize();
}

void dpy_shutdown(void)
{
	glfwTerminate();
}

void dpy_clearscreen(void)
{
}

void dpy_getscreensize(int* x, int* y)
{
    *x = screenwidth;
    *y = screenheight;
}

void dpy_sync(void)
{
	glfwSwapBuffers(window);
}

void dpy_setcursor(int x, int y, bool shown)
{
    cursorx = x;
    cursory = y;
    cursor_shown = shown;
}

void dpy_setattr(int andmask, int ormask)
{
	defaultattr &= andmask;
	defaultattr |= ormask;
}

void dpy_writechar(int x, int y, uni_t c)
{
}

void dpy_cleararea(int x1, int y1, int x2, int y2)
{
}

uni_t dpy_getchar(double timeout)
{
	glfwWaitEventsTimeout(timeout);
	return -VK_TIMEOUT;
}

const char* dpy_getkeyname(uni_t k)
{
	#if 0
    switch (-k)
    {
        case VK_RESIZE:      return "KEY_RESIZE";
        case VK_TIMEOUT:     return "KEY_TIMEOUT";
    }

    int mods = -k;
    int key = (-k & 0xfff0ffff);
    static char buffer[32];

    if (mods & VKM_CTRLASCII)
    {
        sprintf(buffer, "KEY_%s^%c",
                (mods & VKM_SHIFT) ? "S" : "",
                key + 64);
        return buffer;
    }

    const char* template = NULL;
    switch (key)
    {
        case SDLK_DOWN:        template = "DOWN"; break;
        case SDLK_UP:          template = "UP"; break;
        case SDLK_LEFT:        template = "LEFT"; break;
        case SDLK_RIGHT:       template = "RIGHT"; break;
        case SDLK_HOME:        template = "HOME"; break;
        case SDLK_END:         template = "END"; break;
        case SDLK_BACKSPACE:   template = "BACKSPACE"; break;
        case SDLK_DELETE:      template = "DELETE"; break;
        case SDLK_INSERT:      template = "INSERT"; break;
        case SDLK_PAGEUP:      template = "PGUP"; break;
        case SDLK_PAGEDOWN:    template = "PGDN"; break;
        case SDLK_TAB:         template = "TAB"; break;
        case SDLK_RETURN:      template = "RETURN"; break;
        case SDLK_ESCAPE:      template = "ESCAPE"; break;
        case SDLK_MENU:        template = "MENU"; break;
    }

    if (template)
    {
        sprintf(buffer, "KEY_%s%s%s",
                (mods & VKM_SHIFT) ? "S" : "",
                (mods & VKM_CTRL) ? "C" : "",
                template);
        return buffer;
    }

    if ((key >= SDLK_F1) && (key <= (SDLK_F24)))
    {
        sprintf(buffer, "KEY_%s%sF%d",
                (mods & VKM_SHIFT) ? "S" : "",
                (mods & VKM_CTRL) ? "C" : "",
                key - SDLK_F1 + 1);
        return buffer;
    }

    sprintf(buffer, "KEY_UNKNOWN_%d", -k);
    return buffer;
	#endif
	return "KEY_TIMEOUT";
}

// vim: sw=4 ts=4 et


