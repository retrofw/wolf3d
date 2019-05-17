CONFIG ?= config.default
-include $(CONFIG)

CHAINPREFIX := /opt/mipsel-linux-uclibc
CROSS_COMPILE := $(CHAINPREFIX)/usr/bin/mipsel-linux-

CC  := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
STRIP := $(CROSS_COMPILE)strip

BINARY    ?= wolf3d/wolf3d.elf
PREFIX    ?= .
MANPREFIX ?= $(PREFIX)

INSTALL         ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 555 -s
INSTALL_MAN     ?= $(INSTALL) -m 444
INSTALL_DATA    ?= $(INSTALL) -m 444

SYSROOT := $(shell $(CC) --print-sysroot)
SDL_CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

CFLAGS += $(SDL_CFLAGS)

#CFLAGS += -Wall
#CFLAGS += -W
CFLAGS += -Wpointer-arith
CFLAGS += -Wreturn-type
CFLAGS += -Wwrite-strings
CFLAGS += -Wcast-align
#CFLAGS += -DGP2X

CCFLAGS += $(CFLAGS)
CCFLAGS += -std=gnu99 --static
CCFLAGS += -Werror-implicit-function-declaration
CCFLAGS += -Wimplicit-int
CCFLAGS += -Wsequence-point


CXXFLAGS += $(CFLAGS)

LDFLAGS += $(SDL_LIBS)
LDFLAGS += -lSDL_mixer

SRCS :=
SRCS += src/fmopl.cpp
SRCS += src/id_ca.cpp
SRCS += src/id_in.cpp
SRCS += src/id_pm.cpp
SRCS += src/id_sd.cpp
SRCS += src/id_us_1.cpp
SRCS += src/id_vh.cpp
SRCS += src/id_vl.cpp
SRCS += src/signon.cpp
SRCS += src/wl_act1.cpp
SRCS += src/wl_act2.cpp
SRCS += src/wl_agent.cpp
SRCS += src/wl_atmos.cpp
SRCS += src/wl_cloudsky.cpp
SRCS += src/wl_debug.cpp
SRCS += src/wl_draw.cpp
SRCS += src/wl_floorceiling.cpp
SRCS += src/wl_game.cpp
SRCS += src/wl_inter.cpp
SRCS += src/wl_main.cpp
SRCS += src/wl_menu.cpp
SRCS += src/wl_parallax.cpp
SRCS += src/wl_play.cpp
SRCS += src/wl_state.cpp
SRCS += src/wl_text.cpp
SRCS += src/gp2x.cpp

DEPS = $(filter %.d, $(SRCS:.c=.d) $(SRCS:.cpp=.d))
OBJS = $(filter %.o, $(SRCS:.c=.o) $(SRCS:.cpp=.o))

.SUFFIXES:
.SUFFIXES: .c .cpp .d .o

Q ?= @

all: $(BINARY)

ifndef NO_DEPS
depend: $(DEPS)

ifeq ($(findstring $(MAKECMDGOALS), clean depend Data),)
-include $(DEPS)
endif
endif

$(BINARY): $(OBJS)
	@echo '===> LD $@'
	$(Q)$(CXX) $(CFLAGS) $(OBJS) $(LDFLAGS) -o $@

.c.o:
	@echo '===> CC $<'
	$(Q)$(CC) $(CCFLAGS) -c $< -o $@

.cpp.o:
	@echo '===> CXX $<'
	$(Q)$(CXX) $(CXXFLAGS) -c $< -o $@

.c.d:
	@echo '===> DEP $<'
	$(Q)$(CC) $(CCFLAGS) -MM $< | sed 's#^$(@F:%.d=%.o):#$@ $(@:%.d=%.o):#' > $@

.cpp.d:
	@echo '===> DEP $<'
	$(Q)$(CXX) $(CXXFLAGS) -MM $< | sed 's#^$(@F:%.d=%.o):#$@ $(@:%.d=%.o):#' > $@

clean distclean:
	@echo '===> CLEAN'
	$(Q)rm -fr $(DEPS) $(OBJS) $(BINARY)

install: $(BINARY)
	@echo '===> INSTALL'
	$(Q)$(INSTALL) -d $(PREFIX)/bin
	$(Q)$(INSTALL_PROGRAM) $(BINARY) $(PREFIX)/bin

ipk: $(BINARY)
	@rm -rf /tmp/.wolf3d-ipk/ && mkdir -p /tmp/.wolf3d-ipk/root/home/retrofw/games/wolf3d /tmp/.wolf3d-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@cp -r wolf3d/wolf3d.elf wolf3d/wolf3d.png wolf3d/audiohed.wl1 wolf3d/audiot.wl1 wolf3d/conffiles wolf3d/config.wl1 wolf3d/control wolf3d/gamemaps.wl1 wolf3d/maphead.wl1 wolf3d/vgadict.wl1 wolf3d/vgagraph.wl1 wolf3d/vgahead.wl1 wolf3d/vswap.wl1 /tmp/.wolf3d-ipk/root/home/retrofw/games/wolf3d
	@cp wolf3d/wolf3d.lnk /tmp/.wolf3d-ipk/root/home/retrofw/apps/gmenu2x/sections/games
	@sed "s/^Version:.*/Version: $$(date +%Y%m%d)/" wolf3d/control > /tmp/.wolf3d-ipk/control
	@cp wolf3d/conffiles /tmp/.wolf3d-ipk/
	@tar --owner=0 --group=0 -czvf /tmp/.wolf3d-ipk/control.tar.gz -C /tmp/.wolf3d-ipk/ control conffiles
	@tar --owner=0 --group=0 -czvf /tmp/.wolf3d-ipk/data.tar.gz -C /tmp/.wolf3d-ipk/root/ .
	@echo 2.0 > /tmp/.wolf3d-ipk/debian-binary
	@ar r wolf3d/wolf3d.ipk /tmp/.wolf3d-ipk/control.tar.gz /tmp/.wolf3d-ipk/data.tar.gz /tmp/.wolf3d-ipk/debian-binary
