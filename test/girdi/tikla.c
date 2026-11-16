// İç içe KWin sınamaları için sahte girdi (org_kde_kwin_fake_input): yalnız WAYLAND_DISPLAY'deki
// bileşikleyiciye gider. KWin'i KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 ile başlatın.
//   tikla <x> <y> [sol|sag|yok]   imleci (x,y)'ye götürür, isteğe bağlı tıklar
//   tikla tus <ad...>             tuşlara basar: asagi yukari sag sol enter esc
#include <linux/input-event-codes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "fake-input-client-protocol.h"

static struct org_kde_kwin_fake_input *girdi;

static void kayit(void *v, struct wl_registry *r, uint32_t ad, const char *arayuz, uint32_t surum)
{
    (void)v;
    if (strcmp(arayuz, org_kde_kwin_fake_input_interface.name) == 0)
        girdi = wl_registry_bind(r, ad, &org_kde_kwin_fake_input_interface, surum < 4 ? surum : 4);
}
static void kaldir(void *v, struct wl_registry *r, uint32_t ad) { (void)v; (void)r; (void)ad; }
static const struct wl_registry_listener dinleyici = {kayit, kaldir};

int main(int argc, char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "kullanım: tikla x y [sol|sag|yok]\n");
        return 2;
    }
    // gerçek oturuma asla: yalnız sınama betiklerinin verdiği işaretle ve mt-/mtmenu- soketleriyle
    const char *isaret = getenv("METRO_SINAMA_GIRDI");
    const char *soket = getenv("WAYLAND_DISPLAY");
    if (!isaret || strcmp(isaret, "1") != 0 || !soket || strncmp(soket, "mt", 2) != 0) {
        fprintf(stderr, "yalnız iç içe sınama oturumunda çalışır\n");
        return 3;
    }
    struct wl_display *d = wl_display_connect(NULL);
    if (!d) {
        fprintf(stderr, "bileşikleyiciye bağlanılamadı\n");
        return 1;
    }
    struct wl_registry *r = wl_display_get_registry(d);
    wl_registry_add_listener(r, &dinleyici, NULL);
    wl_display_roundtrip(d);
    if (!girdi) {
        fprintf(stderr, "org_kde_kwin_fake_input yok\n");
        return 1;
    }
    org_kde_kwin_fake_input_authenticate(girdi, "metro-sinama", "iç içe oturum sınaması");
    if (strcmp(argv[1], "tus") == 0) {
        static const struct { const char *ad; uint32_t kod; } tuslar[] = {
            {"asagi", KEY_DOWN}, {"yukari", KEY_UP}, {"sag", KEY_RIGHT}, {"sol", KEY_LEFT},
            {"enter", KEY_ENTER}, {"esc", KEY_ESC}};
        for (int i = 2; i < argc; ++i)
            for (unsigned j = 0; j < sizeof tuslar / sizeof *tuslar; ++j)
                if (strcmp(argv[i], tuslar[j].ad) == 0) {
                    org_kde_kwin_fake_input_keyboard_key(girdi, tuslar[j].kod, WL_KEYBOARD_KEY_STATE_PRESSED);
                    wl_display_roundtrip(d);
                    usleep(30000);
                    org_kde_kwin_fake_input_keyboard_key(girdi, tuslar[j].kod, WL_KEYBOARD_KEY_STATE_RELEASED);
                    wl_display_roundtrip(d);
                    usleep(150000);
                }
        wl_display_disconnect(d);
        return 0;
    }
    org_kde_kwin_fake_input_pointer_motion_absolute(girdi, wl_fixed_from_double(atof(argv[1])), wl_fixed_from_double(atof(argv[2])));
    wl_display_roundtrip(d);
    const char *t = argc > 3 ? argv[3] : "sol";
    if (strcmp(t, "yok") != 0) {
        uint32_t b = strcmp(t, "sag") == 0 ? BTN_RIGHT : BTN_LEFT;
        usleep(50000);
        org_kde_kwin_fake_input_button(girdi, b, WL_POINTER_BUTTON_STATE_PRESSED);
        wl_display_roundtrip(d);
        usleep(50000);
        org_kde_kwin_fake_input_button(girdi, b, WL_POINTER_BUTTON_STATE_RELEASED);
        wl_display_roundtrip(d);
    }
    wl_display_disconnect(d);
    return 0;
}
