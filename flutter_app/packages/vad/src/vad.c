#include "vad.h"

#include "libfvad/src/fvad.c";

#include "libfvad/src/signal_processing/division_operations.c";
#include "libfvad/src/signal_processing/energy.c";
#include "libfvad/src/signal_processing/get_scaling_square.c";
#include "libfvad/src/signal_processing/resample_48khz.c";
#include "libfvad/src/signal_processing/resample_by_2_internal.c";
#include "libfvad/src/signal_processing/resample_fractional.c";
#include "libfvad/src/signal_processing/spl_inl.c";

#include "libfvad/src/vad/vad_core.c";
#include "libfvad/src/vad/vad_filterbank.c";
#include "libfvad/src/vad/vad_gmm.c";
#include "libfvad/src/vad/vad_sp.c";

// // A very short-lived native function.
// //
// // For very short-lived functions, it is fine to call them on the main isolate.
// // They will block the Dart execution while running the native function, so
// // only do this for native functions which are guaranteed to be short-lived.
// FFI_PLUGIN_EXPORT intptr_t sum(intptr_t a, intptr_t b) { return a + b; }

// // A longer-lived native function, which occupies the thread calling it.
// //
// // Do not call these kind of native functions in the main isolate. They will
// // block Dart execution. This will cause dropped frames in Flutter applications.
// // Instead, call these native functions on a separate isolate.
// FFI_PLUGIN_EXPORT intptr_t sum_long_running(intptr_t a, intptr_t b) {
//   // Simulate work.
// #if _WIN32
//   Sleep(5000);
// #else
//   usleep(5000 * 1000);
// #endif
//   return a + b;
// }
