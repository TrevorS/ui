// 28 february 2014

package ui

import (
	"fmt"
	"runtime"
	"unsafe"
)

// #cgo CFLAGS: -mmacosx-version-min=10.6 -DMACOSX_DEPLOYMENT_TARGET=10.6
// #cgo LDFLAGS: -mmacosx-version-min=10.6 -lobjc -framework Foundation -framework AppKit
// /* application compatibilty stuff via https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/cross_development/Configuring/configuring.html, http://www.cocoawithlove.com/2009/09/building-for-earlier-os-versions-in.html, http://opensource.apple.com/source/xnu/xnu-2422.1.72/EXTERNAL_HEADERS/AvailabilityMacros.h (via http://stackoverflow.com/questions/20485797/what-macro-to-use-to-identify-mavericks-osx-10-9-in-c-c-code), and Beelsebob and LookyLuke_ICBM on irc.freenode.net/#macdev */
// #include "objc_darwin.h"
import "C"

var uitask chan func()

func ui(main func()) error {
	runtime.LockOSThread()

	uitask = make(chan func())

	err := initCocoa()
	if err != nil {
		return err
	}

	// Cocoa must run on the first thread created by the program, so we run our dispatcher on another thread instead
	go func() {
		for f := range uitask {
			C.douitask(appDelegate, unsafe.Pointer(&f))
		}
	}()

	go func() {
		main()
		uitask <- func() {
			C.breakMainLoop()
		}
	}()

	C.cocoaMainLoop()
	return nil
}

func initCocoa() (err error) {
	makeAppDelegate()
	if C.initCocoa(appDelegate) != C.YES {
		return fmt.Errorf("error setting NSApplication activation policy (basically identifies our program as a separate program; needed for several things, such as Dock icon, application menu, window resizing, etc.) (unknown reason)")
	}
	return nil
}

//export appDelegate_uitask
func appDelegate_uitask(p unsafe.Pointer) {
	f := (*func ())(unsafe.Pointer(p))
	(*f)()
}
