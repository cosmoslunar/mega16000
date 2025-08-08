#include <windows.h>
#include <stdlib.h>
#include <time.h>

#define FPS 30

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (msg == WM_DESTROY) {
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

void RenderFrame(HDC hdc, int w, int h, int tick) {
    for (int i = 0; i < 10; i++) {
        HBRUSH brush = CreateSolidBrush(RGB(rand()%256, rand()%256, rand()%256));
        SelectObject(hdc, brush);
        Ellipse(hdc, rand()%w, rand()%h, rand()%w, rand()%h);
        DeleteObject(brush);
    }

    int pipW = w / 3, pipH = h / 3;
    BitBlt(hdc, w - pipW - 10, h - pipH - 10, pipW, pipH, hdc, 0, 0, SRCCOPY);

    POINT p;
    GetCursorPos(&p);
    ScreenToClient(WindowFromDC(hdc), &p);
    HBRUSH brush = CreateSolidBrush(RGB((tick*5)%256, (tick*7)%256, (tick*11)%256));
    SelectObject(hdc, brush);
    Ellipse(hdc, p.x-10, p.y-10, p.x+10, p.y+10);
    DeleteObject(brush);

    for (int i = 0; i < 30; i++) {
        int px = rand() % w;
        int py = rand() % h;
        PatBlt(hdc, px, py, 20, 20, PATINVERT);
    }

    for (int i = 0; i < 5; i++) {
        int sx = rand() % w;
        int sy = rand() % h;
        int sw = rand() % 100 + 20;
        int sh = rand() % 100 + 20;
        int dx = sx + (rand()%21 - 10);
        int dy = sy + (rand()%21 - 10);
        BitBlt(hdc, dx, dy, sw, sh, hdc, sx, sy, SRCCOPY);
    }

    static int lastFlipTick = -1;
    int seconds = tick / FPS;
    if (seconds != lastFlipTick) {
        lastFlipTick = seconds;
        SetStretchBltMode(hdc, HALFTONE);
        StretchBlt(hdc, 0, 0, w, h, hdc, w-1, 0, -w, h, SRCCOPY);
    }
}

int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrev, LPSTR lpCmdLine, int nCmdShow) {
    srand((unsigned)time(NULL));

    WNDCLASS wc = {0};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = "FlashyGDI";
    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(0, wc.lpszClassName, "Flashy GDI Demo",
                               WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                               CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
                               NULL, NULL, hInstance, NULL);

    HDC hdc = GetDC(hwnd);
    MSG msg;
    int tick = 0;
    while (1) {
        while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
            if (msg.message == WM_QUIT) return 0;
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
        RECT r;
        GetClientRect(hwnd, &r);
        RenderFrame(hdc, r.right, r.bottom, tick++);
        Sleep(1000 / FPS);
    }
    return 0;
}